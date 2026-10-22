import 'dart:math' as math;

import '../models/proyek_data_filter.dart';
import '../models/proyek_data_item.dart';
import '../models/proyek_data_option.dart';
import '../models/proyek_data_page_result.dart';
import 'proyek_offline_meta.dart';

class ProyekOfflineEngine {
  ProyekOfflineEngine(this._items) {
    for (final ProyekDataItem e in _items) {
      if (e.versiKbli != null) {
        _versiPerKode.putIfAbsent(e.kbli, () => <int>{}).add(e.versiKbli!);
      }
    }
  }

  final List<ProyekDataItem> _items;
  final Map<String, Set<int>> _versiPerKode = <String, Set<int>>{};

  bool _cocok(ProyekDataItem e, ProyekDataFilter f) {
    if (f.provinsi != null && e.provinsi != f.provinsi) return false;
    if (f.kota.isNotEmpty && !f.kota.contains(e.kabKota)) return false;
    if (f.kbli.isNotEmpty && !f.kbli.contains(e.kbli)) return false;
    if (f.statusModal.isNotEmpty && !f.statusModal.contains(e.statusModal)) {
      return false;
    }
    if (f.risiko.isNotEmpty && !f.risiko.contains(e.risiko)) return false;
    if (f.versiKbli != null && e.versiKbli != f.versiKbli) return false;

    final String k = f.search.trim();
    if (k.isNotEmpty) {
      final bool ok =
          e.nib == k ||
          e.kbli == k ||
          e.namaPerusahaan.toLowerCase().startsWith(k.toLowerCase());
      if (!ok) return false;
    }
    return true;
  }

  ProyekDataPageResult halaman(
    ProyekDataFilter f,
    int page,
    ProyekOfflineMeta meta,
  ) {
    final List<ProyekDataItem> cocok = _items
        .where((ProyekDataItem e) => _cocok(e, f))
        .toList();

    final int total = cocok.length;
    final int lastPage = total == 0 ? 1 : (total + f.perPage - 1) ~/ f.perPage;
    final int hal = math.min(math.max(page, 1), lastPage);

    return ProyekDataPageResult(
      items: cocok.skip((hal - 1) * f.perPage).take(f.perPage).toList(),
      pagination: ProyekDataPagination(
        currentPage: hal,
        perPage: f.perPage,
        total: total,
        lastPage: lastPage,
        hasNextPage: hal < lastPage,
      ),
      provinsiUser: meta.provinsiUser,
      aksesSemuaWilayah: meta.aksesSemuaWilayah,
      dariOffline: true,
      waktuOffline: meta.savedAt,
    );
  }

  /// Pilihan filter dari isi dataset (hanya nilai yang memang ada).
  ProyekDataOptionResult opsi(
    ProyekDataOptionType tipe,
    String q,
    String? provinsi,
  ) {
    final String kata = q.trim().toLowerCase();

    ProyekDataOptionResult daftar(Iterable<String?> nilai) {
      final List<String> unik = nilai.whereType<String>().toSet().toList()
        ..sort();
      return ProyekDataOptionResult(
        options: unik
            .where((String v) => kata.isEmpty || v.toLowerCase().contains(kata))
            .take(100)
            .map((String v) => ProyekDataOption(value: v, label: v))
            .toList(),
      );
    }

    switch (tipe) {
      case ProyekDataOptionType.provinsi:
        return daftar(_items.map((ProyekDataItem e) => e.provinsi));
      case ProyekDataOptionType.kota:
        return daftar(
          _items
              .where((ProyekDataItem e) => provinsi == null || e.provinsi == provinsi)
              .map((ProyekDataItem e) => e.kabKota),
        );
      case ProyekDataOptionType.status:
        return daftar(_items.map((ProyekDataItem e) => e.statusModal));
      case ProyekDataOptionType.risiko:
        return daftar(_items.map((ProyekDataItem e) => e.risiko));
      case ProyekDataOptionType.kbli:
        if (kata.length < 2) {
          return const ProyekDataOptionResult(
            options: <ProyekDataOption>[],
            message: 'Ketik minimal 2 karakter kode atau nama KBLI.',
          );
        }
        final Map<String, ProyekDataOption> unik = <String, ProyekDataOption>{};
        for (final ProyekDataItem e in _items) {
          final String judul = e.judulKbli ?? '';
          if (!e.kbli.contains(kata) && !judul.toLowerCase().contains(kata)) {
            continue;
          }
          unik.putIfAbsent(
            '${e.kbli}|${e.versiKbli}',
            () => ProyekDataOption(
              value: e.kbli,
              label: '${e.kbli} - $judul',
              versi: e.versiKbli,
              bedaVersi: (_versiPerKode[e.kbli]?.length ?? 0) > 1,
            ),
          );
        }
        final List<ProyekDataOption> hasil = unik.values.toList()
          ..sort((ProyekDataOption a, ProyekDataOption b) =>
              a.value.compareTo(b.value));
        return ProyekDataOptionResult(options: hasil.take(100).toList());
    }
  }
}