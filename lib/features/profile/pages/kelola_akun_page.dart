import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ipardasbor/features/profile/models/kelola_akun.dart';

import '../../../app/app_theme.dart';
import '../../../core/api/api_exception.dart';
// import '../models/kelola_akun.dart';
import '../services/profile_service.dart';

class KelolaAkunPage extends StatefulWidget {
  const KelolaAkunPage({super.key});

  @override
  State<KelolaAkunPage> createState() => _KelolaAkunPageState();
}

class _KelolaAkunPageState extends State<KelolaAkunPage> {
  static const List<String> _filters = [
    'Semua',
    'Admin',
    'Operator',
    'Dinas',
    'Industri',
  ];

  final ProfileService _profileService = ProfileService();
  final Set<String> _selected = <String>{};
  final TextEditingController _searchCtrl = TextEditingController();

  List<KelolaAkunModel> _data = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _filter = 'Semua';
  String _query = '';

  // Paginasi lokal: 5 akun per halaman.
  static const int _perPage = 25;
  int _page = 1;

  static const Color _merah = Color(0xFFC62828);
  static const Color _merahBg = Color(0x1FC62828);

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _profileService.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _profileService.getKelolaAkunList();
      setState(() {
        _data = users;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data akun: $e';
        _isLoading = false;
      });
    }
  }

  List<KelolaAkunModel> get _filtered {
    final String q = _query.trim().toLowerCase();
    return _data.where((p) {
      final bool cocokRole =
          _filter == 'Semua' || p.role.toLowerCase() == _filter.toLowerCase();
      final bool cocokCari =
          q.isEmpty ||
          p.nama.toLowerCase().contains(q) ||
          p.kodeUser.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q) ||
          p.role.toLowerCase().contains(q);
      return cocokRole && cocokCari;
    }).toList();
  }

  int _countFor(String filter) {
    if (filter == 'Semua') return _data.length;
    return _data
        .where((p) => p.role.toLowerCase() == filter.toLowerCase())
        .length;
  }

  int _totalHalaman(int total) {
    return total == 0 ? 1 : (total / _perPage).ceil();
  }

  (Color, Color) _warnaRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return (AppTheme.primaryColor, Colors.white);
      case 'operator':
      case 'editor':
        return (const Color(0x33F59E0B), const Color(0xFFB45309));
      default:
        return (
          AppTheme.surfaceMuted(context),
          AppTheme.textSecondary(context),
        );
    }
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: isError ? _merah : const Color(0xFF238636),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  void _toggleSelect(KelolaAkunModel p, bool? value) {
    setState(() {
      if (value == true) {
        _selected.add(p.kodeUser);
      } else {
        _selected.remove(p.kodeUser);
      }
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      for (final KelolaAkunModel p in _filtered) {
        if (value == true) {
          _selected.add(p.kodeUser);
        } else {
          _selected.remove(p.kodeUser);
        }
      }
    });
  }

  Future<void> _confirmDelete(String title, List<String> kodeUsers) async {
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

    try {
      for (final kode in kodeUsers) {
        await _profileService.deleteKelolaAkun(kode);
      }
      _toast('Data berhasil dihapus');
      _selected.removeAll(kodeUsers);
      _fetchUsers();
    } on ApiException catch (e) {
      _toast(e.message, isError: true);
    } catch (e) {
      _toast('Gagal menghapus data', isError: true);
    }
  }

  String _buatKodeUser() {
    final DateTime now = DateTime.now();
    final String tanggal =
        '${(now.year % 100).toString().padLeft(2, '0')}'
        '${(now.month.toString().padLeft(2, '0'))}'
        '${(now.day.toString().padLeft(2, '0'))}';
    const String karakter = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random acak = Random.secure();
    final String unik = List.generate(
      6,
      (_) => karakter[acak.nextInt(karakter.length)],
    ).join();
    return 'USR-$tanggal-$unik';
  }

  void _showFormModal({KelolaAkunModel? user}) {
    final isEdit = user != null;
    final formKey = GlobalKey<FormState>();

    final kodeCtrl = TextEditingController(
      text: user?.kodeUser ?? _buatKodeUser(),
    );
    final namaCtrl = TextEditingController(text: user?.nama ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passCtrl = TextEditingController();
    final jabatanCtrl = TextEditingController(text: user?.jabatan ?? '');
    final nohpCtrl = TextEditingController(text: user?.nohp ?? '');
    String selectedRole = user?.role ?? 'Operator';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Akun Pengguna' : 'Tambah Akun Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColor(modalCtx),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: kodeCtrl,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Kode User',
                          helperText: isEdit
                              ? null
                              : 'Dibuat otomatis setelah disimpan',
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: namaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: isEdit
                              ? 'Password (Kosongkan jika tidak diubah)'
                              : 'Password',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (!isEdit && (v == null || v.isEmpty)) {
                            return 'Wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(
                          labelText: 'Role / Peran',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Admin', 'Operator', 'Dinas', 'Industri']
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null)
                            setModalState(() => selectedRole = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: jabatanCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Jabatan (Opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nohpCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'No. HP (Opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final payload = {
                                'kode_user': kodeCtrl.text,
                                'nama': namaCtrl.text,
                                'email': emailCtrl.text,
                                'role': selectedRole,
                                if (passCtrl.text.isNotEmpty)
                                  'password': passCtrl.text,
                                if (jabatanCtrl.text.isNotEmpty)
                                  'jabatan': jabatanCtrl.text,
                                if (nohpCtrl.text.isNotEmpty)
                                  'nohp': nohpCtrl.text,
                              };

                              Navigator.pop(modalCtx);

                              try {
                                if (isEdit) {
                                  await _profileService.updateKelolaAkun(
                                    user.kodeUser,
                                    payload,
                                  );
                                  _toast('Akun berhasil diperbarui');
                                } else {
                                  await _profileService.createKelolaAkun(
                                    payload,
                                  );
                                  _toast('Akun berhasil ditambahkan');
                                }
                                _fetchUsers();
                              } on ApiException catch (e) {
                                _toast(e.message, isError: true);
                              } catch (e) {
                                _toast('Gagal menyimpan data', isError: true);
                              }
                            }
                          },
                          child: Text(
                            isEdit ? 'Simpan Perubahan' : 'Tambah Akun',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<KelolaAkunModel> list = _filtered;
    final int totalHalaman = _totalHalaman(list.length);
    if (_page > totalHalaman) _page = totalHalaman;
    final List<KelolaAkunModel> halaman = list
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!, style: const TextStyle(color: _merah)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _fetchUsers,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              child: Column(
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
                        else
                          ...List.generate(
                            halaman.length,
                            (i) => _buildCard(
                              halaman[i],
                              (_page - 1) * _perPage + i + 1,
                            ),
                          ),
                        const SizedBox(height: 16),
                        _buildPagination(list.length),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormModal(),
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
            style: TextStyle(fontSize: 13, color: AppTheme.textColor(context)),
            decoration: InputDecoration(
              hintText: 'Cari nama, kode user, atau role...',
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

  Widget _buildBulkBar(List<KelolaAkunModel> list) {
    final int dipilih = _selected.length;
    final bool semuaDipilih =
        list.isNotEmpty && list.every((p) => _selected.contains(p.kodeUser));

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

  Widget _buildCard(KelolaAkunModel p, int nomor) {
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
                      value: _selected.contains(p.kodeUser),
                      onChanged: (v) => _toggleSelect(p, v),
                      activeColor: AppTheme.primaryColor,
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
                  p.nama.isNotEmpty ? p.nama[0].toUpperCase() : 'U',
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
                          '@${p.kodeUser}',
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
                  backgroundColor: AppTheme.surfaceMuted(context),
                  foregroundColor: AppTheme.textColor(context),
                ),
                onPressed: () => _showFormModal(user: p),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit', style: TextStyle(fontSize: 11.5)),
              ),
              const SizedBox(width: 4),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: _merahBg,
                  foregroundColor: _merah,
                ),
                onPressed: () =>
                    _confirmDelete('${p.nama} (@${p.kodeUser})', [p.kodeUser]),
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(int total) {
    final int totalHalaman = _totalHalaman(total);
    final int awal = total == 0 ? 0 : (_page - 1) * _perPage + 1;
    final int akhir = _page * _perPage > total ? total : _page * _perPage;

    return Column(
      children: [
        Text('Menampilkan $awal-$akhir dari $total akun'),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: _page > 1 ? () => setState(() => _page--) : null,
              child: const Text('Sebelumnya'),
            ),
            Text(' Hal $_page dari $totalHalaman '),
            TextButton(
              onPressed: _page < totalHalaman
                  ? () => setState(() => _page++)
                  : null,
              child: const Text('Selanjutnya'),
            ),
          ],
        ),
      ],
    );
  }
}
