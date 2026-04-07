import 'cloud_models.dart';

abstract class CloudAuthRepository<TToken extends CloudAuthToken> {
  Future<Uri> buildAuthorizeUri();

  Future<void> loginWithAuthorizationCode(String code);

  Future<void> logout();

  Future<String> getValidAccessToken();

  Future<bool> hasValidSession();

  Future<TToken?> readToken();
}
