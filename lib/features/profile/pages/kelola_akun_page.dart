import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class _Pengguna {
  const _Pengguna({
    required this.nama,
    required this.username,
    required this.email,
    required this.role,
  });

  final String nama;
  final String username;
  final String email;
  final String role;

  String get inisial {
    final List<String> bagian = nama.split(' ');
    final String a = bagian.first.isNotEmpty ? bagian.first[0] : '';
    final String b = bagian.length > 1 && bagian[1].isNotEmpty
        ? bagian[1][0]
        : '';
    return (a + b).toUpperCase();
  }
}

class KelolaAkunPage extends StatefulWidget {
  const KelolaAkunPage({super.key});

  @override
  State<KelolaAkunPage> createState() => _KelolaAkunPageState();
}

class _KelolaAkunPageState extends State<KelolaAkunPage> {
  static const List<String> _filters = ['Semua', 'Admin', 'Editor', 'Pengguna'];

  // Data dummy, nanti diganti data dari endpoint.
  final List<_Pengguna> _data = [
    const _Pengguna(
      nama: 'Budi Pratama',
      username: 'budi.pratama',
      email: 'budi.pratama@example.com',
      role: 'Admin',
    ),
    const _Pengguna(
      nama: 'Siti Rahmawati',
      username: 'siti.rahma',
      email: 'siti.rahma@example.com',
      role: 'Editor',
    ),
    const _Pengguna(
      nama: 'Ahmad Fauzi',
      username: 'ahmad.fauzi',
      email: 'ahmad.fauzi@example.com',
      role: 'Pengguna',
    ),
    const _Pengguna(
      nama: 'Dewi Lestari',
      username: 'dewi.lestari',
      email: 'dewi.l@example.com',
      role: 'Editor',
    ),
    const _Pengguna(
      nama: 'Rian Wijaya',
      username: 'rian.w',
      email: 'rian.w@example.com',
      role: 'Pengguna',
    ),
  ];

  final Set<String> _selected = <String>{};
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isCardView = true;
  String _filter = 'Semua';
  String _query = '';

  // Paginasi lokal: 3 akun per halaman.
  static const int _perPage = 3;
  int _page = 1;

  static const Color _merah = Color(0xFFC62828);
  static const Color _merahBg = Color(0x1FC62828);

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Pengguna> get _filtered {
    final String q = _query.trim().toLowerCase();
    return _data.where((p) {
      final bool cocokRole = _filter == 'Semua' || p.role == _filter;
      final bool cocokCari =
          q.isEmpty ||
              p.nama.toLowerCase().contains(q) ||
              p.username.toLowerCase().contains(q) ||
              p.role.toLowerCase().contains(q);
      return cocokRole && cocokCari;
    }).toList();
  }

  int _countFor(String filter) {
    if (filter == 'Semua') return _data.length;
    return _data.where((p) => p.role == filter).length;
  }

  int _totalHalaman(int total) {
    return total == 0 ? 1 : (total / _perPage).ceil();
  }

  /// (warna latar, warna teks) badge role, mengikuti tema aplikasi.
  (Color, Color) _warnaRole(String role) {
    switch (role) {
      case 'Admin':
        return (AppTheme.primaryColor, Colors.white);
      case 'Editor':
        return (const Color(0x33F59E0B), const Color(0xFFB45309));
      default:
        return (
        AppTheme.surfaceMuted(context),
        AppTheme.textSecondary(context),
        );
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF238636),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  void _toggleSelect(_Pengguna p, bool? value) {
    setState(() {
      if (value == true) {
        _selected.add(p.username);
      } else {
        _selected.remove(p.username);
      }
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      for (final _Pengguna p in _filtered) {
        if (value == true) {
          _selected.add(p.username);
        } else {
          _selected.remove(p.username);
        }
      }
    });
  }

  Future<void> _confirmDelete(String title, List<String> usernames) async {
    final bool? ya = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border(sheetContext),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: _merahBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: _merah,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konfirmasi Hapus',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textColor(sheetContext),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary(sheetContext),
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Apakah Anda yakin ingin menghapus ',
                                ),
                                TextSpan(
                                  text: title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textColor(sheetContext),
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                  '? Tindakan ini tidak dapat dibatalkan.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.surfaceMuted(sheetContext),
                          foregroundColor: AppTheme.textColor(sheetContext),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: _merah,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        child: const Text('Hapus Permanen'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (ya != true || !mounted) return;
    setState(() {
      _data.removeWhere((p) => usernames.contains(p.username));
      _selected.removeAll(usernames);
    });
    _toast('Data berhasil dihapus');
  }

  @override
  Widget build(BuildContext context) {
    final List<_Pengguna> list = _filtered;
    final int totalHalaman = _totalHalaman(list.length);
    if (_page > totalHalaman) _page = totalHalaman;
    final List<_Pengguna> halaman = list
        .skip((_page - 1) * _perPage)
        .take(_perPage)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        title: const Text('Kelola Akun'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: Column(
        children: [
          _buildControls(),
          _buildBulkBar(list),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'Tidak ada pengguna ditemukan',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                  )
                else if (_isCardView)
                  ...List.generate(
                    halaman.length,
                        (i) => _buildCard(
                      halaman[i],
                      (_page - 1) * _perPage + i + 1,
                    ),
                  )
                else
                  _buildTable(halaman),
                const SizedBox(height: 16),
                _buildPagination(list.length),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _toast('Membuka formulir tambah akun'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Akun',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ---- Bagian atas: pencarian, chip filter, view switcher ----
  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() {
              _query = v;
              _page = 1;
            }),
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textColor(context),
            ),
            decoration: InputDecoration(
              hintText: 'Cari nama, username, atau role...',
              hintStyle: TextStyle(color: AppTheme.textSecondary(context)),
              prefixIcon: Icon(
                Icons.search,
                color: AppTheme.textSecondary(context),
                size: 20,
              ),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                icon: Icon(
                  Icons.cancel,
                  size: 18,
                  color: AppTheme.textSecondary(context),
                ),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {
                    _query = '';
                    _page = 1;
                  });
                },
              ),
              filled: true,
              fillColor: AppTheme.surface(context),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.border(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, i) => _buildChip(_filters[i]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildViewToggle(Icons.view_agenda_outlined, true),
                    _buildViewToggle(Icons.table_rows_outlined, false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    final bool aktif = _filter == label;
    return GestureDetector(
      onTap: () => setState(() {
        _filter = label;
        _page = 1;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: aktif ? AppTheme.primaryColor : AppTheme.surfaceMuted(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: aktif ? Colors.white : AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${_countFor(label)}',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: aktif ? Colors.white : AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle(IconData icon, bool cardMode) {
    final bool aktif = _isCardView == cardMode;
    return GestureDetector(
      onTap: () => setState(() => _isCardView = cardMode),
      child: Container(
        width: 32,
        height: 28,
        decoration: BoxDecoration(
          color: aktif ? AppTheme.surface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: aktif
              ? AppTheme.primaryColor
              : AppTheme.textSecondary(context),
        ),
      ),
    );
  }

  // ---- Bar ringkasan + aksi massal ----
  Widget _buildBulkBar(List<_Pengguna> list) {
    final int dipilih = _selected.length;
    final bool semuaDipilih =
        list.isNotEmpty && list.every((p) => _selected.contains(p.username));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: semuaDipilih,
                onChanged: _toggleSelectAll,
                activeColor: AppTheme.primaryColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${list.length}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Akun',
              style: TextStyle(
                fontSize: 11.5,
                color: AppTheme.textSecondary(context),
              ),
            ),
            const Spacer(),
            if (dipilih > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$dipilih Dipilih',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Hapus terpilih',
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: _merahBg,
                  foregroundColor: _merah,
                ),
                onPressed: () => _confirmDelete(
                  '$dipilih item yang dipilih',
                  _selected.toList(),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---- Mode 1: kartu ----
  Widget _buildCard(_Pengguna p, int nomor) {
    final (Color roleBg, Color roleFg) = _warnaRole(p.role);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _selected.contains(p.username),
                      onChanged: (v) => _toggleSelect(p, v),
                      activeColor: AppTheme.primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '#$nomor',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  p.inisial,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: roleBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p.role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: roleFg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '@${p.username}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            p.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary(context),
                ),
                onPressed: () => _toast('Detail: ${p.nama}'),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Detail', style: TextStyle(fontSize: 11.5)),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.surfaceMuted(context),
                  foregroundColor: AppTheme.textColor(context),
                ),
                onPressed: () => _toast('Edit: ${p.nama}'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit', style: TextStyle(fontSize: 11.5)),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: _merahBg,
                  foregroundColor: _merah,
                ),
                onPressed: () =>
                    _confirmDelete('${p.nama} (@${p.username})', [p.username]),
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Mode 2: tabel kompak, bisa digeser horizontal ----
  Widget _buildTable(List<_Pengguna> list) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppTheme.surfaceMuted(context),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.swipe,
                  size: 14,
                  color: AppTheme.textSecondary(context),
                ),
                const SizedBox(width: 4),
                Text(
                  'Geser horizontal untuk melihat semua kolom',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppTheme.surfaceMuted(context),
              ),
              headingTextStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.textColor(context),
              ),
              dataRowMinHeight: 56,
              dataRowMaxHeight: 56,
              columnSpacing: 20,
              showCheckboxColumn: false,
              columns: const [
                DataColumn(label: Text('')),
                DataColumn(label: Text('No')),
                DataColumn(label: Text('Nama Lengkap')),
                DataColumn(label: Text('Username')),
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Aksi')),
              ],
              rows: List.generate(list.length, (i) {
                final _Pengguna p = list[i];
                final (Color roleBg, Color roleFg) = _warnaRole(p.role);

                return DataRow(
                  cells: [
                    DataCell(
                      Checkbox(
                        value: _selected.contains(p.username),
                        onChanged: (v) => _toggleSelect(p, v),
                        activeColor: AppTheme.primaryColor,
                      ),
                    ),
                    DataCell(
                      Text(
                        '${(_page - 1) * _perPage + i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            child: Text(
                              p.inisial,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.nama,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textColor(context),
                                ),
                              ),
                              Text(
                                p.email,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        '@${p.username}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: roleBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          p.role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: roleFg,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _toast('Edit ${p.nama}'),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                          ),
                          IconButton(
                            tooltip: 'Hapus',
                            visualDensity: VisualDensity.compact,
                            color: _merah,
                            onPressed: () =>
                                _confirmDelete(p.nama, [p.username]),
                            icon: const Icon(Icons.delete_outline, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Paginasi lokal (3 akun per halaman) ----
  Widget _buildPagination(int total) {
    final int totalHalaman = _totalHalaman(total);
    final int awal = total == 0 ? 0 : (_page - 1) * _perPage + 1;
    final int akhir = _page * _perPage > total ? total : _page * _perPage;

    return Column(
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary(context),
            ),
            children: [
              const TextSpan(text: 'Menampilkan '),
              TextSpan(
                text: total == 0 ? '0' : '$awal-$akhir',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor(context),
                ),
              ),
              const TextSpan(text: ' dari '),
              TextSpan(
                text: '$total',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor(context),
                ),
              ),
              const TextSpan(text: ' total akun'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textColor(context),
                ),
                onPressed: _page > 1 ? () => setState(() => _page--) : null,
                child: const Row(
                  children: [
                    Icon(Icons.chevron_left, size: 18),
                    Text('Sebelumnya', style: TextStyle(fontSize: 11.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textColor(context),
                    ),
                    children: [
                      const TextSpan(text: 'Hal '),
                      TextSpan(
                        text: '$_page',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      TextSpan(text: ' dari $totalHalaman'),
                    ],
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textColor(context),
                ),
                onPressed: _page < totalHalaman
                    ? () => setState(() => _page++)
                    : null,
                child: const Row(
                  children: [
                    Text('Selanjutnya', style: TextStyle(fontSize: 11.5)),
                    Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}