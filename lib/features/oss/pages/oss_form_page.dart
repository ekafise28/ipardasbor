import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/core/api/api_exception.dart';
import 'package:ipardasbor/shared/gps/gps_capture_mixin.dart';

import '../../../core/api/api_client.dart';
import '../../non_oss/models/location_fetch_status.dart';
import '../../non_oss/models/region_option.dart';
import '../../non_oss/services/location_service.dart';
import '../../non_oss/services/region_service.dart';
import '../../non_oss/widgets/location_picker.dart';
import '../../non_oss/widgets/photo_picker.dart';

import '../models/oss_form_data.dart';
import '../models/oss_validasi_result.dart';
import '../services/oss_service.dart';
import '../widgets/ota_platform_selector.dart';
import '../widgets/status_ketidaksesuaian_selector.dart';

/// Tahap 2: form lanjutan validasi OSS, dibuka setelah [OssValidasiPage]
/// mengembalikan [OssValidasiResult].
///
/// Data dikirim ke backend lewat [OssService.submit], yang menyimpannya
/// ke tbl_oss_pengawasan beserta OTA dan foto dokumentasi.
class OssFormPage extends StatefulWidget {
  const OssFormPage({super.key, required this.validasi});

  final OssValidasiResult validasi;

  @override
  State<OssFormPage> createState() => _OssFormPageState();
}

class _OssFormPageState extends State<OssFormPage>
    with WidgetsBindingObserver, GpsCaptureMixin<OssFormPage> {
  static const _primary = AppTheme.primaryColor;
  static const _navy = Color(0xFF0B3F78);

  final _key = GlobalKey<FormState>();
  late final OssFormData _data;
  late final RegionService _regions;
  late final ApiClient _api;
  late final OssService _ossService;

  /// Snapshot nilai field yang diisi otomatis dari hasil validasi OSS,
  /// dipakai untuk mendeteksi "apakah petugas sudah mengubahnya".
  final Map<String, String> _nilaiAsliOtomatis = <String, String>{};

  /// Nama wilayah asli dari API OSS untuk jenjang yang GAGAL dicocokkan
  /// ke ID lokal (ditampilkan sebagai hint di bawah dropdown).
  final Map<String, String?> _hintWilayahAsli = <String, String?>{};

  List<RegionOption> _provinces = [],
      _regencies = [],
      _districts = [],
      _villages = [];
  bool _loadingRegions = true, _saving = false;

  Set<_Section> _sectionErrors = {};

  late final TextEditingController _namaPemilikCtrl;
  late final TextEditingController _namaBrandCtrl;
  late final TextEditingController _npwpdCtrl;
  late final TextEditingController _alamatCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _noHpCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _keteranganCtrl;
  late final TextEditingController _catatanPetugasCtrl;
  late final TextEditingController _otaLainnyaCtrl;

  static const List<MapEntry<String, String>> jenisProdukOptions = [
    MapEntry('55105', 'Hotel Bintang 1'),
    MapEntry('55104', 'Hotel Bintang 2'),
    MapEntry('55103', 'Hotel Bintang 3'),
    MapEntry('55102', 'Hotel Bintang 4'),
    MapEntry('55101', 'Hotel Bintang 5'),
    MapEntry('55106', 'Hotel Non Bintang'),
    MapEntry('55203', 'Vila'),
    MapEntry('55201', 'Homestay'),
    MapEntry('55202', 'Youth Hostel'),
    MapEntry('55204', 'Apartemen Hotel'),
    MapEntry('55300', 'Bumi Perkemahan'),
    MapEntry('55209', 'Akomodasi Jangka Pendek Lainnya'),
    MapEntry('87303', 'Senior Living'),
    MapEntry('55909', 'Akomodasi Lainnya'),
  ];

  static const Map<int, String> statuses = <int, String>{
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
    initGpsCapture();
    _data = OssFormData(
      nib: widget.validasi.nib,
      kbli: widget.validasi.kbli,
      nku: widget.validasi.nku,
      isValid: widget.validasi.isValid,
      kbliDesc: widget.validasi.kbliDesc,
    );

    if (_data.isValid) {
      _data.jenisProduk = _data.kbli;
    }

    _regions = RegionService();
    _api = ApiClient();
    _ossService = OssService(_api);

    _namaPemilikCtrl = TextEditingController();
    _namaBrandCtrl = TextEditingController();
    _npwpdCtrl = TextEditingController();
    _alamatCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
    _noHpCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _keteranganCtrl = TextEditingController();
    _catatanPetugasCtrl = TextEditingController();
    _otaLainnyaCtrl = TextEditingController();

    _loadProvinces();
    _terapkanAutofillProyek();
  }

  @override
  void dispose() {
    disposeGpsCapture();
    _namaPemilikCtrl.dispose();
    _namaBrandCtrl.dispose();
    _npwpdCtrl.dispose();
    _alamatCtrl.dispose();
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
    } catch (e) {
      _error(e);
    } finally {
      if (mounted) setState(() => _loadingRegions = false);
    }
  }

  /// Isi field form dari data proyek hasil validasi (kalau ada), dan catat
  /// nilai aslinya supaya bisa dideteksi kalau petugas mengubahnya nanti.
  Future<void> _terapkanAutofillProyek() async {
    final Map<String, dynamic>? proyek = widget.validasi.proyek;
    if (proyek == null) return;

    String? teks(String key) {
      final dynamic v = proyek[key];
      if (v == null) return null;
      final String s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    int? angka(String key) {
      final dynamic v = proyek[key];
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '');
    }

    final String? namaPerusahaan = teks('nama_perusahaan');
    if (namaPerusahaan != null) {
      _data.namaBrand = namaPerusahaan;
      _namaBrandCtrl.text = namaPerusahaan;
      _nilaiAsliOtomatis['namaBrand'] = namaPerusahaan;
    }

    final String? alamat = teks('alamat_usaha');
    if (alamat != null) {
      _data.alamat = alamat;
      _alamatCtrl.text = alamat;
      _nilaiAsliOtomatis['alamat'] = alamat;
    }

    final String? noHp = teks('nomor_telp_perusahaan');
    if (noHp != null) {
      final String bersih = noHp.replaceAll(RegExp(r'\D'), '');
      if (bersih.isNotEmpty) {
        _data.noHp = bersih;
        _noHpCtrl.text = bersih;
        _nilaiAsliOtomatis['noHp'] = bersih;
      }
    }

    final String? email = teks('email_perusahaan');
    if (email != null) {
      _data.email = email;
      _emailCtrl.text = email;
      _nilaiAsliOtomatis['email'] = email;
    }

    if (mounted) setState(() {});

    // Wilayah - berjenjang, pakai method cascading yang sudah ada (sama
    // seperti kalau petugas memilih manual) supaya dropdown level
    // berikutnya ikut ter-load dengan benar.
    final int? provinsiId = angka('provinsi_id');
    if (provinsiId != null) {
      await _chooseProvince(provinsiId);
    } else {
      _hintWilayahAsli['provinsi'] = teks('provinsi_usaha');
    }

    final int? kabupatenId = angka('kabupaten_id');
    if (kabupatenId != null) {
      await _chooseRegency(kabupatenId);
    } else {
      _hintWilayahAsli['kabupaten'] = teks('kab_kota_usaha');
    }

    final int? kecamatanId = angka('kecamatan_id');
    if (kecamatanId != null) {
      await _chooseDistrict(kecamatanId);
    } else {
      _hintWilayahAsli['kecamatan'] = teks('kecamatan');
    }

    final int? kelurahanId = angka('kelurahan_id');
    if (kelurahanId != null) {
      if (mounted) setState(() => _data.kelurahanId = kelurahanId);
    } else {
      _hintWilayahAsli['kelurahan'] = teks('kelurahan');
    }

    if (mounted) setState(() {});
  }

  /// Apakah nilai field [key] sekarang beda dari nilai hasil autofill asli.
  bool _diubahDariAsli(String key, String nilaiSekarang) {
    final String? asli = _nilaiAsliOtomatis[key];
    if (asli == null) return false;
    return nilaiSekarang.trim() != asli.trim();
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
      (v == null || v.trim().isEmpty) ? 'Wajib diisi.' : null;

  String? _phoneValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null;
    if (value.length < 9 || value.length > 15) {
      return 'Nomor telepon harus 9-15 digit.';
    }
    return null;
  }

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

  List<_RequiredCheck> _buildChecks() => [
    _RequiredCheck(_Section.identitas, _data.namaPemilik.trim().isEmpty),
    _RequiredCheck(_Section.identitas, _data.namaBrand.trim().isEmpty),
    _RequiredCheck(
      _Section.identitas,
      !_data.isValid && _data.jenisProduk.isEmpty,
    ),
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
    _RequiredCheck(_Section.ota, _hasInvalidOtaUrl()),
    _RequiredCheck(
      _Section.ketidaksesuaian,
      !_data.isValid && _data.statusKetidaksesuaian.isEmpty,
    ),
    _RequiredCheck(
      _Section.ketidaksesuaian,
      !_data.isValid &&
          _data.statusKetidaksesuaian.contains('LAINNYA') &&
          _data.keteranganKetidaksesuaian.trim().isEmpty,
    ),
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
      await _ossService.submit(_data);

      if (!mounted) return;
      setState(() => _saving = false);

      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 52),
          title: const Text('Berhasil'),
          content: const Text(
            'Data pengawasan OSS berhasil disimpan ke server.',
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
      if (!mounted) return;
      setState(() => _saving = false);

      final String pesan = _ossService.isConnectionFailure(e)
          ? 'Tidak dapat terhubung ke server. Periksa koneksi internet.'
          : (e is ApiException
                ? e.message
                : e.toString().replaceFirst('Exception: ', ''));

      _error(Exception(pesan));
    }
  }

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
    IconData icon = Icons.notes_rounded,
    String? autofillKey,
  }) {
    final bool diubah =
        autofillKey != null && _diubahDariAsli(autofillKey, controller.text);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label${required ? ' *' : ''}',
          hintText: hintText,
          filled: true,
          fillColor: AppTheme.scaffoldColorDynamic(context),
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: diubah
              ? Tooltip(
                  message: 'Diubah dari data resmi OSS',
                  child: Icon(
                    Icons.edit_note_rounded,
                    size: 20,
                    color: Colors.orange.shade700,
                  ),
                )
              : null,
        ),
        keyboardType: type,
        maxLines: lines,
        inputFormatters: inputFormatters,
        validator: validator ?? (required ? _required : null),
        onChanged: (v) {
          changed(v);
          // supaya badge "diubah" langsung muncul/hilang saat mengetik
          if (autofillKey != null) setState(() {});
        },
      ),
    );
  }

  Widget _region(
    String label,
    int? value,
    List<RegionOption> values,
    ValueChanged<int?> changed, {
    String? hintNamaAsli,
  }) {
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
          helperText: (value == null && hintNamaAsli != null)
              ? 'Data OSS: $hintNamaAsli \u2014 tidak ditemukan di daftar, pilih manual.'
              : null,
          helperMaxLines: 2,
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

  Widget _identityStrip() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.scaffoldColorDynamic(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Expanded(child: _identityItem('NIB', _data.nib)),
          const SizedBox(width: 8),
          Expanded(child: _identityItem('KBLI', _data.kbli)),
          const SizedBox(width: 8),
          Expanded(child: _identityItem('NKU', _data.nku)),
        ],
      ),
    );
  }

  Widget _identityItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary(context),
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 11,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor(context),
                ),
              ),
            ),
          ],
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
        brightness: Theme.of(context).brightness,
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Validasi OSS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Form lanjutan pendataan usaha',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400),
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
                    child: Row(
                      children: [
                        const Icon(
                          Icons.assignment_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Formulir Pendataan Lapangan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.validasi.isValid
                                    ? 'Data OSS tervalidasi - lengkapi informasi usaha di bawah.'
                                    : 'Data belum valid - lengkapi ketidaksesuaian di bagian bawah.',
                                style: const TextStyle(
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
                  FormSectionOss(
                    number: 1,
                    title: 'Identitas Usaha',
                    subtitle:
                        'NIB, KBLI, dan NKU terkunci dari hasil validasi.',
                    icon: Icons.store,
                    hasError: _sectionErrors.contains(_Section.identitas),
                    child: Column(
                      children: [
                        _identityStrip(),
                        _text(
                          'Nama Pemilik',
                          _namaPemilikCtrl,
                          (v) => _data.namaPemilik = v,
                          icon: Icons.person_outline_rounded,
                        ),
                        _text(
                          'Nama Brand',
                          _namaBrandCtrl,
                          (v) => _data.namaBrand = v,
                          icon: Icons.storefront_outlined,
                          autofillKey: 'namaBrand',
                        ),
                        if (_data.isValid)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _identityItem(
                              'Jenis Produk (dari KBLI)',
                              _data.kbli,
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DropdownButtonFormField<String>(
                              initialValue: _data.jenisProduk.isEmpty
                                  ? null
                                  : _data.jenisProduk,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Jenis Produk Akomodasi *',
                                prefixIcon: Icon(
                                  Icons.category_outlined,
                                  size: 20,
                                ),
                              ),
                              items: jenisProdukOptions
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(
                                        e.value,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _data.jenisProduk = v ?? ''),
                              validator: (v) =>
                                  v == null ? 'Wajib dipilih.' : null,
                            ),
                          ),
                        _text(
                          'NPWPD',
                          _npwpdCtrl,
                          (v) => _data.npwpd = v,
                          required: false,
                          icon: Icons.badge_outlined,
                        ),
                      ],
                    ),
                  ),
                  FormSectionOss(
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
                          hintNamaAsli: _hintWilayahAsli['provinsi'],
                        ),
                        _region(
                          'Kabupaten/Kota',
                          _data.kabupatenId,
                          _regencies,
                          _chooseRegency,
                          hintNamaAsli: _hintWilayahAsli['kabupaten'],
                        ),
                        _region(
                          'Kecamatan',
                          _data.kecamatanId,
                          _districts,
                          _chooseDistrict,
                          hintNamaAsli: _hintWilayahAsli['kecamatan'],
                        ),
                        _region(
                          'Kelurahan/Desa',
                          _data.kelurahanId,
                          _villages,
                          (v) => setState(() => _data.kelurahanId = v),
                          hintNamaAsli: _hintWilayahAsli['kelurahan'],
                        ),
                        _text(
                          'Alamat Lengkap',
                          _alamatCtrl,
                          (v) => _data.alamat = v,
                          lines: 3,
                          icon: Icons.home_work_outlined,
                          autofillKey: 'alamat',
                        ),
                      ],
                    ),
                  ),
                  FormSectionOss(
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
                  FormSectionOss(
                    number: 4,
                    title: 'Kontak',
                    subtitle: 'Data kontak aktif memudahkan proses verifikasi.',
                    icon: Icons.contact_phone,
                    hasError: _sectionErrors.contains(_Section.kontak),
                    child: Column(
                      children: [
                        _text(
                          'Website',
                          _websiteCtrl,
                          (v) => _data.website = v,
                          required: false,
                          type: TextInputType.url,
                          hintText: 'https://www.example.com',
                          validator: _urlValidator,
                          icon: Icons.language_rounded,
                        ),
                        _text(
                          'Telepon/WhatsApp',
                          _noHpCtrl,
                          (v) => _data.noHp = v,
                          type: TextInputType.phone,
                          hintText: '081234567890',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(15),
                          ],
                          validator: _phoneValidator,
                          icon: Icons.phone_outlined,
                          autofillKey: 'noHp',
                        ),
                        _text(
                          'Email',
                          _emailCtrl,
                          (v) => _data.email = v,
                          required: false,
                          type: TextInputType.emailAddress,
                          hintText: 'example@example.com',
                          validator: _emailValidator,
                          icon: Icons.email_outlined,
                          autofillKey: 'email',
                        ),
                      ],
                    ),
                  ),
                  FormSectionOss(
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
                        if (_data.terdaftarOta == 'YA') ...[
                          const SizedBox(height: 12),
                          OtaPlatformSelector(
                            urls: _data.otaUrls,
                            onChanged: (v) => setState(() {
                              _data.otaUrls
                                ..clear()
                                ..addAll(v);
                            }),
                          ),
                          if (_data.otaUrls.containsKey('lainnya'))
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _text(
                                'Nama OTA Lainnya',
                                _otaLainnyaCtrl,
                                (v) => _data.otaLainnyaNama = v,
                                icon: Icons.edit_outlined,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  if (!_data.isValid)
                    FormSectionOss(
                      number: 6,
                      title: 'Status Ketidaksesuaian',
                      subtitle:
                          'Data hasil validasi tidak sesuai - pilih kondisi yang ditemukan.',
                      icon: Icons.report_gmailerrorred_rounded,
                      hasError: _sectionErrors.contains(
                        _Section.ketidaksesuaian,
                      ),
                      child: StatusKetidaksesuaianSelector(
                        selected: _data.statusKetidaksesuaian,
                        onChanged: (v) => setState(() {
                          _data.statusKetidaksesuaian
                            ..clear()
                            ..addAll(v);
                        }),
                        keteranganLainnya: _data.keteranganKetidaksesuaian,
                        onKeteranganChanged: (v) =>
                            _data.keteranganKetidaksesuaian = v,
                      ),
                    ),
                  FormSectionOss(
                    number: _data.isValid ? 6 : 7,
                    title: 'Hasil Pengawasan',
                    icon: Icons.fact_check,
                    hasError: _sectionErrors.contains(_Section.hasil),
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _data.statusPengawasan,
                          decoration: const InputDecoration(
                            labelText: 'Status Pengawasan *',
                            prefixIcon: Icon(
                              Icons.fact_check_outlined,
                              size: 20,
                            ),
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
                          icon: Icons.notes_rounded,
                        ),
                        _text(
                          'Catatan Petugas',
                          _catatanPetugasCtrl,
                          (v) => _data.catatanPetugas = v,
                          required: false,
                          lines: 3,
                          icon: Icons.edit_note_rounded,
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
                  FormSectionOss(
                    number: _data.isValid ? 7 : 8,
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
                        _saving ? 'Menyimpan data...' : 'Simpan Pengawasan',
                        style: const TextStyle(
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

/// Kartu section untuk halaman OSS - SENGAJA disalin dari [FormSection]
/// milik Non-OSS (bukan reuse) sesuai keputusan untuk belum menyatukan ke
/// shared widget. Style identik, gampang dipindah ke shared nanti.
class FormSectionOss extends StatelessWidget {
  const FormSectionOss({
    super.key,
    required this.number,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.hasError = false,
  });

  final int number;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    const primary = AppTheme.primaryColor;
    final Color border = AppTheme.border(context);
    final Color surface = AppTheme.surface(context);
    final Color headerBg = AppTheme.surfaceMuted(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: hasError ? Colors.red.withOpacity(0.05) : surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? Colors.red : border,
          width: hasError ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A152238),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasError ? Colors.red : primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: const BorderRadius.all(Radius.circular(9)),
                  ),
                  child: Icon(
                    icon,
                    color: hasError ? Colors.red : primary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: AppTheme.textColor(context),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (hasError)
                            const Icon(
                              Icons.error_rounded,
                              color: Colors.red,
                              size: 17,
                            ),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

enum _Section {
  identitas,
  wilayah,
  lokasi,
  kontak,
  ota,
  ketidaksesuaian,
  hasil,
  foto,
}

class _RequiredCheck {
  final _Section section;
  final bool hasError;
  _RequiredCheck(this.section, this.hasError);
}
