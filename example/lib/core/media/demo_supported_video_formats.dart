const List<String> demoSupportedVideoExtensions = <String>[
  '3g2',
  '3gp',
  'asf',
  'avi',
  'dat',
  'divx',
  'dv',
  'f4v',
  'flv',
  'm1v',
  'm2t',
  'm2ts',
  'm2v',
  'm4v',
  'mkv',
  'mov',
  'mp4',
  'mpe',
  'mpeg',
  'mpg',
  'mts',
  'mxf',
  'ogm',
  'ogv',
  'qt',
  'rm',
  'rmvb',
  'tod',
  'tp',
  'trp',
  'ts',
  'vob',
  'webm',
  'wmv',
];

final Set<String> demoSupportedVideoExtensionSet = Set<String>.unmodifiable(
  demoSupportedVideoExtensions.toSet(),
);

String demoExtractVideoExtension(String fileName) {
  final int dotIndex = fileName.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == fileName.length - 1) {
    return '';
  }
  return fileName.substring(dotIndex + 1).toLowerCase();
}

bool demoIsSupportedVideoFileName(String fileName) {
  return demoSupportedVideoExtensionSet.contains(
    demoExtractVideoExtension(fileName),
  );
}
