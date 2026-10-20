// import '../../../core/api/api_client.dart';
// import '../../../core/api/api_endpoints.dart';
// import '../../../core/api/api_exception.dart';
// import '../../authentication/models/auth_user.dart';

// class ProfileService {
//   ProfileService({ApiClient? apiClient})
//     : _apiClient = apiClient ?? ApiClient();

//   final ApiClient _apiClient;

//   Future<AuthUser> getProfile() async {
//     final dynamic response = await _apiClient.get(ApiEndpoints.me);

//     if (response is! Map<String, dynamic>) {
//       throw const ApiException(
//         message: 'Format respons profil dari server tidak valid.',
//       );
//     }

//     final dynamic data = response['data'];

//     if (data is! Map<String, dynamic>) {
//       throw const ApiException(
//         message: 'Data profil tidak ditemukan pada respons server.',
//       );
//     }

//     final dynamic userData = data['user'];

//     if (userData is! Map<String, dynamic>) {
//       throw const ApiException(
//         message: 'Data pengguna tidak ditemukan pada respons server.',
//       );
//     }

//     return AuthUser.fromJson(userData);
//   }

//   /// Mengubah password akun yang sedang login.
//   Future<void> changePassword({
//     required String password,
//     required String passwordConfirmation,
//   }) async {
//     final dynamic response = await _apiClient.post(
//       ApiEndpoints.changePassword,
//       body: {
//         'new_password': password,
//         'new_password_confirmation': passwordConfirmation,
//       },
//     );

//     if (response is Map<String, dynamic> && response['success'] == false) {
//       throw ApiException(
//         message: response['message']?.toString() ?? 'Gagal mengubah password.',
//       );
//     }
//   }

//   void dispose() {
//     _apiClient.close();
//   }
// }

import 'package:http/http.dart' as http;
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../authentication/models/auth_user.dart';
import '../models/kelola_akun.dart';

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

  // ==========================================
  // //Mobile - CRUD Kelola Akun Service
  // ==========================================

  /// //Mobile - Mengambil daftar semua akun pengguna
  Future<List<KelolaAkunModel>> getKelolaAkunList() async {
    final dynamic response = await _apiClient.get(ApiEndpoints.users);

    if (response is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'Format respons daftar akun tidak valid.',
      );
    }

    final dynamic listData = response['data'];
    if (listData is! List) {
      return [];
    }

    return listData
        .map((json) => KelolaAkunModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// //Mobile - Menambah akun baru (mendukung upload foto jika ada)
  Future<void> createKelolaAkun(
    Map<String, dynamic> payload, {
    String? imagePath,
  }) async {
    dynamic response;

    if (imagePath != null && imagePath.isNotEmpty) {
      final Map<String, String> fields = payload.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      final multipartFile = await http.MultipartFile.fromPath(
        'foto_user',
        imagePath,
      );

      response = await _apiClient.multipartPost(
        ApiEndpoints.users,
        fields: fields,
        files: [multipartFile],
      );
    } else {
      response = await _apiClient.post(ApiEndpoints.users, body: payload);
    }

    if (response is Map<String, dynamic> && response['success'] == false) {
      throw ApiException(
        message: response['message']?.toString() ?? 'Gagal menambahkan akun.',
      );
    }
  }

  /// //Mobile - Mengubah data akun berdasarkan kode_user
  Future<void> updateKelolaAkun(
    String kodeUser,
    Map<String, dynamic> payload, {
    String? imagePath,
  }) async {
    final endpoint = ApiEndpoints.userDetail(kodeUser);
    dynamic response;

    if (imagePath != null && imagePath.isNotEmpty) {
      final Map<String, String> fields = payload.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      final multipartFile = await http.MultipartFile.fromPath(
        'foto_user',
        imagePath,
      );

      response = await _apiClient.multipartPost(
        endpoint,
        fields: fields,
        files: [multipartFile],
      );
    } else {
      response = await _apiClient.post(endpoint, body: payload);
    }

    if (response is Map<String, dynamic> && response['success'] == false) {
      throw ApiException(
        message: response['message']?.toString() ?? 'Gagal mengubah data akun.',
      );
    }
  }

  /// //Mobile - Menghapus akun berdasarkan kode_user
  Future<void> deleteKelolaAkun(String kodeUser) async {
    final dynamic response = await _apiClient.delete(
      ApiEndpoints.userDetail(kodeUser),
    );

    if (response is Map<String, dynamic> && response['success'] == false) {
      throw ApiException(
        message: response['message']?.toString() ?? 'Gagal menghapus akun.',
      );
    }
  }

  void dispose() {
    _apiClient.close();
  }
}
