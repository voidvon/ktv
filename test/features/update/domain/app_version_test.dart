import 'package:flutter_test/flutter_test.dart';
import 'package:maimai_ktv/features/update/domain/app_version.dart';

void main() {
  test('stable release is newer than prerelease with same core version', () {
    final AppVersion stable = AppVersion.parse(
      version: '1.0.0',
      buildNumber: '10',
    );
    final AppVersion prerelease = AppVersion.parse(
      version: '1.0.0-alpha.7',
      buildNumber: '99',
    );

    expect(stable.compareTo(prerelease), greaterThan(0));
  });

  test('build number participates when display version is unchanged', () {
    final AppVersion oldBuild = AppVersion.parse(
      version: '1.0.0-alpha.7',
      buildNumber: '7',
    );
    final AppVersion newBuild = AppVersion.parse(
      version: '1.0.0-alpha.7',
      buildNumber: '8',
    );

    expect(newBuild.compareTo(oldBuild), greaterThan(0));
  });

  test('prerelease identifiers follow semantic ordering', () {
    final AppVersion alpha = AppVersion.parse(
      version: '1.0.0-alpha.7',
      buildNumber: '1',
    );
    final AppVersion beta = AppVersion.parse(
      version: '1.0.0-beta.1',
      buildNumber: '1',
    );

    expect(beta.compareTo(alpha), greaterThan(0));
  });
}
