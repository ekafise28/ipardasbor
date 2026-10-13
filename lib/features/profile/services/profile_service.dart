import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../authentication/models/auth_user.dart';

class ProfileService {
  ProfileService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthUser> getProfile() async {
    final dynamic response = await _apiClient.get(ApiEndpoints.me);

    if (response is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Format respons profil dari server tidak valid.',
      );
    }

    final dynamic data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Data profil tidak ditemukan pada respons server.',
      );
    }

    final dynamic userData = data['user'];

    if (userData is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Data pengguna tidak ditemukan pada respons server.',
      );
    }

    return AuthUser.fromJson(userData);
  }

  /// Mengubah password akun yang sedang login.
  Future<void> changePassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    final dynamic response = await _apiClient.post(
      ApiEndpoints.changePassword,
      body: {
        'new_password': password,
        'new_password_confirmation': passwordConfirmation,
      },
    );

    if (response is Map<String, dynamic> && response['success'] == false) {
      throw ApiException(
        message: response['message']?.toString() ?? 'Gagal mengubah password.',
      );
    }
  }

  void dispose() {
    _apiClient.close();
  }
}
