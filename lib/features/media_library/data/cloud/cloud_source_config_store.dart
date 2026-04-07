import 'cloud_models.dart';

abstract class CloudSourceConfigStore<TConfig extends CloudSourceConfig> {
  Future<TConfig?> loadConfig();

  Future<void> saveConfig(TConfig config);

  Future<void> clearConfig();
}
