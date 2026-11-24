import 'package:flutter/material.dart';
import 'package:ipardasbor/core/network/network_status.dart';
import 'package:ipardasbor/features/pengawasan/oss/pages/oss_akomodasi_review_page.dart';
import 'package:ipardasbor/features/pengawasan/riwayat/models/riwayat_detail.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../shared/region/services/region_service.dart';
import '../models/oss_akomodasi_item_data.dart';
import '../models/oss_form_data.dart';
import '../services/oss_akomodasi_service.dart';
import '../widgets/oss_akomodasi_item_card.dart';

/// Tahap 2 - Akomodasi yang Dikelola. Dibuka dari [OssFormPage] setelah
/// identitas Tahap 1 (Manajemen Akomodasi) diisi, TAPI belum dikirim ke
/// server. Tahap 1 baru benar-benar dikirim SEKALI bersamaan dengan
/// Tahap 2 di [AkomodasiReviewPage].
///
/// Mode edit ([editRiwayat] != null): daftar item diisi dari data server.
/// Item lama bisa diedit (kecuali NIB/KBLI/NKU) atau dihapus, dan item
/// baru bisa ditambah.
class AkomodasiFormPage extends StatefulWidget {
  const AkomodasiFormPage({super.key, required this.tahap1, this.editRiwayat});

  final OssFormData tahap1;
  final RiwayatDetail? editRiwayat;

  @override
  State<AkomodasiFormPage> createState() => _AkomodasiFormPageState();
}

class _AkomodasiFormPageState extends State<AkomodasiFormPage> {
  final _key = GlobalKey<FormState>();
  final RegionService _regions = RegionService();
  late final AkomodasiService _service;
  late final ApiClient _api;

  late final List<AkomodasiItemData> _items;

  /// Id item lama yang dihapus petugas (hanya mode edit).
  final List<int> _hapusAkomodasiIds = <int>[];

  bool get _isEditing => widget.editRiwayat != null;

  @override
  void initState() {
    super.initState();
    _api = ApiClient.shared;
    _service = AkomodasiService(_api);

    _items = _isEditing
        ? widget.editRiwayat!.akomodasi
              .map(AkomodasiItemData.fromDetail)
              .toList()
        : <AkomodasiItemData>[];

    if (_items.isEmpty) _items.add(AkomodasiItemData());
  }

  void _tambahAkomodasi() => setState(() => _items.add(AkomodasiItemData()));

  Future<void> _hapusAkomodasi(int index) async {
    if (_items.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada satu data akomodasi.')),
      );
      return;
    }

    final AkomodasiItemData item = _items[index];

    // Item yang sudah ada di server: konfirmasi dulu, karena foto dan OTA-nya
    // ikut terhapus saat perubahan disimpan.
    if (item.id != null) {
      final bool? yakin = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Hapus akomodasi ini?'),
          content: const Text(
            'Data beserta foto dan OTA akomodasi ini akan dihapus dari server '
            'setelah Anda menyimpan perubahan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );
      if (yakin != true || !mounted) return;
      _hapusAkomodasiIds.add(item.id!);
    }

    setState(() => _items.remove(item));
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _cekValidasi(AkomodasiItemData item) async {
    if (!await NetworkGuard.pastikanOnline(context)) return;
    if (!mounted) return;

    try {
      final hasil = await _service.cek(
        nib: item.nib,
        kbli: item.kbli,
        nku: item.nku,
      );
      item.tandaiSudahDicek(valid: hasil.valid, pesan: hasil.pesan);
    } on ApiException catch (e) {
      item.tandaiSudahDicek(valid: false, pesan: e.message);
    } catch (_) {
      item.tandaiSudahDicek(
        valid: false,
        pesan: 'Gagal memeriksa. Periksa koneksi internet.',
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final bool formValid = _key.currentState?.validate() ?? false;

    final List<int> belumLengkap = <int>[];
    for (int i = 0; i < _items.length; i++) {
      if (!_items[i].lengkapUntukDisimpan) belumLengkap.add(i + 1);
    }

    if (!formValid || belumLengkap.isNotEmpty) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            belumLengkap.isNotEmpty
                ? 'Lengkapi data akomodasi nomor: ${belumLengkap.join(', ')}.'
                : 'Periksa kembali data yang diisi.',
          ),
        ),
      );
      return;
    }

    // Submit sungguhan tidak di sini - lihat AkomodasiReviewPage.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AkomodasiReviewPage(
          tahap1: widget.tahap1,
          akomodasi: _items,
          editRiwayat: widget.editRiwayat,
          hapusAkomodasiIds: List<int>.unmodifiable(_hapusAkomodasiIds),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              _isEditing
                  ? 'Edit Tahap 2 - Akomodasi'
                  : 'Tahap 2 - Akomodasi yang Dikelola',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              _isEditing
                  ? 'NIB, KBLI, dan NKU akomodasi lama terkunci'
                  : 'Minimal satu akomodasi, isi lengkap tiap kartu',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (int i = 0; i < _items.length; i++)
              AkomodasiItemCard(
                key: ValueKey(_items[i]),
                index: i,
                data: _items[i],
                regionService: _regions,
                onChanged: () => setState(() {}),
                onRemove: () => _hapusAkomodasi(i),
                onCekValidasi: _cekValidasi,
              ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _tambahAkomodasi,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Tambah Akomodasi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: const Icon(
                  Icons.rate_review_outlined,
                  color: Colors.white,
                ),
                label: const Text(
                  'Review & Simpan',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}