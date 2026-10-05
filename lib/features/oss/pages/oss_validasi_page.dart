import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
// OCR: import baru
import 'package:ipardasbor/core/constants/kbli_constants.dart';
import 'package:ipardasbor/shared/ocr/ocr_field_type.dart';
import 'package:ipardasbor/shared/ocr/ocr_paste_flow.dart';
import 'package:ipardasbor/shared/ocr/ocr_scan_flow.dart';
import 'package:ipardasbor/shared/widgets/ocr_field_actions.dart';
import 'package:ipardasbor/shared/widgets/ocr_scan_button.dart';

import '../../../core/api/api_client.dart';
import '../models/oss_validasi_result.dart';
import 'oss_form_page.dart';
import '../services/oss_service.dart';

/// Tahap 1: validasi NIB, KBLI, dan NKU sebelum masuk ke form lanjutan.
///
/// Mengikuti alur Laravel (oss_validasi_lanjutan) - validasi NIB dikirim
/// ke backend, yang kemudian meneruskannya ke API OSS pemerintah dan
/// mencocokkan KBLI/NKU-nya. Backend adalah sumber kebenaran; hasil valid/
/// tidak valid TIDAK ditentukan di sisi aplikasi.
class OssValidasiPage extends StatefulWidget {
  const OssValidasiPage({
    super.key,
    this.initialNib,
    this.initialKbli,
    this.initialNku,
    this.namaUsaha,
    this.baselineOtaId,
    this.bidang = 'akomodasi',
  });

  final String bidang;

  /// Diisi saat dibuka dari daftar usaha. Kalau ketiganya ada, field
  /// terisi otomatis dan petugas tinggal menekan tombol Cek Validasi.
  final String? initialNib;
  final String? initialKbli;
  final String? initialNku;
  final String? namaUsaha;

  /// ID baris tbl_oss_baseline_ota, kalau halaman ini dibuka lewat tombol
  /// "Ada NIB" di BaselineOtaPage (lewat OssProyekPage).
  final int? baselineOtaId;

  @override
  State<OssValidasiPage> createState() => _OssValidasiPageState();
}

class _OssValidasiPageState extends State<OssValidasiPage> {
  final _key = GlobalKey<FormState>();
  final _nibCtrl = TextEditingController();
  final _kbliCtrl = TextEditingController();
  final _nkuCtrl = TextEditingController();

  late final ApiClient _api;
  late final OssService _ossService;

  String? _kbliDesc;
  bool _submitting = false;

  // OCR: _daftarKbliDiizinkan dipindah ke KbliConstants.daftarDiizinkan.

  static const List<String> _daftarJenisUsaha55900 = [
    'Jasa Manajemen Hotel',
    'Senior Living',
    'Kos-kosan/Asrama',
  ];

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _ossService = OssService(_api);

    _nibCtrl.text = (widget.initialNib ?? '').trim();
    _kbliCtrl.text = (widget.initialKbli ?? '').trim();
    _nkuCtrl.text = (widget.initialNku ?? '').trim();

    // KBLI 55901 selalu otomatis Manajemen Akomodasi (sama seperti web),
    // tidak ada pilihan untuk petugas.
    if (_isKbli55901) {
      _kbliDesc = 'MANAJEMEN AKOMODASI';
    }
  }

  @override
  void dispose() {
    _nibCtrl.dispose();
    _kbliCtrl.dispose();
    _nkuCtrl.dispose();
    super.dispose();
  }

  bool get _isAkomodasi => widget.bidang == 'akomodasi';
  bool get _isKbli55900 => _isAkomodasi && _kbliCtrl.text.trim() == '55900';
  bool get _isKbli55901 => _isAkomodasi && _kbliCtrl.text.trim() == '55901';
  bool get _isKbliAkomodasiKhusus => _isKbli55900 || _isKbli55901;
  bool get _kbliDiLuarDaftar {
    if (!_isAkomodasi) return false; // daftar KbliConstants khusus akomodasi
    final String kbli = _kbliCtrl.text.trim();
    return kbli.length == 5 && !KbliConstants.isDiizinkan(kbli);
  }

  bool get _dariDaftar =>
      (widget.initialNib ?? '').trim().isNotEmpty &&
      (widget.initialKbli ?? '').trim().isNotEmpty &&
      (widget.initialNku ?? '').trim().isNotEmpty;

  String? _kbliValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Wajib diisi.';
    if (value.length != 5) return 'KBLI harus 5 digit.';
    // KBLI di luar daftar KbliConstants.daftarDiizinkan tetap diterima;
    // statusnya (mis. "KBLI tidak ada") ditentukan di OssFormPage.
    return null;
  }

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi.' : null;

  void _showError(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  // OCR: logika KBLI khusus yang tadinya inline di onChanged, dijadikan satu
  // fungsi supaya bisa dipanggil juga setelah controller diisi lewat kode
  // (mengisi controller TIDAK memicu onChanged).
  void _syncKbliState() {
    setState(() {
      if (_isKbli55901) {
        _kbliDesc = 'MANAJEMEN AKOMODASI';
      } else if (_isKbli55900) {
        // Nilai lama (mis. MANAJEMEN AKOMODASI dari 55901) tidak ada di
        // dropdown 55900 dan akan memicu assertion kalau dibiarkan.
        if (!_daftarJenisUsaha55900.contains(_kbliDesc)) _kbliDesc = null;
      } else {
        _kbliDesc = null;
      }
    });
  }

  // OCR: scan dari foto/screenshot lalu isi field yang dicentang pengguna.
  Future<void> _scanOcr(Set<OcrFieldType> targets) async {
    final Map<OcrFieldType, String>? values = await runOcrScan(
      context,
      targets: targets,
      currentValues: {
        OcrFieldType.nib: _nibCtrl.text.trim(),
        OcrFieldType.nku: _nkuCtrl.text.trim(),
        OcrFieldType.kbli: _kbliCtrl.text.trim(),
      },
    );
    if (!mounted || values == null || values.isEmpty) return;

    values.forEach((type, value) {
      switch (type) {
        case OcrFieldType.nib:
          _nibCtrl.text = value;
        case OcrFieldType.nku:
          _nkuCtrl.text = value;
        case OcrFieldType.kbli:
          _kbliCtrl.text = value;
      }
    });
    _syncKbliState();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${values.length} field diisi dari scan.')),
    );
  }

  // OCR: tempel dari clipboard ke satu field, dengan pembersihan otomatis.
  Future<void> _pasteInto(OcrFieldType type) async {
    final TextEditingController ctrl = switch (type) {
      OcrFieldType.nib => _nibCtrl,
      OcrFieldType.nku => _nkuCtrl,
      OcrFieldType.kbli => _kbliCtrl,
    };

    final String? value = await runPaste(
      context,
      type: type,
      currentValue: ctrl.text.trim(),
    );
    if (!mounted || value == null) return;

    ctrl.text = value;
    if (type == OcrFieldType.kbli) _syncKbliState();
  }

  Future<void> _submit() async {
    final bool valid = _key.currentState?.validate() ?? false;

    if (_isKbli55900 && _kbliDesc == null) {
      setState(() {}); // memicu rebuild supaya pesan error jenis usaha tampil
    }

    if (!valid || (_isKbliAkomodasiKhusus && _kbliDesc == null)) {
      _showError('Periksa kembali data yang diisi.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final OssValidasiResult hasilApi = await _ossService.validasi(
        nib: _nibCtrl.text.trim(),
        kbli: _kbliCtrl.text.trim(),
        nku: _nkuCtrl.text.trim(),
        bidang: widget.bidang,
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      // kbli_desc (khusus KBLI 55900) tetap dari pilihan user di halaman
      // ini - backend tidak menentukan jenis usaha spesifiknya.
      final OssValidasiResult hasil = OssValidasiResult(
        nib: hasilApi.nib,
        kbli: hasilApi.kbli,
        nku: hasilApi.nku,
        kbliDesc: _kbliDesc ?? '',
        isValid: hasilApi.isValid,
        proyek: hasilApi.proyek,
        baselineOtaId: widget.baselineOtaId,
        bidang: widget.bidang,
        dariDaftar: _dariDaftar,
      );

      if (!mounted) return;
      final bool? tersimpan = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => OssFormPage(validasi: hasil)),
      );

      // Dibuka dari daftar: halaman ini hanya perantara, jadi setelah form
      // ditutup (disimpan atau dibatalkan) langsung kembali ke daftar.
      if (mounted && (tersimpan == true || _dariDaftar)) {
        Navigator.of(context).pop(tersimpan == true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);

      final String pesan = _ossService.isConnectionFailure(e)
          ? 'Tidak dapat terhubung ke server. Periksa koneksi internet.'
          : e.toString().replaceFirst('Exception: ', '');

      _showError(pesan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          primary: AppTheme.primaryColor,
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
            borderSide: const BorderSide(
              color: AppTheme.primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldColorDynamic(context),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppTheme.primaryDark,
          foregroundColor: Colors.white,
          titleSpacing: 4,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Validasi Data OSS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(
                'Periksa NIB, KBLI, dan NKU usaha',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ),
        body: Form(
          key: _key,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    Icon(Icons.shield_outlined, color: Colors.white, size: 34),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cek NIB, KBLI, dan NKU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pastikan data sesuai sebelum lanjut ke form pengawasan.',
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
              if (_dariDaftar && widget.namaUsaha != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.namaUsaha!,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'NIB, KBLI, dan NKU diisi otomatis dari daftar. Tekan "Cek Validasi" untuk melanjutkan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              // OCR: tombol utama (scan semua field). Disembunyikan saat
              // dibuka dari daftar karena datanya sudah terisi otomatis.
              if (!_dariDaftar)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: OcrScanMainButton(
                    onPressed: _submitting
                        ? null
                        : () => _scanOcr(OcrFieldType.values.toSet()),
                  ),
                ),
              TextFormField(
                controller: _nkuCtrl,
                // readOnly: _dariDaftar,
                decoration: InputDecoration(
                  labelText: 'NKU *',
                  hintText: 'Contoh: 202210051139546023359',
                  prefixIcon: const Icon(Icons.key_outlined, size: 20),
                  // OCR: ikon scan per field
                  suffixIcon: _dariDaftar
                      ? null
                      : OcrFieldActions(
                          onPaste: _submitting
                              ? null
                              : () => _pasteInto(OcrFieldType.nku),
                          onScan: _submitting
                              ? null
                              : () => _scanOcr({OcrFieldType.nku}),
                        ),
                ),
                keyboardType: TextInputType.number,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nibCtrl,
                // readOnly: _dariDaftar,
                decoration: InputDecoration(
                  labelText: 'NIB *',
                  hintText: 'Masukkan NIB',
                  prefixIcon: const Icon(Icons.credit_card_outlined, size: 20),
                  // OCR: ikon scan per field
                  suffixIcon: _dariDaftar
                      ? null
                      : OcrFieldActions(
                          onPaste: _submitting
                              ? null
                              : () => _pasteInto(OcrFieldType.nib),
                          onScan: _submitting
                              ? null
                              : () => _scanOcr({OcrFieldType.nib}),
                        ),
                ),
                keyboardType: TextInputType.number,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kbliCtrl,
                // readOnly: _dariDaftar,
                decoration: InputDecoration(
                  labelText: 'KBLI *',
                  hintText: 'Masukkan 5 digit KBLI',
                  prefixIcon: const Icon(Icons.category_outlined, size: 20),
                  // Petunjuk non-blokir: KBLI tetap diterima, hanya memberi tahu petugas.
                  helperText: _kbliDiLuarDaftar
                      ? 'KBLI di luar daftar pengawasan, akan berstatus "KBLI tidak ada".'
                      : null,
                  helperMaxLines: 2,
                  // OCR: ikon scan per field
                  suffixIcon: _dariDaftar
                      ? null
                      : OcrFieldActions(
                          onPaste: _submitting
                              ? null
                              : () => _pasteInto(OcrFieldType.kbli),
                          onScan: _submitting
                              ? null
                              : () => _scanOcr({OcrFieldType.kbli}),
                        ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 5,
                validator: _kbliValidator,
                // OCR: logika dipindah ke _syncKbliState
                onChanged: (_) => _syncKbliState(),
              ),
              if (_isKbli55901) ...[
                const SizedBox(height: 4),
                Text(
                  'Jenis Usaha KBLI 55901',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldColorDynamic(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jasa Manajemen Hotel',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'KBLI 55901 otomatis diproses sebagai Manajemen Akomodasi.',
                              style: TextStyle(
                                color: AppTheme.textSecondary(context),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_isKbli55900) ...[
                const SizedBox(height: 4),
                Text(
                  'Jenis Usaha KBLI 55900 *',
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _kbliDesc,
                  isExpanded:
                      true, // <- ini yang biasanya hilang & bikin overflow
                  decoration: const InputDecoration(
                    hintText: 'Pilih jenis usaha penyediaan akomodasi lainnya',
                    prefixIcon: Icon(Icons.apartment_outlined, size: 20),
                  ),
                  items: _daftarJenisUsaha55900
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _kbliDesc = v),
                  validator: (v) => v == null ? 'Wajib dipilih.' : null,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.shield_outlined, color: Colors.white),
                  label: Text(
                    _submitting ? 'Memeriksa...' : 'Cek Validasi',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
