import '../../media_library/data/baidu_pan/baidu_pan_api_client.dart';
import '../../media_library/data/baidu_pan/baidu_pan_auth_repository.dart';
import '../../media_library/data/baidu_pan/baidu_pan_models.dart';
import '../../media_library/data/baidu_pan/baidu_pan_source_config_store.dart';
import 'cloud_source_settings_controller.dart';

class BaiduPanSettingsController
    extends
        CloudSourceSettingsController<
          BaiduPanSourceConfig,
          BaiduPanAuthToken,
          BaiduPanUserInfo,
          BaiduPanQuotaInfo
        > {
  BaiduPanSettingsController({
    required BaiduPanAppCredentials appCredentials,
    required BaiduPanApiClient apiClient,
    required BaiduPanAuthRepository authRepository,
    required BaiduPanSourceConfigStore sourceConfigStore,
  }) : super(
         providerLabel: '百度网盘',
         appCredentials: appCredentials,
         authRepository: authRepository,
         sourceConfigStore: sourceConfigStore,
         loadUserInfo: apiClient.getUserInfo,
         loadQuotaInfo: apiClient.getQuota,
         configFactory: (String rootPath) {
           return BaiduPanSourceConfig(
             sourceRootId: 'baidu_pan:$rootPath',
             rootPath: rootPath,
             displayName: '百度网盘',
           );
         },
       );
}
