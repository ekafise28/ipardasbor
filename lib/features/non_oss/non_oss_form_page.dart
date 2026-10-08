import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/non_oss/offline/non_oss_local_data.dart';
import 'package:ipardasbor/features/oss/widgets/status_ketidaksesuaian_selector.dart';
import 'package:ipardasbor/shared/gps/gps_capture_mixin.dart';
import 'package:ipardasbor/core/constants/bidang_usaha_constants.dart';
import 'package:ipardasbor/features/oss/models/jenis_produk_akomodasi.dart';

import '../../core/api/api_client.dart';

import 'models/non_oss_form_data.dart';
import 'models/region_option.dart';

import 'services/non_oss_service.dart';
import 'services/region_service.dart';

import 'widgets/form_section.dart';
import 'widgets/location_picker.dart';
import 'widgets/ota_selector.dart';
import 'widgets/photo_picker.dart';

import 'offline/offline_queue_service.dart';
import 'package:ipardasbor/shared/validators/form_validators.dart';

class NonOssFormPage extends StatefulWidget {
  const NonOssFormPage({
    super.key,
    this.editingData,
    this.memilikiNibTerkunci,
    this.baselineOtaId,
    this.bidang,
  });

  /// Slug bidang usaha untuk data BARU. Diabaikan saat mode edit (bidang
  /// diambil dari data tersimpan). null = akomodasi.
  final String? bidang;

  final NonOssLocalData? editingData;

  /// Kalau diisi ('TIDAK' atau 'TIDAK TAHU'), field Kepemilikan NIB dikunci
  /// ke nilai ini dan pilihannya disembunyikan - dipakai saat form ini
  /// dibuka dari alur verifikasi Baseline OTA (lihat BaselineOtaPage).
  final String? memilikiNibTerkunci;

  /// ID baris tbl_oss_baseline_ota yang sedang diverifikasi, kalau form ini
  /// dibuka dari BaselineOtaPage.
  final int? baselineOtaId;

  @override
  State<NonOssFormPage> createState() => _NonOssFormPageState();
}

class _NonOssFormPageState extends State<NonOssFormPage>
    with WidgetsBindingObserver, GpsCaptureMixin<NonOssFormPage> {
  final _key = GlobalKey<FormState>();
  late final NonOssFormData _data;

  late Map<String, String> _snapshotAwal;
  late final int _jumlahFotoAwal;

  late final ApiClient _api;
  late final RegionService _regions;
  late final NonOssService _service;
  late final OfflineQueueService _offlineQueue;

  /// "55105 - Hotel Bintang 1". Nilai lama (label teks, mis. "Hotel") tampil apa adanya.
  String _labelJenisProduk(MapEntry<String, String> e) {
    final bool kode = RegExp(r'^\d{5}$').hasMatch(e.key);
    if (!kode) return e.value;
    return e.value.startsWith(e.key) ? e.value : '${e.key} - ${e.value}';
  }

  List<RegionOption> _provinces = [],
      _regencies = [],
      _districts = [],
      _villages = [];
  bool _loadingRegions = true, _saving = false;

  Set<_Section> _sectionErrors = {};
  bool get _isEditing => widget.editingData != null;
  bool get _nibTerkunci =>
      widget.memilikiNibTerkunci != null || _data.baselineOtaId != null;

  bool get _isDirty {
    final Map<String, String> sekarang = _data.toFields();

    if (sekarang.length != _snapshotAwal.length) {
      return true;
    }
    for (final MapEntry<String, String> entry in sekarang.entries) {
      if (_snapshotAwal[entry.key] != entry.value) {
        return true;
      }
    }
    return _data.photos.length != _jumlahFotoAwal;
  }

  List<MapEntry<String, String>> _jenisProdukOptions =
      JenisProdukAkomodasi.options;

  Future<void> _muatJenisProduk() async {
    if (_data.bidang == 'akomodasi') return;
    try {
      final opsi = await _service.jenisProduk(_data.bidang);
      if (mounted) setState(() => _jenisProdukOptions = opsi);
    } catch (_) {
      if (mounted) {
        _error(
          Exception(
            'Daftar jenis produk gagal dimuat. Periksa koneksi internet.',
          ),
        );
      }
    }
  }

  Future<_BackAction?> _tanyaSimpanDraft() {
    return showDialog<_BackAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Simpan sebagai draft?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Data yang sudah diisi belum tersimpan. Simpan sebagai draft '
          'supaya bisa dilanjutkan nanti, atau buang perubahan ini.',
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, _BackAction.saveDraft),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Simpan Draft',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, _BackAction.discard),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Buang'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, _BackAction.cancel),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraftAndGoHome() async {
    if (!_offlineQueue.hasAnyContent(_data)) {
      _error(
        Exception('Isi minimal satu data sebelum menyimpan sebagai draft.'),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await _offlineQueue.updateDraft(widget.editingData!, _data);
      } else {
        await _offlineQueue.saveDraft(_data);
      }
      if (!mounted) return;
      // popUntil isFirst: memastikan benar-benar kembali ke Home, baik
      // form dibuka langsung dari Home maupun lewat alur edit (Sync ->
      // Detail -> Form).
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    } catch (e) {
      if (mounted) _error(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleBackAttempt() async {
    if (_saving) return;

    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }

    final _BackAction? aksi = await _tanyaSimpanDraft();

    if (aksi == _BackAction.discard) {
      if (mounted) Navigator.of(context).pop();
    } else if (aksi == _BackAction.saveDraft) {
      await _saveDraftAndGoHome();
    }
    // _BackAction.cancel atau null (dialog ditutup tanpa pilih): tetap di form.
  }

  // ---------------------------------------------------------------------
  // TextEditingController untuk setiap field teks.
  //
  // Sebelumnya TextFormField hanya memakai `initialValue`, sehingga saat
  // widget melakukan rebuild (misalnya saat tombol "Simpan Perubahan"
  // ditekan lalu validasi gagal karena ada data wajib yang belum diisi),
  // isian yang sudah diketik pengguna bisa hilang. Dengan controller,
  // nilai teks tersimpan secara independen dari proses build/rebuild
  // sehingga tidak akan terhapus.
  // ---------------------------------------------------------------------
  late final TextEditingController _namaPemilikCtrl;
  late final TextEditingController _namaBrandCtrl;
  late final TextEditingController _alamatCtrl;
  late final TextEditingController _npwpdCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _noHpCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _keteranganCtrl;
  late final TextEditingController _catatanPetugasCtrl;
  late final TextEditingController _otaLainnyaCtrl;

  @override
  void initState() {
    super.initState();
    initGpsCapture();

    _data = widget.editingData != null
        ? NonOssFormData.fromLocalData(widget.editingData!)
        : NonOssFormData();

    if (widget.memilikiNibTerkunci != null) {
      _data.memilikiNib = widget.memilikiNibTerkunci!;
    }
    if (widget.baselineOtaId != null) {
      _data.baselineOtaId = widget.baselineOtaId;
    }

    if (widget.editingData == null && widget.bidang != null) {
      _data.bidang = widget.bidang!;
    }

    // Snapshot kondisi awal, dipakai untuk deteksi "dirty" saat back ditekan.
    _snapshotAwal = Map<String, String>.from(_data.toFields());
    _jumlahFotoAwal = _data.photos.length;

    _api = ApiClient();
    _regions = RegionService();
    _service = NonOssService(_api);
    _muatJenisProduk();
    _offlineQueue = OfflineQueueService();
    // Inisialisasi controller dengan nilai awal dari _data, satu kali saja.
    _namaPemilikCtrl = TextEditingController(text: _data.namaPemilik);
    _namaBrandCtrl = TextEditingController(text: _data.namaBrand);
    _alamatCtrl = TextEditingController(text: _data.alamat);
    _npwpdCtrl = TextEditingController(text: _data.npwpd);
    _websiteCtrl = TextEditingController(text: _data.website);
    _noHpCtrl = TextEditingController(text: _data.noHp);
    _emailCtrl = TextEditingController(text: _data.email);
    _keteranganCtrl = TextEditingController(text: _data.keterangan);
    _catatanPetugasCtrl = TextEditingController(text: _data.catatanPetugas);
    _otaLainnyaCtrl = TextEditingController(text: _data.otaLainnyaNama);

    _loadProvinces();
  }

  @override
  void dispose() {
    disposeGpsCapture();
    _api.close();

    // Buang semua controller agar tidak membebani memori.
    _namaPemilikCtrl.dispose();
    _namaBrandCtrl.dispose();
    _alamatCtrl.dispose();
    _npwpdCtrl.dispose();
    _websiteCtrl.dispose();
    _noHpCtrl.dispose();
    _emailCtrl.dispose();
    _keteranganCtrl.dispose();
    _catatanPetugasCtrl.dispose();
    _otaLainnyaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    try {
      _provinces = await _regions.provinces();

      if (_isEditing) {
        await _preloadRegionsForEditing();
      }

      await _sesuaikanWilayahDenganAkses();
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _loadingRegions = false);
    }
  }

  /// Menyesuaikan wilayah dengan kewenangan akun.
  /// - Draft lama yang wilayahnya sudah di luar akses dikosongkan.
  /// - Akun terkunci ke satu wilayah: provinsi/kabupaten dipilih otomatis.
  Future<void> _sesuaikanWilayahDenganAkses() async {
    bool berubah = false;

    if (_data.provinsiId != null &&
        !_provinces.any((RegionOption o) => o.id == _data.provinsiId)) {
      _data.provinsiId = _data.kabupatenId = _data.kecamatanId =
          _data.kelurahanId = null;
      _regencies = [];
      _districts = [];
      _villages = [];
      berubah = true;
    } else if (_data.kabupatenId != null &&
        !_regencies.any((RegionOption o) => o.id == _data.kabupatenId)) {
      _data.kabupatenId = _data.kecamatanId = _data.kelurahanId = null;
      _districts = [];
      _villages = [];
      berubah = true;
    }

    if (_data.provinsiId == null && _provinces.length == 1) {
      await _chooseProvince(_provinces.first.id);
      berubah = true;
    }

    if (_data.provinsiId != null &&
        _data.kabupatenId == null &&
        _regencies.length == 1) {
      await _chooseRegency(_regencies.first.id);
      berubah = true;
    }

    // Perubahan otomatis ini bukan perubahan petugas. Perbarui snapshot
    // supaya tombol Kembali tidak menampilkan "Simpan sebagai draft?"
    // tanpa alasan.
    if (berubah) {
      _snapshotAwal = Map<String, String>.from(_data.toFields());
    }
  }

  /*
    Memuat daftar kabupaten/kecamatan/kelurahan sesuai ID yang sudah
    tersimpan, supaya dropdown wilayah langsung terisi benar saat form
    dibuka dalam mode edit (bukan cuma menunggu user memilih ulang).
  */
  Future<void> _preloadRegionsForEditing() async {
    if (_data.provinsiId != null) {
      try {
        _regencies = await _regions.regencies(_data.provinsiId!);
      } catch (_) {
        // Biarkan kosong kalau gagal - user tetap bisa pilih ulang manual.
      }
    }
    if (_data.kabupatenId != null) {
      try {
        _districts = await _regions.districts(_data.kabupatenId!);
      } catch (_) {}
    }
    if (_data.kecamatanId != null) {
      try {
        _villages = await _regions.villages(_data.kecamatanId!);
      } catch (_) {}
    }
  }

  Future<void> _chooseProvince(int? id) async {
    setState(() {
      _data.provinsiId = id;
      _data.kabupatenId = _data.kecamatanId = _data.kelurahanId = null;
      _regencies = [];
      _districts = [];
      _villages = [];
    });
    if (id != null) {
      try {
        final v = await _regions.regencies(id);
        if (mounted) setState(() => _regencies = v);
      } catch (e) {
        _error(e);
      }
    }
  }

  Future<void> _chooseRegency(int? id) async {
    setState(() {
      _data.kabupatenId = id;
      _data.kecamatanId = _data.kelurahanId = null;
      _districts = [];
      _villages = [];
    });
    if (id != null) {
      try {
        final v = await _regions.districts(id);
        if (mounted) setState(() => _districts = v);
      } catch (e) {
        _error(e);
      }
    }
  }

  Future<void> _chooseDistrict(int? id) async {
    setState(() {
      _data.kecamatanId = id;
      _data.kelurahanId = null;
      _villages = [];
    });
    if (id != null) {
      try {
        final v = await _regions.villages(id);
        if (mounted) setState(() => _villages = v);
      } catch (e) {
        _error(e);
      }
    }
  }

  Future<void> _date() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _data.tanggalPengawasan,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _data.tanggalPengawasan = d);
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Wajib diisi.' : null;

  String? _phoneValidator(String? v) => FormValidators.phone(v);
  String? _urlValidator(String? v) => FormValidators.url(v);

  String? _emailValidator(String? v) => FormValidators.email(v, wajib: true);

  bool _hasInvalidOtaUrl() {
    if (_data.terdaftarOta != 'YA') return false;

    for (final urls in _data.otaUrls.values) {
      for (final url in urls) {
        final trimmed = url.trim();
        if (trimmed.isEmpty) continue;
        if (_urlValidator(trimmed) != null) return true;
      }
    }
    return false;
  }

  void _error(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Setiap check dipetakan ke section key tempat field itu berada.
  List<_RequiredCheck> _buildChecks() => [
    _RequiredCheck(_Section.identitas, _data.namaPemilik.trim().isEmpty),
    _RequiredCheck(_Section.identitas, _data.namaBrand.trim().isEmpty),
    _RequiredCheck(_Section.identitas, _data.jenisProduk.isEmpty),
    _RequiredCheck(_Section.wilayah, _data.provinsiId == null),
    _RequiredCheck(_Section.wilayah, _data.kabupatenId == null),
    _RequiredCheck(_Section.wilayah, _data.kecamatanId == null),
    _RequiredCheck(_Section.wilayah, _data.kelurahanId == null),
    _RequiredCheck(_Section.wilayah, _data.alamat.trim().isEmpty),
    _RequiredCheck(
      _Section.lokasi,
      _data.latitude.isEmpty || _data.longitude.isEmpty,
    ),
    _RequiredCheck(_Section.kontak, _data.noHp.trim().isEmpty),
    // --- Tambahan: validasi format di section Kontak ---
    _RequiredCheck(_Section.kontak, _phoneValidator(_data.noHp) != null),
    _RequiredCheck(_Section.kontak, _urlValidator(_data.website) != null),
    _RequiredCheck(_Section.kontak, _emailValidator(_data.email) != null),
    _RequiredCheck(
      _Section.ota,
      _data.terdaftarOta == 'YA' &&
          (_data.otaUrls.isEmpty ||
              _data.otaUrls.values.any(
                (v) => v.every((x) => x.trim().isEmpty),
              )),
    ),
    // --- Tambahan: validasi format URL OTA di section OTA ---
    _RequiredCheck(_Section.ota, _hasInvalidOtaUrl()),
    _RequiredCheck(
      _Section.hasil,
      _data.memilikiNib == 'TIDAK TAHU' && _data.statusKetidaksesuaian.isEmpty,
    ),
    _RequiredCheck(
      _Section.hasil,
      _data.statusKetidaksesuaian.contains('LAINNYA') &&
          _data.keterangan.trim().isEmpty,
    ),
    _RequiredCheck(_Section.foto, _data.photos.isEmpty),
  ];

  Future<void> _submit() async {
    _key.currentState!.validate();
    _key.currentState!.save();

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final failedChecks = _buildChecks().where((c) => c.hasError).toList();
    final failedSections = failedChecks.map((c) => c.section).toSet();

    setState(() => _sectionErrors = failedSections);

    if (failedSections.isNotEmpty) {
      _error(Exception('Ada data yang belum diisi dengan benar.'));
      return;
    }

    setState(() => _saving = true);

    // Menentukan pesan dialog sukses: khusus mode edit, selalu pesan yang
    // sama (edit selalu tersimpan lokal dulu, lihat _submitOnlineOrQueue).
    // Untuk data baru, pesannya tergantung apakah berhasil ke server atau
    // jatuh ke penyimpanan lokal.
    String pesanSukses;
    IconData ikonSukses = Icons.check_circle;
    Color warnaIkonSukses = Colors.green;

    try {
      if (_isEditing) {
        await _offlineQueue.update(widget.editingData!, _data);
        pesanSukses = 'Perubahan data berhasil disimpan.';
      } else {
        final bool berhasilKeServer = await _submitOnlineOrQueue();
        if (berhasilKeServer) {
          pesanSukses = 'Data pengawasan Non-OSS berhasil disimpan.';
        } else {
          pesanSukses =
              'Tidak ada koneksi ke server. Data disimpan sementara '
              'di perangkat. Lihat status di halaman Sinkronisasi.';
          ikonSukses = Icons.cloud_off_rounded;
          warnaIkonSukses = const Color(0xFFD97706);
        }
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: Icon(ikonSukses, color: warnaIkonSukses, size: 52),
          title: const Text('Berhasil'),
          content: Text(pesanSukses),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Opsi C: cek ketersediaan server dulu; kalau offline, langsung simpan
  /// lokal. Kalau online tapi gagal karena masalah koneksi di tengah proses
  /// (misalnya putus saat upload foto), fallback ke penyimpanan lokal juga.
  /// Kegagalan karena sebab lain (validasi server, dsb) tetap dilempar apa
  /// adanya ke pemanggil.
  ///
  /// Return value: true kalau berhasil terkirim ke server, false kalau
  /// tersimpan lokal (menunggu sinkronisasi manual di halaman Sinkronisasi).
  Future<bool> _submitOnlineOrQueue() async {
    final bool online = await _service.isServerAvailable();

    if (!online) {
      await _saveOffline();
      return false;
    }

    try {
      await _service.submit(_data);
      return true;
    } catch (e) {
      if (_service.isConnectionFailure(e)) {
        await _saveOffline();
        return false;
      } else {
        rethrow;
      }
    }
  }

  Future<void> _saveOffline() async {
    try {
      await _offlineQueue.save(_data);
    } catch (_) {
      throw Exception('Gagal menyimpan data secara lokal. Silakan coba lagi.');
    }
  }

  // ---------------------------------------------------------------------
  // Field teks umum.
  // - [controller] menyimpan nilai teks secara stabil (lihat penjelasan di
  //   bagian deklarasi controller di atas) sehingga isian tidak hilang
  //   saat terjadi rebuild.
  // - [inputFormatters] opsional untuk membatasi karakter yang bisa
  //   diketik (mis. hanya angka untuk nomor telepon).
  // - [validator] opsional untuk pemeriksaan format khusus (mis. email,
  //   URL, atau nomor telepon). Jika tidak diisi, dipakai pemeriksaan
  //   "wajib diisi" standar (hanya jika [required] true).
  // ---------------------------------------------------------------------
  Widget _text(
    String label,
    TextEditingController controller,
    ValueChanged<String> changed, {
    bool required = true,
    String? hintText,
    TextInputType? type,
    int lines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        hintText: hintText,
        filled: true,
        fillColor: AppTheme.scaffoldColorDynamic(context),
        prefixIcon: Icon(_fieldIcon(label), size: 20),
      ),
      keyboardType: type,
      maxLines: lines,
      inputFormatters: inputFormatters,
      validator: validator ?? (required ? _required : null),
      onChanged: changed,
    ),
  );

  IconData _fieldIcon(String label) {
    if (label.contains('Pemilik')) {
      return Icons.person_outline_rounded;
    }
    if (label.contains('Brand')) {
      return Icons.storefront_outlined;
    }
    if (label.contains('Alamat')) {
      return Icons.home_work_outlined;
    }
    if (label.contains('Website')) {
      return Icons.language_rounded;
    }
    if (label.contains('Telepon')) {
      return Icons.phone_outlined;
    }
    if (label.contains('Email')) {
      return Icons.email_outlined;
    }
    if (label.contains('NPWPD')) {
      return Icons.badge_outlined;
    }
    if (label.contains('Catatan')) {
      return Icons.edit_note_rounded;
    }
    return Icons.notes_rounded;
  }

  Widget _region(
    String label,
    int? value,
    List<RegionOption> values,
    ValueChanged<int?> changed,
  ) {
    final int? nilai = values.any((RegionOption r) => r.id == value)
        ? value
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        key: ValueKey<String>('$label-$nilai-${values.length}'),
        initialValue: nilai,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: '$label *',
          filled: true,
          fillColor: AppTheme.scaffoldColorDynamic(context),
          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
        ),
        items: values
            .map(
              (region) => DropdownMenuItem(
                value: region.id,
                child: Text(region.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: changed,
        validator: (selected) => selected == null ? 'Wajib dipilih.' : null,
      ),
    );
  }

  Widget _lockedNibBanner() {
    final String label = _data.memilikiNib == 'TIDAK' ? 'Tidak' : 'Tidak Tahu';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldColorDynamic(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: AppTheme.textSecondary(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kepemilikan NIB: $label (terkunci dari alur Baseline OTA)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choice<T>({
    required String label,
    required T value,
    required Map<T, String> choices,
    required ValueChanged<T> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: choices.entries.map((entry) {
            final selected = entry.key == value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: entry.key == choices.keys.last ? 0 : 8,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onChanged(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.textOnBrandBadge
                          : AppTheme.scaffoldColorDynamic(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppTheme.primaryColor
                            : AppTheme.border(context),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 18,
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.primaryColor,
        primary: AppTheme.primaryColor,
        brightness: Theme.of(context).brightness, // langsung dari context
        surface: AppTheme.surface(context),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: AppTheme.textSecondary(context)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppTheme.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: AppTheme.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
      ),
    ),
    child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handleBackAttempt();
      },
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldColorDynamic(context),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppTheme.primaryDark,
          foregroundColor: Colors.white,
          titleSpacing: 4,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Pengawasan Non-OSS' : 'Pengawasan Non-OSS',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _isEditing
                    ? 'Perbarui data yang tersimpan'
                    : (BidangUsahaOpsi.namaDari(_data.bidang) ??
                          'Pendataan usaha pariwisata'),
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        body: _loadingRegions
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _key,
                child: ListView(
                  scrollCacheExtent: const ScrollCacheExtent.pixels(10000),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0B4E91), AppTheme.primaryColor],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.assignment_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                          SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Formulir Pendataan Lapangan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Lengkapi data bertanda * dan pastikan lokasi serta foto sudah sesuai.',
                                  style: TextStyle(
                                    color: Color(0xFFE7F2FF),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    FormSection(
                      number: 1,
                      title: 'Identitas Usaha',
                      subtitle: 'Informasi dasar pemilik dan jenis usaha.',
                      icon: Icons.store,
                      hasError: _sectionErrors.contains(_Section.identitas),
                      child: Column(
                        children: [
                          // NIB
                          if (_nibTerkunci)
                            _lockedNibBanner()
                          else
                            _choice<String>(
                              label: 'Apakah usaha memiliki NIB? *',
                              value: _data.memilikiNib,
                              choices: const {
                                'TIDAK': 'Tidak',
                                'TIDAK TAHU': 'Tidak Tahu',
                              },
                              onChanged: (v) => setState(() {
                                _data.memilikiNib = v;
                                // Opsi status berbeda per kondisi, jadi pilihan
                                // lama tidak relevan lagi saat kondisi diganti.
                                _data.statusKetidaksesuaian = <String>[];
                                _data.keterangan = '';
                                _keteranganCtrl.clear();
                              }),
                            ),

                          const SizedBox(height: 12),

                          // Nama Pemilik
                          _text(
                            'Nama Pemilik',
                            _namaPemilikCtrl,
                            (v) => _data.namaPemilik = v,
                          ),

                          // Nama Brand
                          _text(
                            'Nama Brand',
                            _namaBrandCtrl,
                            (v) => _data.namaBrand = v,
                          ),

                          Builder(
                            builder: (_) {
                              final opsi = List<MapEntry<String, String>>.of(
                                _jenisProdukOptions,
                              );
                              // Nilai tersimpan (draft/edit) yang tidak ada di
                              // daftar tetap ditampilkan, supaya dropdown tidak
                              // error dan nilainya tidak hilang.
                              if (_data.jenisProduk.isNotEmpty &&
                                  !opsi.any(
                                    (e) => e.key == _data.jenisProduk,
                                  )) {
                                opsi.add(
                                  MapEntry(
                                    _data.jenisProduk,
                                    _data.jenisProduk,
                                  ),
                                );
                              }
                              return DropdownButtonFormField<String>(
                                key: ValueKey<String>('jp-${opsi.length}'),
                                initialValue: _data.jenisProduk.isEmpty
                                    ? null
                                    : _data.jenisProduk,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Jenis Produk *',
                                  border: OutlineInputBorder(),
                                ),
                                items: opsi
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(
                                          _labelJenisProduk(e),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _data.jenisProduk = v ?? ''),
                                validator: (v) =>
                                    v == null ? 'Wajib dipilih.' : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    FormSection(
                      number: 2,
                      title: 'Wilayah dan Alamat',
                      subtitle:
                          'Pilih wilayah secara berurutan hingga kelurahan.',
                      icon: Icons.location_city,
                      hasError: _sectionErrors.contains(_Section.wilayah),
                      child: Column(
                        children: [
                          _region(
                            'Provinsi',
                            _data.provinsiId,
                            _provinces,
                            _chooseProvince,
                          ),
                          _region(
                            'Kabupaten/Kota',
                            _data.kabupatenId,
                            _regencies,
                            _chooseRegency,
                          ),
                          _region(
                            'Kecamatan',
                            _data.kecamatanId,
                            _districts,
                            _chooseDistrict,
                          ),
                          _region(
                            'Kelurahan/Desa',
                            _data.kelurahanId,
                            _villages,
                            (v) => setState(() => _data.kelurahanId = v),
                          ),
                          _text(
                            'Alamat Lengkap',
                            _alamatCtrl,
                            (v) => _data.alamat = v,
                            lines: 3,
                          ),
                        ],
                      ),
                    ),
                    FormSection(
                      number: 3,
                      title: 'Lokasi dan Peta',
                      subtitle:
                          'Ambil koordinat langsung dari perangkat petugas.',
                      icon: Icons.gps_fixed,
                      hasError: _sectionErrors.contains(_Section.lokasi),
                      child: LocationPicker(
                        latitude: _data.latitude,
                        longitude: _data.longitude,
                        loading: gpsLoading,
                        status: gpsStatus,
                        sisaDetik: gpsCountdown,
                        source: gpsSource,
                        savedAt: gpsSavedAt,
                        onGetLocation: () => ambilLokasiGps(
                          onBerhasil: (hasil) => setState(() {
                            _data.latitude = hasil.position.latitude
                                .toStringAsFixed(8);
                            _data.longitude = hasil.position.longitude
                                .toStringAsFixed(8);
                          }),
                        ),
                      ),
                    ),
                    FormSection(
                      number: 4,
                      title: 'Kontak dan Legalitas',
                      subtitle:
                          'Data kontak aktif memudahkan proses verifikasi.',
                      icon: Icons.contact_phone,
                      hasError: _sectionErrors.contains(_Section.kontak),
                      child: Column(
                        children: [
                          _text(
                            'NPWPD',
                            _npwpdCtrl,
                            (v) => _data.npwpd = v,
                            required: false,
                          ),
                          _text(
                            'Website',
                            _websiteCtrl,
                            (v) => _data.website = v,
                            required: false,
                            type: TextInputType.url,
                            hintText: 'https://www.example.com',
                            // Format URL diperiksa hanya jika field diisi.
                            validator: _urlValidator,
                          ),
                          _text(
                            'Telepon/WhatsApp',
                            _noHpCtrl,
                            (v) => _data.noHp = v,
                            type: TextInputType.phone,
                            hintText: '081234567890',
                            inputFormatters: [
                              // Hanya menerima karakter angka.
                              FilteringTextInputFormatter.digitsOnly,
                              // Batasi maksimal 15 digit.
                              LengthLimitingTextInputFormatter(15),
                            ],
                            validator: _phoneValidator,
                          ),
                          _text(
                            'Email',
                            _emailCtrl,
                            (v) => _data.email = v,
                            type: TextInputType.emailAddress,
                            hintText: 'example@example.com',
                            validator: _emailValidator,
                          ),
                        ],
                      ),
                    ),
                    FormSection(
                      number: 5,
                      title: 'Platform OTA',
                      subtitle: 'Catat platform dan URL listing usaha.',
                      icon: Icons.travel_explore,
                      hasError: _sectionErrors.contains(_Section.ota),
                      child: Column(
                        children: [
                          _choice<String>(
                            label: 'Apakah terdaftar di OTA? *',
                            value: _data.terdaftarOta,
                            choices: const {'YA': 'Ya', 'TIDAK': 'Tidak'},
                            onChanged: (v) =>
                                setState(() => _data.terdaftarOta = v),
                          ),
                          if (_data.terdaftarOta == 'YA')
                            OtaSelector(
                              urls: _data.otaUrls,
                              onChanged: (v) => setState(() {
                                _data.otaUrls
                                  ..clear()
                                  ..addAll(v);
                              }),
                            ),
                          if (_data.terdaftarOta == 'YA' &&
                              _data.otaUrls.containsKey('lainnya'))
                            _text(
                              'Nama OTA lainnya',
                              _otaLainnyaCtrl,
                              (v) => _data.otaLainnyaNama = v,
                            ),
                        ],
                      ),
                    ),
                    FormSection(
                      number: 6,
                      title: 'Hasil Pengawasan',
                      icon: Icons.fact_check,
                      hasError: _sectionErrors.contains(_Section.hasil),
                      child: Column(
                        children: [
                          Text(
                            'Status Hasil Pengawasan *',
                            style: TextStyle(
                              color: AppTheme.textColor(context),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 9),
                          if (_data.memilikiNib == 'TIDAK')
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.scaffoldColorDynamic(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.border(context),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: AppTheme.textSecondary(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tidak Punya NIB',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            StatusKetidaksesuaianSelector(
                              options: StatusKetidaksesuaianSelector
                                  .nonOssTidakTahuOptions,
                              selected: _data.statusKetidaksesuaian,
                              onChanged: (v) => setState(() {
                                _data.statusKetidaksesuaian = v;
                              }),
                              keteranganLainnya: _data.keterangan,
                              keteranganLabel: 'Keterangan Status Lainnya *',
                              onKeteranganChanged: (v) => _data.keterangan = v,
                            ),
                          const SizedBox(height: 12),
                          _text(
                            'Catatan Petugas',
                            _catatanPetugasCtrl,
                            (v) => _data.catatanPetugas = v,
                            required: false,
                            lines: 3,
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Tanggal Pengawasan *'),
                            subtitle: Text(
                              DateFormat(
                                'dd-MM-yyyy',
                              ).format(_data.tanggalPengawasan),
                            ),
                            trailing: const Icon(Icons.calendar_month),
                            onTap: _date,
                          ),
                        ],
                      ),
                    ),
                    FormSection(
                      number: 7,
                      title: 'Foto Dokumentasi',
                      subtitle: 'Tambahkan 1–5 foto kondisi usaha di lapangan.',
                      icon: Icons.photo_camera,
                      hasError: _sectionErrors.contains(_Section.foto),
                      child: PhotoPicker(
                        photos: _data.photos,
                        onChanged: (v) => setState(() {
                          _data.photos
                            ..clear()
                            ..addAll(v);
                        }),
                      ),
                    ),
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.cloud_upload_rounded,
                                color: Colors.white,
                              ),
                        label: Text(
                          _saving
                              ? (_isEditing
                                    ? 'Menyimpan perubahan...'
                                    : 'Menyimpan data...')
                              : (_isEditing
                                    ? 'Simpan Perubahan'
                                    : 'Simpan Pengawasan'),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    ),
  );
}

enum _Section { identitas, wilayah, lokasi, kontak, ota, hasil, foto }

class _RequiredCheck {
  final _Section section;
  final bool hasError;
  _RequiredCheck(this.section, this.hasError);
}

enum _BackAction { discard, cancel, saveDraft }
