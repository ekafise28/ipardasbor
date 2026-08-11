import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

class NonOssFormPage extends StatefulWidget {
  const NonOssFormPage({super.key});
  @override
  State<NonOssFormPage> createState() => _NonOssFormPageState();
}

class _NonOssFormPageState extends State<NonOssFormPage> {
  static const _primary = Color(0xFF0D67C2);
  static const _navy = Color(0xFF0B3F78);
  final _key = GlobalKey<FormState>();
  final _data = NonOssFormData();
  late final ApiClient _api;
  late final RegionService _regions;
  late final NonOssService _service;
  final _location = LocationService();
  List<RegionOption> _provinces = [],
      _regencies = [],
      _districts = [],
      _villages = [];
  bool _loadingRegions = true, _gpsLoading = false, _saving = false;

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
    _api = ApiClient();
    _regions = RegionService();
    _service = NonOssService(_api);
    _loadProvinces();
  }

  @override
  void dispose() {
    _api.close();
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
    });

    try {
      final p = await _location.current();

      if (!mounted) {
        return;
      }

      setState(() {
        _data.latitude = p.latitude.toStringAsFixed(8);
        _data.longitude = p.longitude.toStringAsFixed(8);
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
  void _error(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    _key.currentState!.save();
    if ([
      _data.provinsiId,
      _data.kabupatenId,
      _data.kecamatanId,
      _data.kelurahanId,
    ].contains(null)) {
      _error(Exception('Wilayah harus dipilih lengkap.'));
      return;
    }
    if (_data.latitude.isEmpty || _data.longitude.isEmpty) {
      _error(Exception('Ambil lokasi GPS terlebih dahulu.'));
      return;
    }
    if (_data.photos.isEmpty) {
      _error(Exception('Minimal satu foto dokumentasi.'));
      return;
    }
    if (_data.terdaftarOta == 'YA' &&
        (_data.otaUrls.isEmpty ||
            _data.otaUrls.values.any(
              (v) => v.every((x) => x.trim().isEmpty),
            ))) {
      _error(Exception('Pilih OTA dan isi URL listing.'));
      return;
    }
    if ([3, 8].contains(_data.statusPengawasan) &&
        _data.keterangan.trim().isEmpty) {
      _error(Exception('Keterangan wajib untuk status lainnya.'));
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.submit(_data);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 52),
          title: const Text('Berhasil'),
          content: const Text('Data pengawasan Non-OSS berhasil disimpan.'),
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

  Widget _text(
    String label,
    String value,
    ValueChanged<String> changed, {
    bool required = true,
    TextInputType? type,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}',
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        prefixIcon: Icon(_fieldIcon(label), size: 20),
      ),
      keyboardType: type,
      maxLines: lines,
      validator: required ? _required : null,
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
          fillColor: const Color(0xFFF8FAFC),
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
          style: const TextStyle(
            color: Color(0xFF334E68),
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
                          ? const Color(0xFFEAF4FF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _primary : const Color(0xFFDCE4EA),
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
                          color: selected ? _primary : const Color(0xFF8A98A8),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? _primary
                                  : const Color(0xFF405366),
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
        surface: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: Color(0xFF607286)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFDCE4EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFDCE4EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengawasan Non-OSS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Pendataan usaha pariwisata',
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
                        colors: [Color(0xFF0B4E91), Color(0xFF1976D2)],
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
                    child: Column(
                      children: [
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
                        _text(
                          'Nama Pemilik',
                          _data.namaPemilik,
                          (v) => _data.namaPemilik = v,
                        ),
                        _text(
                          'Nama Brand',
                          _data.namaBrand,
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
                          onChanged: (v) => _data.jenisProduk = v ?? '',
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
                          _data.alamat,
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
                    child: LocationPicker(
                      latitude: _data.latitude,
                      longitude: _data.longitude,
                      loading: _gpsLoading,
                      onGetLocation: _gps,
                    ),
                  ),
                  FormSection(
                    number: 4,
                    title: 'Kontak dan Legalitas',
                    subtitle: 'Data kontak aktif memudahkan proses verifikasi.',
                    icon: Icons.contact_phone,
                    child: Column(
                      children: [
                        _text(
                          'NPWPD',
                          _data.npwpd,
                          (v) => _data.npwpd = v,
                          required: false,
                        ),
                        _text(
                          'Website',
                          _data.website,
                          (v) => _data.website = v,
                          required: false,
                          type: TextInputType.url,
                        ),
                        _text(
                          'Telepon/WhatsApp',
                          _data.noHp,
                          (v) => _data.noHp = v,
                          type: TextInputType.phone,
                        ),
                        _text(
                          'Email',
                          _data.email,
                          (v) => _data.email = v,
                          required: false,
                          type: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),
                  FormSection(
                    number: 5,
                    title: 'Platform OTA',
                    subtitle: 'Catat platform dan URL listing usaha.',
                    icon: Icons.travel_explore,
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
                            _data.otaLainnyaNama,
                            (v) => _data.otaLainnyaNama = v,
                          ),
                      ],
                    ),
                  ),
                  FormSection(
                    number: 6,
                    title: 'Hasil Pengawasan',
                    icon: Icons.fact_check,
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
                          _data.keterangan,
                          (v) => _data.keterangan = v,
                          required: false,
                          lines: 3,
                        ),
                        _text(
                          'Catatan Petugas',
                          _data.catatanPetugas,
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
                          : const Icon(Icons.cloud_upload_rounded),
                      label: Text(
                        _saving ? 'Menyimpan data...' : 'Simpan Pengawasan',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
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
