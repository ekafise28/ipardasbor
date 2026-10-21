// lib/features/peta_industri/services/peta_industri_service.dart

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../models/peta_detail_model.dart';
import '../models/peta_grafik_model.dart';
import '../models/peta_industri_model.dart';

class PetaIndustriService {
  PetaIndustriService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Marker per provinsi (Batch 1).
  Future<PetaIndustriData> ambilPeta() async {
    final dynamic response = await _client.get(ApiEndpoints.petaIndustri);
    return PetaIndustriData.fromJson(_ambilData(response));
  }

  /// Donut risiko per KBLI, dikelompokkan per kategori usaha.
  Future<PetaGrafikData> ambilGrafik(String provinsi) async {
    final dynamic response = await _client.get(
      ApiEndpoints.petaIndustriGrafik(provinsi),
    );
    return PetaGrafikData.fromJson(_ambilData(response));
  }

  /// Daftar perusahaan untuk satu baris rekap (provinsi + KBLI + risiko).
  Future<PetaPerusahaanHalaman> ambilPerusahaan(
    String provinsi, {
    required String kbli,
    required String risiko,
    int page = 1,
    int perPage = 25,
    String search = '',
  }) async {
    final dynamic response = await _client.get(
      ApiEndpoints.petaIndustriPerusahaan(provinsi),
      queryParameters: <String, dynamic>{
        'kbli': kbli,
        'risiko': risiko,
        'page': page,
        'per_page': perPage,
        'search': search,
      },
    );
    return PetaPerusahaanHalaman.fromJson(_ambilData(response));
  }

  /// Seluruh baris rekap satu provinsi, untuk diekspor.
  Future<List<PetaRekapItem>> ambilSemuaRekap(String provinsi) async {
    final dynamic response = await _client.get(
      ApiEndpoints.petaIndustriEkspor(provinsi),
    );
    return PetaRekapHalaman.fromJson(_ambilData(response)).items;
  }

  /// Rekap berpaginasi.
  /// [sort]: jumlah | jenis_usaha | nama_kbli | kbli | risiko
  /// [dir]: asc | desc
  Future<PetaRekapHalaman> ambilDetail(
    String provinsi, {
    int page = 1,
    int perPage = 25,
    String search = '',
    String sort = 'jumlah',
    String dir = 'desc',
  }) async {
    final dynamic response = await _client.get(
      ApiEndpoints.petaIndustriDetail(provinsi),
      queryParameters: <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'search': search,
        'sort': sort,
        'dir': dir,
      },
    );
    return PetaRekapHalaman.fromJson(_ambilData(response));
  }

  Map<String, dynamic> _ambilData(dynamic response) {
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Format data tidak valid.');
    }

    final dynamic data = response['data'];
    if (data is! Map) {
      throw const ApiException(message: 'Data tidak ditemukan.');
    }

    return Map<String, dynamic>.from(data);
  }
}
