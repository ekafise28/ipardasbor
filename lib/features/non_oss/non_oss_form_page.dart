import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/features/non_oss/models/location_fetch_status.dart';
import 'package:ipardasbor/features/non_oss/offline/non_oss_local_data.dart';

import '../../core/api/api_client.dart';

import 'models/non_oss_form_data.dart';
import 'models/region_option.dart';

import 'services/location_service.dart';
import 'services/non_oss_service.dart';
import 'services/region_service.dart';

import 'widgets/form_section.dart';
import 'widgets/location_picker.dart';
import 'widgets/ota_selector.dart';
import 'widgets/photo_picker.dart';

import 'offline/offline_queue_service.dart';

class NonOssFormPage extends StatefulWidget {
  const NonOssFormPage({super.key, this.editingData});

  final NonOssLocalData? editingData;

  @override
  State<NonOssFormPage> createState() => _NonOssFormPageState();
}

class _NonOssFormPageState extends State<NonOssFormPage> {
  static const _primary = AppTheme.primaryColor;
  static const _navy = Color(0xFF0B3F78);
  final _key = GlobalKey<FormState>();
  late final NonOssFormData _data;

  late final ApiClient _api;
  late final RegionService _regions;
  late final NonOssService _service;
  late final OfflineQueueService _offlineQueue;
  final _location = LocationService();

  List<RegionOption> _provinces = [],
      _regencies = [],
      _districts = [],
      _villages = [];
  bool _loadingRegions = true, _gpsLoading = false, _saving = false;
  LocationFetchStatus? _gpsStatus;
  int? _gpsCountdown;
  LocationSource? _gpsSource;
  Set<_Section> _sectionErrors = {};
  bool get _isEditing => widget.editingData != null;

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

  static const products = [
    'Hotel',
    'Villa',
    'Pondok Wisata',
    'Apartemen',
    'Penginapan',
    'Bumi Perkemahan',
    'Akomodasi Lainnya',
  ];
  static const statuses = <int, String>{
    1: 'Sesuai/aktif',
    2: 'Tidak beroperasi',
    3: 'Lainnya',
    4: 'Alamat tidak ditemukan',
    5: 'Menolak diverifikasi',
    6: 'Pindah alamat',
    7: 'Tutup permanen',
    8: 'Status lainnya',
  };

  @override
  void initState() {
    super.initState();
    _data = widget.editingData != null
        ? NonOssFormData.fromLocalData(widget.editingData!)
        : NonOssFormData();

    _api = ApiClient();
    _regions = RegionService();
    _service = NonOssService(_api);
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
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _loadingRegions = false);
    }
  }

  /// Memuat daftar kabupaten/kecamatan/kelurahan sesuai ID yang sudah
  /// tersimpan, supaya dropdown wilayah langsung terisi benar saat form
  /// dibuka dalam mode edit (bukan cuma menunggu user memilih ulang).
  Future<void> _preloadRegionsForEditing() async {
    if (_data.provinsiId != null) {
      try {
        _regencies = await _regions.regencies(_data.provinsiId!);
      } catch (_) {
        // Biarkan kosong kalau gagal — user tetap bisa pilih ulang manual.
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

  Future<void> _gps() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _gpsLoading = true;
      _gpsStatus = null;
      _gpsCountdown = null;
      // _gpsSource SENGAJA tidak direset di sini, supaya kalau proses gagal
      // di tengah jalan, keterangan sumber lokasi sebelumnya (jika ada)
      // tidak hilang begitu saja.
    });

    try {
      final LocationResult hasil = await _location.current(
        onStatus: (LocationFetchStatus status) {
          if (!mounted) return;
          setState(() => _gpsStatus = status);
        },
        onCountdown: (int sisaDetik) {
          if (!mounted) return;
          setState(() => _gpsCountdown = sisaDetik);
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _data.latitude = hasil.position.latitude.toStringAsFixed(8);
        _data.longitude = hasil.position.longitude.toStringAsFixed(8);
        _gpsSource = hasil.source;
      });
    } catch (e) {
      if (mounted) {
        _error(e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _gpsLoading = false;
        });
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

  // ---------------------------------------------------------------------
  // Validator format nomor telepon.
  // Pengecekan "wajib diisi" SENGAJA tidak dilakukan di sini karena sudah
  // ditangani oleh _buildChecks (lihat _RequiredCheck) — supaya field ini
  // tidak menampilkan dua peringatan sekaligus untuk kondisi kosong.
  // Validator ini hanya memeriksa format saat field sudah terisi (panjang
  // 9-15 digit; karakter non-angka sudah dicegah lewat inputFormatters
  // sehingga tidak perlu dicek ulang di sini).
  // ---------------------------------------------------------------------
  String? _phoneValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null;
    if (value.length < 9 || value.length > 15) {
      return 'Nomor telepon harus 9-15 digit.';
    }
    return null;
  }

  // Validator URL. Field Website bersifat opsional, jadi hanya divalidasi
  // formatnya ketika diisi.
  String? _urlValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    final valid =
        uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return valid ? null : 'Masukkan URL yang valid, contoh: https://contoh.com';
  }

  // Validator email. Field Email bersifat opsional, jadi hanya divalidasi
  // formatnya ketika diisi.
  static final RegExp _emailPattern = RegExp(
    r'^[\w\.\-\+]+@[\w\-]+\.[\w\-\.]+$',
  );
  String? _emailValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null;
    return _emailPattern.hasMatch(value)
        ? null
        : 'Masukkan alamat email yang valid.';
  }

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
      [3, 8].contains(_data.statusPengawasan) &&
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
    try {
      if (_isEditing) {
        await _offlineQueue.update(widget.editingData!, _data);
      } else {
        await _submitOnlineOrQueue();
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 52),
          title: const Text('Berhasil'),
          content: Text(
            _isEditing
                ? 'Perubahan data berhasil disimpan.'
                : 'Data pengawasan Non-OSS berhasil disimpan.',
          ),
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
  Future<void> _submitOnlineOrQueue() async {
    final bool online = await _service.isServerAvailable();

    if (!online) {
      await _saveOffline();
      return;
    }

    try {
      await _service.submit(_data);
    } catch (e) {
      if (_service.isConnectionFailure(e)) {
        await _saveOffline();
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        initialValue: value,
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
                        color: selected ? _primary : AppTheme.border(context),
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
                          color: selected ? _primary : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? _primary
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
        seedColor: _primary,
        primary: _primary,
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
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    ),
    child: Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Pengawasan Non-OSS' : 'Pengawasan Non-OSS',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              _isEditing
                  ? 'Perbarui data yang tersimpan'
                  : 'Pendataan usaha pariwisata',
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
                        _choice<String>(
                          label: 'Apakah usaha memiliki NIB? *',
                          value: _data.memilikiNib,
                          choices: const {
                            'TIDAK': 'Tidak',
                            'TIDAK TAHU': 'Tidak Tahu',
                          },
                          onChanged: (v) =>
                              setState(() => _data.memilikiNib = v),
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

                        DropdownButtonFormField<String>(
                          initialValue: _data.jenisProduk.isEmpty
                              ? null
                              : _data.jenisProduk,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Produk *',
                            border: OutlineInputBorder(),
                          ),
                          items: products
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                          // Perbaikan: sebelumnya tidak ada setState di sini,
                          // sehingga _data.jenisProduk berubah tanpa Flutter
                          // "tahu", dan saat Form.validate() memicu rebuild
                          // (mis. saat tombol Simpan ditekan), dropdown ini
                          // balik ke initialValue lama seolah terhapus.
                          onChanged: (v) =>
                              setState(() => _data.jenisProduk = v ?? ''),
                          validator: (v) => v == null ? 'Wajib dipilih.' : null,
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
                      loading: _gpsLoading,
                      status: _gpsStatus,
                      sisaDetik: _gpsCountdown,
                      source: _gpsSource,
                      onGetLocation: _gps,
                    ),
                  ),
                  FormSection(
                    number: 4,
                    title: 'Kontak dan Legalitas',
                    subtitle: 'Data kontak aktif memudahkan proses verifikasi.',
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
                          required: false,
                          type: TextInputType.emailAddress,
                          hintText: 'example@example.com',
                          // Format email diperiksa hanya jika field diisi.
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
                        DropdownButtonFormField<int>(
                          initialValue: _data.statusPengawasan,
                          decoration: const InputDecoration(
                            labelText: 'Status Pengawasan *',
                            border: OutlineInputBorder(),
                          ),
                          items: statuses.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _data.statusPengawasan = v!),
                        ),
                        const SizedBox(height: 12),
                        _text(
                          'Keterangan',
                          _keteranganCtrl,
                          (v) => _data.keterangan = v,
                          required: false,
                          lines: 3,
                        ),
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
                        backgroundColor: _primary,
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
  );
}

enum _Section { identitas, wilayah, lokasi, kontak, ota, hasil, foto }

class _RequiredCheck {
  final _Section section;
  final bool hasError;
  _RequiredCheck(this.section, this.hasError);
}
