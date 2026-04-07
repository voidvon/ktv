import '../cloud/cloud_song_source.dart';
import 'baidu_pan_models.dart';
import 'baidu_pan_remote_data_source.dart';
import 'baidu_pan_song_mapper.dart';
import 'baidu_pan_source_config_store.dart';

class BaiduPanSongSource
    extends CloudSongSource<BaiduPanSourceConfig, BaiduPanRemoteFile> {
  BaiduPanSongSource({
    required super.mediaLibraryRepository,
    required BaiduPanSourceConfigStore sourceConfigStore,
    required BaiduPanRemoteDataSource remoteDataSource,
    BaiduPanSongMapper? songMapper,
  }) : super(
         sourceId: 'baidu_pan',
         sourceConfigStore: sourceConfigStore,
         remoteDataSource: remoteDataSource,
         sourceRecordMapper: _createSourceRecordMapper(songMapper),
       );

  static CloudSourceSongRecordMapper<BaiduPanSourceConfig, BaiduPanRemoteFile>
  _createSourceRecordMapper(BaiduPanSongMapper? songMapper) {
    final BaiduPanSongMapper resolvedMapper =
        songMapper ?? BaiduPanSongMapper();
    return ({
      required BaiduPanRemoteFile file,
      required BaiduPanSourceConfig config,
    }) {
      return resolvedMapper.mapRemoteFileToSourceRecord(
        file: file,
        sourceRootId: config.sourceRootId,
      );
    };
  }
}
