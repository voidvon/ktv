import 'cloud_models.dart';

abstract class CloudRemoteDataSource<TFile extends CloudRemoteFile> {
  Future<List<TFile>> scanRoot(String rootPath);

  Future<List<TFile>> searchFiles({required String keyword, String? rootPath});

  Future<TFile> getPlayableFileMeta(String fileId);
}
