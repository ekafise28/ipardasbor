import '../../../app/app_navigator.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/auth_user.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthUser> login({
    required String login,
    required String password,
  }) async {
    final dynamic response = await _apiClient.post(
      ApiEndpoints.login,
      useToken: false,
      body: {'login': login.trim(), 'password': password},
    );

    if (response is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Format respons login dari server tidak valid.',
      );
    }

    final dynamic data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Data login tidak ditemukan pada respons server.',
      );
    }

    final String token = data['token']?.toString().trim() ?? '';
    final dynamic userData = data['user'];

    if (token.isEmpty || userData is! Map) {
      throw const ApiException(
        message: 'Token atau data pengguna tidak ditemukan.',
      );
    }

    final AuthUser user = AuthUser.fromJson(
      Map<String, dynamic>.from(userData),
    );

    await SecureStorage.saveAccessToken(token);

    await SecureStorage.saveUser(
      id: user.id,
      name: user.nama,
      email: user.email,
      role: user.role,
    );

    // Mengaktifkan kembali handler sesi untuk login yang baru.
    AppNavigator.resetSessionRedirect();

    return user;
  }

  Future<bool> isLoggedIn() {
    return SecureStorage.hasAccessToken();
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Tetap logout secara lokal apabila server tidak dapat dijangkau.
    } finally {
      await SecureStorage.clearSession();
      AppNavigator.resetSessionRedirect();
    }
  }

  void dispose() {
    _apiClient.close();
  }
}
