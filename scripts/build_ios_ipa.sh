#!/usr/bin/env bash

set -euo pipefail

mode="release"
skip_pub_get=0
clean=0
team_id=""
bundle_id=""
export_method="development"

usage() {
  cat <<'EOF'
Usage: scripts/build_ios_ipa.sh [options]

Options:
  --mode <debug|profile|release>  Build mode. Default: release
  --skip-pub-get                  Skip flutter pub get
  --clean                         Remove build/ios and dist/ios before building
  --team-id <TEAM_ID>             Apple development team ID for signed export
  --bundle-id <BUNDLE_ID>         Override bundle identifier for signed export
  --export-method <METHOD>        Export method for signed export. Default: development
  --help                          Show this message

Without --team-id, the script builds an unsigned Runner.app and wraps it as an
unsigned IPA under dist/ios for handoff purposes.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      mode="${2:-}"
      shift 2
      ;;
    --skip-pub-get)
      skip_pub_get=1
      shift
      ;;
    --clean)
      clean=1
      shift
      ;;
    --team-id)
      team_id="${2:-}"
      shift 2
      ;;
    --bundle-id)
      bundle_id="${2:-}"
      shift 2
      ;;
    --export-method)
      export_method="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$mode" in
  debug|profile|release)
    ;;
  *)
    echo "Unsupported mode: $mode" >&2
    exit 1
    ;;
esac

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dist_dir="$repo_root/dist/ios"

version="$(sed -nE 's/^version:[[:space:]]*(.+)$/\1/p' "$repo_root/pubspec.yaml" | head -n 1)"
if [[ -z "$version" ]]; then
  version="unknown"
fi
safe_version="$(printf '%s' "$version" | tr '+/' '--' | tr -cd '[:alnum:]._-')"
artifact_prefix="maimai-ktv-${safe_version}-ios"

if [[ $clean -eq 1 ]]; then
  rm -rf "$repo_root/build/ios" "$dist_dir"
fi

mkdir -p "$dist_dir"

if [[ $skip_pub_get -eq 0 ]]; then
  (cd "$repo_root" && flutter pub get)
fi

flutter_build_args=(build ios "--$mode")
if [[ $skip_pub_get -eq 1 ]]; then
  flutter_build_args+=(--no-pub)
fi

if [[ -z "$team_id" ]]; then
  echo "==> Building unsigned iOS app"
  (cd "$repo_root" && flutter "${flutter_build_args[@]}" --no-codesign)

  app_path="$repo_root/build/ios/iphoneos/Runner.app"
  if [[ ! -d "$app_path" ]]; then
    echo "Unsigned build finished but Runner.app was not found: $app_path" >&2
    exit 1
  fi

  payload_root="$(mktemp -d "${TMPDIR:-/tmp}/maimai-ios-payload.XXXXXX")"
  trap 'rm -rf "$payload_root"' EXIT
  mkdir -p "$payload_root/Payload"
  ditto "$app_path" "$payload_root/Payload/Runner.app"

  ipa_path="$dist_dir/${artifact_prefix}-unsigned.ipa"
  rm -f "$ipa_path"
  (
    cd "$payload_root"
    zip -qry "$ipa_path" Payload
  )

  echo "Created unsigned IPA: $ipa_path"
  exit 0
fi

if [[ -z "$bundle_id" ]]; then
  bundle_id="com.app0122.maimai.app"
fi

archive_dir="$repo_root/build/ios/archive"
archive_path="$archive_dir/Runner.xcarchive"
export_dir="$dist_dir/export"
export_options_plist="$(mktemp "${TMPDIR:-/tmp}/ExportOptions.XXXXXX.plist")"
trap 'rm -f "$export_options_plist"' EXIT

mkdir -p "$archive_dir"
rm -rf "$archive_path" "$export_dir"

cat >"$export_options_plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>${export_method}</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>${team_id}</string>
</dict>
</plist>
EOF

echo "==> Preparing Flutter iOS workspace"
(cd "$repo_root" && flutter "${flutter_build_args[@]}" --no-codesign)

echo "==> Archiving signed iOS app"
(
  cd "$repo_root"
  xcodebuild \
    -workspace ios/Runner.xcworkspace \
    -scheme Runner \
    -configuration "$(tr '[:lower:]' '[:upper:]' <<< "${mode:0:1}")${mode:1}" \
    -archivePath "$archive_path" \
    archive \
    DEVELOPMENT_TEAM="$team_id" \
    PRODUCT_BUNDLE_IDENTIFIER="$bundle_id" \
    CODE_SIGN_STYLE=Automatic \
    -allowProvisioningUpdates
)

echo "==> Exporting IPA"
(
  cd "$repo_root"
  xcodebuild \
    -exportArchive \
    -archivePath "$archive_path" \
    -exportPath "$export_dir" \
    -exportOptionsPlist "$export_options_plist" \
    -allowProvisioningUpdates
)

signed_ipa="$(find "$export_dir" -maxdepth 1 -name '*.ipa' -print -quit)"
if [[ -z "$signed_ipa" ]]; then
  echo "Signed export finished but no IPA was produced in $export_dir" >&2
  exit 1
fi

final_ipa="$dist_dir/${artifact_prefix}-${export_method}.ipa"
rm -f "$final_ipa"
mv "$signed_ipa" "$final_ipa"

echo "Created signed IPA: $final_ipa"
