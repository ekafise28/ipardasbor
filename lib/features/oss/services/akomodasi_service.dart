import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../models/akomodasi_item_data.dart';
import '../models/oss_form_data.dart';

/// Hasil live-check satu item akomodasi (endpoint /oss/validasi-akomodasi).
/// Dibuat class terpisah dari [OssValidasiResult] karena tidak membawa
/// data `proyek` untuk autofill - live-check akomodasi murni konfirmasi
/// valid/tidak, bukan sumber autofill form.
class AkomodasiCekHasil {
  const AkomodasiCekHasil({
    required this.valid,
    required this.status,
    required this.pesan,
  });

  final bool valid;
  final String status;
  final String pesan;
}

class AkomodasiService {
  AkomodasiService(this._api);

  final ApiClient _api;

  /// Live-check NIB/KBLI/NKU satu kartu akomodasi (dipanggil dari tombol
  /// "Cek Validasi" di [AkomodasiItemCard]). Hasilnya HANYA untuk feedback
  /// UI - backend selalu memvalidasi ulang saat [submit] final.
  Future<AkomodasiCekHasil> cek({
    required String nib,
    required String kbli,
    required String nku,
  }) async {
    final dynamic response = await _api.post(
      ApiEndpoints.validasiAkomodasi,
      body: {'nib': nib, 'kbli': kbli, 'nku': nku},
    );

    if (response is! Map) {
      throw const ApiException(message: 'Respons cek akomodasi tidak valid.');
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(response);

    return AkomodasiCekHasil(
      valid: data['valid'] == true,
      status: data['status']?.toString() ?? '',
      pesan: data['pesan']?.toString() ?? '',
    );
  }

  /// Submit atomic: Tahap 1 ([tahap1]) + seluruh [akomodasi] Tahap 2 +
  /// foto per item, dalam SATU request multipart (all-or-nothing).
  Future<dynamic> submit({
    required OssFormData tahap1,
    required List<AkomodasiItemData> akomodasi,
  }) async {
    final Map<String, String> fields = _fieldsTahap1(tahap1);

    for (int i = 0; i < akomodasi.length; i++) {
      fields.addAll(akomodasi[i].toFields(i));
    }

    final List<http.MultipartFile> files = <http.MultipartFile>[];

    for (int i = 0; i < akomodasi.length; i++) {
      for (final photo in akomodasi[i].photos) {
        final File file = File(photo.path);
        if (!await file.exists()) {
          throw Exception('Foto lokal tidak ditemukan: ${photo.path}');
        }
        files.add(
          await http.MultipartFile.fromPath(
            'akomodasi[$i][foto][]',
            photo.path,
            filename: file.uri.pathSegments.last,
          ),
        );
      }
    }

    return _api.multipartPost(
      ApiEndpoints.pengawasanAkomodasi,
      fields: fields,
      files: files,
    );
  }

  Map<String, String> _fieldsTahap1(OssFormData tahap1) {
    final Map<String, String> fields = <String, String>{
      'nib': tahap1.nib.trim(),
      'kbli': tahap1.kbli.trim(),
      'nku': tahap1.nku.trim(),
      'nama_pemilik': tahap1.namaPemilik.trim(),
      'nama_brand': tahap1.namaBrand.trim(),
      'alamat': tahap1.alamat.trim(),
      'latitude': tahap1.latitude.trim(),
      'longitude': tahap1.longitude.trim(),
      'no_hp': tahap1.noHp.trim(),
      'tanggal_pengawasan': _formatDate(tahap1.tanggalPengawasan),
    };

    if (tahap1.provinsiId != null) fields['provinsi_id'] = tahap1.provinsiId.toString();
    if (tahap1.kabupatenId != null) fields['kabupaten_id'] = tahap1.kabupatenId.toString();
    if (tahap1.kecamatanId != null) fields['kecamatan_id'] = tahap1.kecamatanId.toString();
    if (tahap1.kelurahanId != null) fields['kelurahan_id'] = tahap1.kelurahanId.toString();

    if (tahap1.npwpd.trim().isNotEmpty) fields['npwpd'] = tahap1.npwpd.trim();
    if (tahap1.website.trim().isNotEmpty) fields['website'] = tahap1.website.trim();
    if (tahap1.email.trim().isNotEmpty) fields['email'] = tahap1.email.trim();

    if (!tahap1.isValid) {
      for (int i = 0; i < tahap1.statusKetidaksesuaian.length; i++) {
        fields['status_ketidaksesuaian[$i]'] = tahap1.statusKetidaksesuaian[i];
      }
      if (tahap1.keteranganKetidaksesuaian.trim().isNotEmpty) {
        fields['keterangan_ketidaksesuaian'] = tahap1.keteranganKetidaksesuaian.trim();
      }
    }

    return fields;
  }

  String _formatDate(DateTime date) {
    final String y = date.year.toString().padLeft(4, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}