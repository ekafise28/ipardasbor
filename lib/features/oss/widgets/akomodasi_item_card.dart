// lib/features/oss/widgets/akomodasi_item_card.dart
import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/gps/gps_capture_mixin.dart';

import '../../non_oss/models/region_option.dart';
import '../../non_oss/services/region_service.dart';
import '../../non_oss/widgets/form_section.dart';
import '../../non_oss/widgets/location_picker.dart';
import '../../non_oss/widgets/photo_picker.dart';
import '../models/akomodasi_item_data.dart';
import '../models/jenis_produk_akomodasi.dart';
import 'ota_platform_selector.dart';
import 'status_ketidaksesuaian_selector.dart';

/// Satu kartu "Akomodasi yang Dikelola" pada Tahap 2 form Manajemen
/// Akomodasi. Controlled widget - semua perubahan langsung memutasi [data],
/// lalu memanggil [onChanged] supaya parent (AkomodasiFormPage) tahu perlu
/// rebuild. Isi kartu dipecah per-section pakai [FormSection] yang sama
/// dengan Tahap 1 (OssFormPage), supaya gaya visualnya konsisten.
///
/// Panggilan live-check NIB/KBLI/NKU (endpoint /oss/validasi-akomodasi)
/// SENGAJA tidak dilakukan di sini - didelegasikan ke [onCekValidasi] yang
/// disuplai parent, supaya widget ini tidak perlu tahu soal ApiClient.
class AkomodasiItemCard extends StatefulWidget {
  const AkomodasiItemCard({
    super.key,
    required this.index,
    required this.data,
    required this.regionService,
    required this.onChanged,
    required this.onRemove,
    required this.onCekValidasi,
    this.initiallyExpanded = true,
  });

  final int index;
  final AkomodasiItemData data;
  final RegionService regionService;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  /// Dipanggil saat tombol "Cek Validasi" ditekan. Parent yang mengurus
  /// loading state + panggilan service + memanggil
  /// `data.tandaiSudahDicek(...)` setelah hasil didapat.
  final Future<void> Function(AkomodasiItemData data) onCekValidasi;

  final bool initiallyExpanded;

  @override
  State<AkomodasiItemCard> createState() => _AkomodasiItemCardState();
}

class _AkomodasiItemCardState extends State<AkomodasiItemCard>
    with WidgetsBindingObserver, GpsCaptureMixin<AkomodasiItemCard> {
  static const _primary = AppTheme.primaryColor;

  late bool _expanded;
  bool _loadingRegions = true;
  bool _cekLoading = false;

  List<RegionOption> _provinces = [], _regencies = [], _districts = [], _villages = [];

  AkomodasiItemData get _d => widget.data;

  /// Section "Status Hasil Pengawasan" hanya relevan kalau:
  /// - akomodasi tidak punya NIB / status kepemilikan belum diketahui, atau
  /// - punya NIB tapi hasil live-check terakhir TIDAK_VALID.
  /// Kalau punya NIB dan sudah valid, section ini disembunyikan (mirip
  /// Tahap 1 yang menyembunyikan "Status Hasil Pengawasan" saat isValid).
  bool get _tampilkanStatusSection {
    if (!_d.memilikiNibYa) return true;
    return _d.validasiStatus == AkomodasiValidasiStatus.tidakValid;
  }

  @override
  void initState() {
    super.initState();
    initGpsCapture();
    _expanded = widget.initiallyExpanded;
    _muatWilayahAwal();
  }

  @override
  void dispose() {
    disposeGpsCapture();
    super.dispose();
  }

  Future<void> _muatWilayahAwal() async {
    final provinces = await widget.regionService.provinces();
    if (!mounted) return;

    List<RegionOption> regencies = [], districts = [], villages = [];

    if (_d.provinsiId != null) {
      regencies = await widget.regionService.regencies(_d.provinsiId!);
    }
    if (_d.kabupatenId != null) {
      districts = await widget.regionService.districts(_d.kabupatenId!);
    }
    if (_d.kecamatanId != null) {
      villages = await widget.regionService.villages(_d.kecamatanId!);
    }

    if (!mounted) return;
    setState(() {
      _provinces = provinces;
      _regencies = regencies;
      _districts = districts;
      _villages = villages;
      _loadingRegions = false;
    });
  }

  Future<void> _onProvinsiChanged(int? id) async {
    setState(() {
      _d.provinsiId = id;
      _d.kabupatenId = null;
      _d.kecamatanId = null;
      _d.kelurahanId = null;
      _regencies = [];
      _districts = [];
      _villages = [];
    });
    widget.onChanged();
    if (id == null) return;
    final regencies = await widget.regionService.regencies(id);
    if (!mounted) return;
    setState(() => _regencies = regencies);
  }

  Future<void> _onKabupatenChanged(int? id) async {
    setState(() {
      _d.kabupatenId = id;
      _d.kecamatanId = null;
      _d.kelurahanId = null;
      _districts = [];
      _villages = [];
    });
    widget.onChanged();
    if (id == null) return;
    final districts = await widget.regionService.districts(id);
    if (!mounted) return;
    setState(() => _districts = districts);
  }

  Future<void> _onKecamatanChanged(int? id) async {
    setState(() {
      _d.kecamatanId = id;
      _d.kelurahanId = null;
      _villages = [];
    });
    widget.onChanged();
    if (id == null) return;
    final villages = await widget.regionService.villages(id);
    if (!mounted) return;
    setState(() => _villages = villages);
  }

  Future<void> _cekValidasi() async {
    setState(() => _cekLoading = true);
    await widget.onCekValidasi(_d);
    if (!mounted) return;
    setState(() => _cekLoading = false);
  }

  Future<void> _gps() => ambilLokasiGps(
        onBerhasil: (hasil) => setState(() {
          _d.latitude = hasil.position.latitude.toStringAsFixed(8);
          _d.longitude = hasil.position.longitude.toStringAsFixed(8);
        }),
      );

  /// Ganti pilihan Kepemilikan NIB. Status hasil pengawasan SELALU direset
  /// di sini - kalau pindah ke TIDAK, langsung dikunci ke satu nilai tetap
  /// (mirip perilaku form_manajemen_akomodasi di web: satu checkbox
  /// "Tidak punya NIB" yang otomatis tercentang, tanpa pilihan lain).
  void _pilihMemilikiNib(String v) {
    setState(() {
      _d.memilikiNib = v;
      _d.resetStatusValidasi();
      _d.statusKetidaksesuaian.clear();
      _d.keteranganKetidaksesuaian = '';
      if (v == 'TIDAK') {
        _d.statusKetidaksesuaian.add('NIB_TIDAK_DITEMUKAN');
      }
    });
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi.' : null;

  @override
  Widget build(BuildContext context) {
    final Color border = AppTheme.border(context);
    final Color surface = AppTheme.surface(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(14),
              child: _loadingRegions
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _isiForm(),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted(context),
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(15),
            bottom: _expanded ? Radius.zero : const Radius.circular(15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                '${widget.index + 1}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _d.namaBrand.trim().isEmpty
                    ? 'Akomodasi ${widget.index + 1}'
                    : _d.namaBrand,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            _StatusBadge(status: _d.validasiStatus),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: widget.onRemove,
              tooltip: 'Hapus akomodasi ini',
            ),
            Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
      ),
    );
  }

  Widget _isiForm() {
    final List<Widget> sections = [];
    int nomor = 1;

    // 1. Kepemilikan NIB
    sections.add(
      FormSection(
        number: nomor++,
        title: 'Kepemilikan NIB',
        subtitle: 'Cek NIB/KBLI/NKU akomodasi ini ke server OSS.',
        icon: Icons.badge_outlined,
        child: _sectionKepemilikanNib(),
      ),
    );

    // 2. Status Hasil Pengawasan (kondisional)
    if (_tampilkanStatusSection) {
      sections.add(
        FormSection(
          number: nomor++,
          title: 'Status Hasil Pengawasan',
          subtitle: 'Pilih kondisi yang ditemukan di lapangan.',
          icon: Icons.report_gmailerrorred_rounded,
          child: _sectionStatusPengawasan(),
        ),
      );
    }

    // 3. Identitas Usaha
    sections.add(
      FormSection(
        number: nomor++,
        title: 'Identitas Usaha',
        icon: Icons.storefront_outlined,
        child: _sectionIdentitas(),
      ),
    );

    // 4. Wilayah dan Alamat
    sections.add(
      FormSection(
        number: nomor++,
        title: 'Wilayah dan Alamat',
        subtitle: 'Pilih wilayah secara berurutan hingga kelurahan.',
        icon: Icons.location_city,
        child: _sectionWilayah(),
      ),
    );

    // 5. Lokasi
    sections.add(
      FormSection(
        number: nomor++,
        title: 'Titik Lokasi',
        subtitle: 'Ambil koordinat GPS di lokasi akomodasi.',
        icon: Icons.my_location_rounded,
        child: LocationPicker(
          latitude: _d.latitude,
          longitude: _d.longitude,
          loading: gpsLoading,
          status: gpsStatus,
          sisaDetik: gpsCountdown,
          source: gpsSource,
          savedAt: gpsSavedAt,
          onGetLocation: _gps,
        ),
      ),
    );

    // 6. Kontak
    sections.add(
      FormSection(
        number: nomor++,
        title: 'Kontak',
        icon: Icons.contact_phone_outlined,
        child: _sectionKontak(),
      ),
    );

    // 7. Platform OTA
    sections.add(
      FormSection(
        number: nomor++,
        title: 'Platform OTA',
        subtitle: 'Catat platform dan URL listing akomodasi ini.',
        icon: Icons.travel_explore,
        child: _sectionOta(),
      ),
    );

    // 8. Foto Dokumentasi
    sections.add(
      FormSection(
        number: nomor++,
        title: 'Foto Dokumentasi',
        subtitle: 'Tambahkan 1–5 foto kondisi akomodasi ini.',
        icon: Icons.photo_camera,
        child: PhotoPicker(
          photos: _d.photos,
          onChanged: (v) => setState(() {
            _d.photos
              ..clear()
              ..addAll(v);
            widget.onChanged();
          }),
        ),
      ),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: sections);
  }

  Widget _sectionKepemilikanNib() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kepemilikan NIB *', style: _label(context)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['YA', 'TIDAK', 'TIDAK TAHU'].map((v) {
            return ChoiceChip(
              label: Text(v),
              selected: _d.memilikiNib == v,
              onSelected: (_) => _pilihMemilikiNib(v),
            );
          }).toList(),
        ),
        if (_d.memilikiNibYa) ...[
          const SizedBox(height: 14),
          TextFormField(
            initialValue: _d.nib,
            decoration: const InputDecoration(labelText: 'NIB *'),
            keyboardType: TextInputType.number,
            validator: _required,
            onChanged: (v) => setState(() {
              _d.nib = v;
              _d.resetStatusValidasi();
            }),
          ),
          const SizedBox(height: 10),
          TextFormField(
            initialValue: _d.kbli,
            decoration: const InputDecoration(labelText: 'KBLI *'),
            keyboardType: TextInputType.number,
            maxLength: 5,
            validator: _required,
            onChanged: (v) => setState(() {
              _d.kbli = v;
              _d.resetStatusValidasi();
            }),
          ),
          TextFormField(
            initialValue: _d.nku,
            decoration: const InputDecoration(labelText: 'NKU *', hintText: 'Tanpa prefix R-'),
            validator: _required,
            onChanged: (v) => setState(() {
              _d.nku = v;
              _d.resetStatusValidasi();
            }),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _cekLoading ? null : _cekValidasi,
              icon: _cekLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fact_check_outlined),
              label: Text(_cekLoading ? 'Memeriksa...' : 'Cek Validasi NIB/KBLI/NKU'),
            ),
          ),
          if (_d.pesanValidasiTerakhir != null) ...[
            const SizedBox(height: 6),
            Text(
              _d.pesanValidasiTerakhir!,
              style: TextStyle(
                fontSize: 12,
                color: _d.validasiStatus == AkomodasiValidasiStatus.valid
                    ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _sectionStatusPengawasan() {
    // TIDAK - terkunci, satu opsi tetap, tidak bisa diubah. Nilainya sudah
    // otomatis diisi ('NIB_TIDAK_DITEMUKAN') oleh _pilihMemilikiNib().
    if (_d.memilikiNib == 'TIDAK') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.scaffoldColorDynamic(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary(context), size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Tidak punya NIB',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    // TIDAK TAHU - 3 pilihan.
    if (_d.memilikiNib == 'TIDAK TAHU') {
      return StatusKetidaksesuaianSelector(
        options: StatusKetidaksesuaianSelector.nonOssTidakTahuOptions,
        selected: _d.statusKetidaksesuaian,
        onChanged: (v) => setState(() {
          _d.statusKetidaksesuaian
            ..clear()
            ..addAll(v);
        }),
        keteranganLainnya: _d.keteranganKetidaksesuaian,
        onKeteranganChanged: (v) => _d.keteranganKetidaksesuaian = v,
      );
    }

    // YA tapi hasil live-check TIDAK_VALID.
    return StatusKetidaksesuaianSelector(
      options: StatusKetidaksesuaianSelector.ossStatusHasilOptions,
      selected: _d.statusKetidaksesuaian,
      onChanged: (v) => setState(() {
        _d.statusKetidaksesuaian
          ..clear()
          ..addAll(v);
      }),
      keteranganLainnya: _d.keteranganKetidaksesuaian,
      onKeteranganChanged: (v) => _d.keteranganKetidaksesuaian = v,
    );
  }

  Widget _sectionIdentitas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: _d.namaPemilik,
          decoration: const InputDecoration(labelText: 'Nama Pemilik *'),
          validator: _required,
          onChanged: (v) => setState(() {
            _d.namaPemilik = v;
            widget.onChanged();
          }),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: _d.namaBrand,
          decoration: const InputDecoration(labelText: 'Nama Brand/Usaha *'),
          validator: _required,
          onChanged: (v) => setState(() {
            _d.namaBrand = v;
            widget.onChanged();
          }),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _d.jenisProduk.isEmpty ? null : _d.jenisProduk,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Jenis Produk Akomodasi *',
            prefixIcon: Icon(Icons.category_outlined, size: 20),
          ),
          items: JenisProdukAkomodasi.options
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) => setState(() => _d.jenisProduk = v ?? ''),
          validator: (v) => v == null ? 'Wajib dipilih.' : null,
        ),
      ],
    );
  }

  Widget _sectionWilayah() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _region('Provinsi', _d.provinsiId, _provinces, _onProvinsiChanged),
        _region('Kabupaten/Kota', _d.kabupatenId, _regencies, _onKabupatenChanged),
        _region('Kecamatan', _d.kecamatanId, _districts, _onKecamatanChanged),
        _region('Kelurahan/Desa', _d.kelurahanId, _villages, (id) => setState(() => _d.kelurahanId = id)),
        TextFormField(
          initialValue: _d.alamat,
          decoration: const InputDecoration(labelText: 'Alamat Lengkap *'),
          maxLines: 2,
          validator: _required,
          onChanged: (v) => _d.alamat = v,
        ),
      ],
    );
  }

  Widget _sectionKontak() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: _d.npwpd,
          decoration: const InputDecoration(labelText: 'NPWPD'),
          onChanged: (v) => _d.npwpd = v,
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: _d.website,
          decoration: const InputDecoration(labelText: 'Website'),
          keyboardType: TextInputType.url,
          onChanged: (v) => _d.website = v,
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: _d.noHp,
          decoration: const InputDecoration(labelText: 'No. HP *'),
          keyboardType: TextInputType.phone,
          validator: _required,
          onChanged: (v) => _d.noHp = v,
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: _d.email,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => _d.email = v,
        ),
      ],
    );
  }

  Widget _sectionOta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Apakah terdaftar di OTA? *', style: _label(context)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['YA', 'TIDAK'].map((v) {
            return ChoiceChip(
              label: Text(v),
              selected: _d.terdaftarOta == v,
              onSelected: (_) => setState(() => _d.terdaftarOta = v),
            );
          }).toList(),
        ),
        if (_d.terdaftarOtaYa) ...[
          const SizedBox(height: 12),
          OtaPlatformSelector(
            urls: _d.otaUrls,
            onChanged: (v) => setState(() {
              _d.otaUrls
                ..clear()
                ..addAll(v);
            }),
          ),
        ],
      ],
    );
  }

  Widget _region(String label, int? value, List<RegionOption> values, ValueChanged<int?> onChanged) {
    final int? nilai = values.any((r) => r.id == value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        initialValue: nilai,
        isExpanded: true,
        decoration: InputDecoration(labelText: '$label *'),
        items: values
            .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? 'Wajib dipilih.' : null,
      ),
    );
  }

  TextStyle _label(BuildContext context) => TextStyle(
        color: AppTheme.textColor(context),
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final AkomodasiValidasiStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (status) {
      AkomodasiValidasiStatus.valid => (Colors.green, Icons.check_circle),
      AkomodasiValidasiStatus.tidakValid => (Colors.orange, Icons.error),
      AkomodasiValidasiStatus.gagalKoneksi => (Colors.red, Icons.wifi_off),
      AkomodasiValidasiStatus.sedangMemeriksa => (Colors.blueGrey, Icons.hourglass_top),
      AkomodasiValidasiStatus.belumDicek => (Colors.grey, Icons.circle_outlined),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(icon, size: 18, color: color),
    );
  }
}