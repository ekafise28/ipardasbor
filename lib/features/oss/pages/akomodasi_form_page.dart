import 'package:flutter/material.dart';
import 'package:ipardasbor/features/oss/pages/akomodasi_review_page.dart';

import '../../../app/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../non_oss/services/region_service.dart';
import '../models/akomodasi_item_data.dart';
import '../models/oss_form_data.dart';
import '../services/akomodasi_service.dart';
import '../widgets/akomodasi_item_card.dart';

/// Tahap 2 - Akomodasi yang Dikelola. Dibuka dari [OssFormPage] setelah
/// identitas Tahap 1 (Manajemen Akomodasi) diisi, TAPI belum dikirim ke
/// server. Tahap 1 baru benar-benar dikirim SEKALI bersamaan dengan
/// Tahap 2 saat tombol "Simpan" di halaman ini ditekan - lihat
/// AkomodasiService.submit dan OssPengawasanController::
/// mobileStorePengawasanAkomodasi di backend untuk alasan atomic-nya.
class AkomodasiFormPage extends StatefulWidget {
  const AkomodasiFormPage({super.key, required this.tahap1});

  final OssFormData tahap1;

  @override
  State<AkomodasiFormPage> createState() => _AkomodasiFormPageState();
}

class _AkomodasiFormPageState extends State<AkomodasiFormPage> {
  static const _navy = Color(0xFF0B3F78);

  final _key = GlobalKey<FormState>();
  final RegionService _regions = RegionService();
  late final AkomodasiService _service;

  final List<AkomodasiItemData> _items = [AkomodasiItemData()];

  @override
  void initState() {
    super.initState();
    _service = AkomodasiService(ApiClient());
  }

  void _tambahAkomodasi() => setState(() => _items.add(AkomodasiItemData()));

  void _hapusAkomodasi(int index) {
    if (_items.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada satu data akomodasi.')),
      );
      return;
    }
    setState(() => _items.removeAt(index));
  }

  Future<void> _cekValidasi(AkomodasiItemData item) async {
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

    // Submit sungguhan tidak lagi di sini - lihat AkomodasiReviewPage.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AkomodasiReviewPage(tahap1: widget.tahap1, akomodasi: _items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              'Tahap 2 — Akomodasi yang Dikelola',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              'Minimal satu akomodasi, isi lengkap tiap kartu',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400),
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
