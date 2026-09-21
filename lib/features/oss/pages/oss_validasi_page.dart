import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';

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
  });

  /// Diisi saat dibuka dari daftar usaha. Kalau ketiganya ada, pengecekan
  /// ke API OSS langsung dijalankan tanpa menunggu tombol ditekan.
  final String? initialNib;
  final String? initialKbli;
  final String? initialNku;
  final String? namaUsaha;

  @override
  State<OssValidasiPage> createState() => _OssValidasiPageState();
}

class _OssValidasiPageState extends State<OssValidasiPage> {
  static const _primary = AppTheme.primaryColor;
  static const _navy = Color(0xFF0B3F78);

  final _key = GlobalKey<FormState>();
  final _nibCtrl = TextEditingController();
  final _kbliCtrl = TextEditingController();
  final _nkuCtrl = TextEditingController();

  late final ApiClient _api;
  late final OssService _ossService;

  String? _kbliDesc;
  bool _submitting = false;

  static const List<String> _daftarKbliDiizinkan = [
    '55105',
    '55104',
    '55103',
    '55102',
    '55101',
    '55106',
    '55203',
    '55201',
    '55202',
    '55204',
    '55300',
    '55209',
    '87303',
    '55909',
    '55901',
    '55110',
    '55120',
    '55130',
    '55191',
    '55192',
    '55193',
    '55194',
    '55199',
    '55900',
  ];

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _ossService = OssService(_api);

    _nibCtrl.text = (widget.initialNib ?? '').trim();
    _kbliCtrl.text = (widget.initialKbli ?? '').trim();
    _nkuCtrl.text = (widget.initialNku ?? '').trim();

    // KBLI 55900 butuh pilihan jenis usaha dari petugas, jadi tidak otomatis.
    if (_dariDaftar && !_isKbli55900) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _submit();
      });
    }
  }

  @override
  void dispose() {
    _nibCtrl.dispose();
    _kbliCtrl.dispose();
    _nkuCtrl.dispose();
    super.dispose();
  }

  bool get _isKbli55900 => _kbliCtrl.text.trim() == '55900';

  bool get _dariDaftar =>
      (widget.initialNib ?? '').trim().isNotEmpty &&
      (widget.initialKbli ?? '').trim().isNotEmpty &&
      (widget.initialNku ?? '').trim().isNotEmpty;

  String? _kbliValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Wajib diisi.';
    if (value.length != 5) return 'KBLI harus 5 digit.';
    if (!_daftarKbliDiizinkan.contains(value)) {
      return 'KBLI tidak termasuk dalam daftar yang diizinkan.';
    }
    return null;
  }

  String? _requiredValidator(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi.' : null;

  void _showError(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _submit() async {
    final bool valid = _key.currentState?.validate() ?? false;

    if (_isKbli55900 && _kbliDesc == null) {
      setState(() {}); // memicu rebuild supaya pesan error jenis usaha tampil
    }

    if (!valid || (_isKbli55900 && _kbliDesc == null)) {
      _showError('Periksa kembali data yang diisi.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final OssValidasiResult hasilApi = await _ossService.validasi(
        nib: _nibCtrl.text.trim(),
        kbli: _kbliCtrl.text.trim(),
        nku: _nkuCtrl.text.trim(),
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
                        'NIB, KBLI, dan NKU diisi otomatis dari daftar.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _nkuCtrl,
                // readOnly: _dariDaftar,
                decoration: const InputDecoration(
                  labelText: 'NKU *',
                  hintText: 'Contoh: 202210051139546023359',
                  prefixIcon: Icon(Icons.key_outlined, size: 20),
                ),
                keyboardType: TextInputType.number,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nibCtrl,
                // readOnly: _dariDaftar,
                decoration: const InputDecoration(
                  labelText: 'NIB *',
                  hintText: 'Masukkan NIB',
                  prefixIcon: Icon(Icons.credit_card_outlined, size: 20),
                ),
                keyboardType: TextInputType.number,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kbliCtrl,
                // readOnly: _dariDaftar,
                decoration: const InputDecoration(
                  labelText: 'KBLI *',
                  hintText: 'Masukkan 5 digit KBLI',
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                ),
                keyboardType: TextInputType.number,
                maxLength: 5,
                validator: _kbliValidator,
                onChanged: (_) => setState(() {}),
              ),
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
                ...<MapEntry<String, String>>[
                  const MapEntry('MANAJEMEN AKOMODASI', 'Manajemen Akomodasi'),
                  const MapEntry('SENIOR LIVING', 'Senior Living'),
                  const MapEntry('KOS-KOSAN/ASRAMA', 'Kos-kosan/Asrama'),
                ].map(
                  (entry) => RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: entry.key,
                    groupValue: _kbliDesc,
                    title: Text(entry.value),
                    onChanged: (v) => setState(() => _kbliDesc = v),
                  ),
                ),
                if (_kbliDesc == null)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      'Wajib dipilih.',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
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
