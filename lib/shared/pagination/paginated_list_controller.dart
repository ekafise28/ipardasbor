import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';

/// Satu halaman hasil dari server, dalam bentuk yang netral supaya bisa
/// dipakai semua daftar berhalaman (OSS, baseline OTA, riwayat).
///
/// [meta] membawa objek hasil asli untuk data tambahan khas halaman
/// (opsi filter, nama provinsi, ringkasan). Halaman membacanya lewat
/// `onLoaded` dengan cast ke tipe hasilnya sendiri.
class PageChunk<T> {
  const PageChunk({
    required this.items,
    required this.currentPage,
    required this.hasNext,
    required this.total,
    this.meta,
  });

  final List<T> items;
  final int currentPage;
  final bool hasNext;
  final int total;
  final Object? meta;
}

/// Mengelola daftar berhalaman: muat awal, muat berikutnya (infinite
/// scroll), muat ulang diam-diam, dan refresh satu halaman setelah sebuah
/// item berubah.
///
/// Controller tidak tahu apa-apa soal filter. Halaman mengubah filternya
/// sendiri lalu memanggil [reload]; [fetchPage] membaca filter terbaru.
///
/// Respons lama diabaikan lewat penghitung permintaan, sehingga hasil yang
/// terlambat tidak menimpa hasil yang lebih baru.
class PaginatedListController<T> extends ChangeNotifier {
  PaginatedListController({
    required this.fetchPage,
    required this.idOf,
    required this.perPage,
    this.onLoaded,
    this.onSilentError,
    this.errorMessage,
  });

  /// Mengambil halaman ke-[page] (mulai dari 1) dengan filter saat ini.
  final Future<PageChunk<T>> Function(int page) fetchPage;

  /// Identitas unik item, dipakai [refreshItem] untuk mencari posisinya.
  final Object Function(T item) idOf;

  /// Jumlah item per halaman server (dibaca saat dibutuhkan, karena filter
  /// bisa berubah).
  final int Function() perPage;

  /// Dipanggil setelah halaman pertama dimuat atau satu halaman di-refresh,
  /// tepat sebelum listener diberi tahu. Cukup isi field; tidak perlu
  /// `setState`.
  final void Function(PageChunk<T> chunk)? onLoaded;

  /// Dipanggil saat muat ulang diam-diam gagal tetapi daftar masih terisi.
  /// Biasanya ditampilkan sebagai snackbar.
  final void Function(String message)? onSilentError;

  /// Mengubah error menjadi pesan untuk pengguna. Default: pesan dari
  /// [ApiException], atau teks generik.
  final String Function(Object error)? errorMessage;

  final List<T> _items = <T>[];
  int _requestId = 0;
  bool _disposed = false;

  int _currentPage = 1;
  bool _hasNext = false;
  int _total = 0;
  bool _loadingFirst = true;
  bool _loadingMore = false;
  bool _loadMoreError = false;
  String? _loadMoreMessage;
  String? _error;

  List<T> get items => UnmodifiableListView<T>(_items);
  int get currentPage => _currentPage;
  bool get hasNext => _hasNext;
  int get total => _total;
  bool get loadingFirst => _loadingFirst;
  bool get loadingMore => _loadingMore;

  /// Gagal memuat halaman berikutnya. Selama true, scroll tidak memicu muat
  /// ulang otomatis; pengguna menekan "Coba lagi" ([retryLoadMore]).
  bool get loadMoreError => _loadMoreError;
  String? get loadMoreMessage => _loadMoreMessage;

  /// Pesan error muat awal; null kalau tidak ada error.
  String? get error => _error;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  String _pesanMuat(Object e) {
    final String Function(Object)? custom = errorMessage;
    if (custom != null) return custom(e);
    if (e is ApiException) return e.message;
    return 'Terjadi kesalahan yang tidak terduga.';
  }

  void _terapkan(PageChunk<T> chunk) {
    _currentPage = chunk.currentPage;
    _hasNext = chunk.hasNext;
    _total = chunk.total;
  }

  /// Memuat ulang dari halaman pertama.
  ///
  /// [showLoading] true: tampilkan skeleton (loadingFirst) dan kosongkan
  /// error. false: daftar lama tetap tampil; kalau gagal dan daftar masih
  /// terisi, errornya dikirim lewat [onSilentError].
  Future<void> reload({bool showLoading = true}) async {
    final int id = ++_requestId;

    _loadingMore = false;
    _loadMoreError = false;
    _loadMoreMessage = null;
    if (showLoading) {
      _loadingFirst = true;
      _error = null;
    }
    _notify();

    try {
      final PageChunk<T> chunk = await fetchPage(1);
      if (_disposed || id != _requestId) return;

      _items
        ..clear()
        ..addAll(chunk.items);
      _terapkan(chunk);
      _loadingFirst = false;
      _error = null;
      onLoaded?.call(chunk);
      _notify();
    } catch (e) {
      if (_disposed || id != _requestId) return;

      final String pesan = _pesanMuat(e);
      _loadingFirst = false;
      if (!showLoading && _items.isNotEmpty) {
        onSilentError?.call(pesan);
      } else {
        _error = pesan;
      }
      _notify();
    }
  }

  /// Memuat halaman berikutnya. Aman dipanggil berulang dari listener
  /// scroll: diabaikan kalau sedang memuat, sedang gagal, atau sudah habis.
  Future<void> loadMore() async {
    if (_loadingMore || _loadingFirst || _loadMoreError || !_hasNext) return;

    final int id = _requestId;
    _loadingMore = true;
    _notify();

    try {
      final PageChunk<T> chunk = await fetchPage(_currentPage + 1);
      if (_disposed || id != _requestId) return;

      _items.addAll(chunk.items);
      _terapkan(chunk);
      _loadingMore = false;
      _notify();
    } catch (e) {
      if (_disposed || id != _requestId) return;

      _loadingMore = false;
      _loadMoreError = true;
      _loadMoreMessage = e is ApiException
          ? e.message
          : 'Gagal memuat data berikutnya.';
      _notify();
    }
  }

  /// Mencoba lagi setelah [loadMoreError].
  Future<void> retryLoadMore() {
    _loadMoreError = false;
    _loadMoreMessage = null;
    return loadMore();
  }

  /// Memuat ulang HANYA halaman server yang memuat [item], lalu mengganti
  /// irisan itu di daftar. Posisi scroll dan halaman lain tidak berubah.
  ///
  /// Kalau irisan itu halaman terakhir yang termuat, seluruh irisan diganti
  /// dengan hasil server. Kalau masih ada halaman termuat di bawahnya, irisan
  /// hanya diganti bila item masih ada di hasil dan jumlah barisnya sama;
  /// selain itu baris di halaman-halaman setelahnya sudah bergeser (mis.
  /// item tersaring keluar atau pindah posisi), sehingga dipakai muat ulang
  /// penuh tanpa skeleton.
  Future<void> refreshItem(T item) async {
    final Object id0 = idOf(item);
    final int index = _items.indexWhere((T e) => idOf(e) == id0);
    if (index < 0) {
      await reload(showLoading: false);
      return;
    }

    final int id = _requestId;
    final int ukuran = perPage();
    final int halaman = index ~/ ukuran + 1;
    final int awal = (halaman - 1) * ukuran;
    final int akhir = awal + ukuran < _items.length
        ? awal + ukuran
        : _items.length;

    try {
      final PageChunk<T> chunk = await fetchPage(halaman);
      if (_disposed || id != _requestId) return;

      // Irisan yang berujung di akhir daftar tidak punya halaman termuat
      // di bawahnya, jadi baris yang bergeser tidak bisa bentrok dengan
      // halaman lain: seluruh irisan boleh diganti apa adanya.
      final bool halamanTerakhir = akhir == _items.length;

      if (!halamanTerakhir) {
        final bool masihAda = chunk.items.any((T e) => idOf(e) == id0);
        if (!masihAda || chunk.items.length != akhir - awal) {
          await reload(showLoading: false);
          return;
        }
      }

      _items.replaceRange(awal, akhir, chunk.items);
      _total = chunk.total;
      if (halamanTerakhir) _hasNext = chunk.hasNext;
      onLoaded?.call(chunk);
      _notify();
    } catch (_) {
      if (_disposed) return;
      onSilentError?.call(
        'Daftar belum diperbarui. Tarik ke bawah untuk menyegarkan.',
      );
    }
  }
}