import 'package:flutter/foundation.dart';
import 'package:ipardasbor/shared/region/models/region_option.dart';
import 'package:ipardasbor/shared/region/services/region_service.dart';

/// Daftar kecamatan dan kelurahan yang bergantung pada pilihan induknya.
/// Memanggil [muatKecamatan] mengosongkan kelurahan juga; memanggil dengan
/// null mengosongkan keduanya. Respons yang terlambat diabaikan.
class RegionCascade extends ChangeNotifier {
  RegionCascade(this._service);

  final RegionService _service;

  List<RegionOption> kecamatan = <RegionOption>[];
  List<RegionOption> kelurahan = <RegionOption>[];
  bool loadingKecamatan = false;
  bool loadingKelurahan = false;

  int? _kabupatenId;
  int? _kecamatanId;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> muatKecamatan(int? kabupatenId) async {
    _kabupatenId = kabupatenId;
    _kecamatanId = null;
    kecamatan = <RegionOption>[];
    kelurahan = <RegionOption>[];
    loadingKelurahan = false;
    loadingKecamatan = kabupatenId != null;
    _notify();
    if (kabupatenId == null) return;

    List<RegionOption> hasil = <RegionOption>[];
    try {
      hasil = await _service.districts(kabupatenId);
    } catch (_) {}
    if (_disposed || _kabupatenId != kabupatenId) return;

    kecamatan = hasil;
    loadingKecamatan = false;
    _notify();
  }

  Future<void> muatKelurahan(int? kecamatanId) async {
    _kecamatanId = kecamatanId;
    kelurahan = <RegionOption>[];
    loadingKelurahan = kecamatanId != null;
    _notify();
    if (kecamatanId == null) return;

    List<RegionOption> hasil = <RegionOption>[];
    try {
      hasil = await _service.villages(kecamatanId);
    } catch (_) {}
    if (_disposed || _kecamatanId != kecamatanId) return;

    kelurahan = hasil;
    loadingKelurahan = false;
    _notify();
  }
}