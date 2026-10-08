import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/api/api_exception.dart';
import '../../authentication/models/auth_user.dart';
import '../services/profile_services.dart';

/// Halaman untuk mengubah password akun.
///
/// CATATAN INTEGRASI:
/// Endpoint pasti (URL, method, nama field payload) belum dikonfirmasi ke
/// backend Laravel. Path `ApiEndpoints.changePassword` di bawah ini masih
/// PLACEHOLDER - cek Network tab di web versi "Ubah Password" untuk
/// mendapatkan URL & payload yang sebenarnya, lalu sesuaikan:
///  1. Tambahkan konstanta path yang benar di `api_endpoints.dart`
///  2. Sesuaikan nama field body di `ProfileService.changePassword`
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.user});

  /// Data user yang sedang login, dipakai untuk menampilkan kotak
  /// "Akun Pengguna" seperti pada desain.
  final AuthUser user;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  static const int _maxPasswordLength = 32;

  // Aturan kekuatan password.
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasDigit => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSymbol => RegExp(
    r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\];]',
  ).hasMatch(_passwordController.text);
  bool get _noSpaces =>
      _passwordController.text.isNotEmpty &&
      !_passwordController.text.contains(' ');

  int get _rulesMet => [
    _hasMinLength,
    _hasUppercase,
    _hasLowercase,
    _hasDigit,
    _hasSymbol,
    _noSpaces,
  ].where((rule) => rule).length;

  List<_RuleItem> get _rules => [
    _RuleItem('8-32 karakter', _hasMinLength),
    _RuleItem('1 huruf besar', _hasUppercase),
    _RuleItem('1 huruf kecil', _hasLowercase),
    _RuleItem('1 angka', _hasDigit),
    _RuleItem('1 simbol', _hasSymbol),
    _RuleItem('Tanpa spasi', _noSpaces),
  ];

  bool get _isPasswordValid => _rulesMet == 6;

  bool get _confirmMatches =>
      _confirmController.text.isNotEmpty &&
      _confirmController.text == _passwordController.text;

  bool get _canSubmit => _isPasswordValid && _confirmMatches && !_isSubmitting;

  String? get _submitHint {
    if (_isSubmitting || _canSubmit) return null;
    if (_passwordController.text.isEmpty) return null;
    if (!_isPasswordValid) return 'Lengkapi semua persyaratan password.';
    if (!_confirmMatches) return 'Konfirmasi password belum sama.';
    return null;
  }

  double get _strengthRatio =>
      _passwordController.text.isEmpty ? 0 : _rulesMet / 6;

  Color get _strengthColor {
    if (_passwordController.text.isEmpty) return AppTheme.border(context);
    if (_rulesMet <= 2) return AppTheme.danger;
    if (_rulesMet <= 4) return AppTheme.warning;
    return AppTheme.success;
  }

  String get _strengthLabel {
    if (_passwordController.text.isEmpty) return 'Belum diisi';
    if (_rulesMet <= 2) return 'Lemah';
    if (_rulesMet <= 4) return 'Sedang';
    return 'Kuat';
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _profileService.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      !_isSubmitting &&
      (_passwordController.text.isNotEmpty ||
          _confirmController.text.isNotEmpty);

  Future<void> _confirmDiscard() async {
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface(context),
          surfaceTintColor: AppTheme.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Batalkan perubahan?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textColor(context),
            ),
          ),
          content: Text(
            'Password yang sudah Anda isi tidak akan disimpan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppTheme.textSecondary(context),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textColor(context),
                      side: BorderSide(color: AppTheme.border(context)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Lanjut mengisi'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Keluar'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (discard == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _profileService.changePassword(
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Kalau server balas error validasi per-field (422), tampilkan pesan
      // paling spesifik yang tersedia; kalau tidak, pakai e.message.
      String? fieldError;
      final Map<String, dynamic>? errors = e.errors;
      if (errors != null && errors.isNotEmpty) {
        final dynamic firstValue = errors.values.first;
        fieldError = firstValue is List && firstValue.isNotEmpty
            ? firstValue.first.toString()
            : firstValue.toString();
      }
      _showSnackBar(fieldError ?? e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Gagal mengubah password. Silakan coba lagi.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      ),
    );
  }

  Widget _buildStrengthBox() {
    final bool empty = _passwordController.text.isEmpty;
    final List<_RuleItem> unmet = _rules
        .where((_RuleItem r) => !r.isMet)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kekuatan password',
                style: TextStyle(
                  color: AppTheme.textColor(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _strengthLabel,
                style: TextStyle(
                  color: _strengthColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (int i = 0; i < 6; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    height: 6,
                    margin: EdgeInsets.only(right: i == 5 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: (!empty && i < _rulesMet)
                          ? _strengthColor
                          : AppTheme.border(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!empty && unmet.isEmpty)
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppTheme.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'Semua persyaratan terpenuhi',
                  style: TextStyle(
                    color: AppTheme.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: unmet.map(_buildRuleChip).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRuleChip(_RuleItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle_outlined, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 5),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchIndicator() {
    if (_confirmController.text.isEmpty) {
      return Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(
            'Masukkan kembali password yang sama.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11.5),
          ),
        ],
      );
    }

    final bool match = _confirmMatches;
    final Color color = match ? AppTheme.success : AppTheme.danger;

    return Row(
      children: [
        Icon(
          match ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          match ? 'Password cocok' : 'Password belum sama',
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _confirmDiscard();
      },
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldColorDynamic(context),
        appBar: AppBar(
          backgroundColor: AppTheme.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text(
            'Ubah Password',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            border: Border(top: BorderSide(color: AppTheme.border(context))),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_submitHint != null) ...[
                  Text(
                    _submitHint!,
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _canSubmit ? _submit : null,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 20,
                          ),
                    label: Text(
                      _isSubmitting ? 'Menyimpan...' : 'Simpan Password',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  // Keterangan singkat (pengganti header gradient)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                    child: Text(
                      'Gunakan kombinasi password yang kuat untuk menjaga keamanan akun.',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),

                  // Kartu utama
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAccountTile(),
                        const SizedBox(height: 18),

                        // Password baru
                        _buildFieldLabel('Password Baru', required: true),
                        const SizedBox(height: 6),
                        TextFormField(
                          focusNode: _passwordFocus,
                          autofocus: true,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            LengthLimitingTextInputFormatter(_maxPasswordLength),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Masukkan password baru',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: AppTheme.textMuted,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password baru wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Kekuatan password
                        _buildStrengthBox(),
                        const SizedBox(height: 18),

                        // Konfirmasi password
                        _buildFieldLabel(
                          'Konfirmasi Password Baru',
                          required: true,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          focusNode: _confirmFocus,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) {
                            if (_canSubmit) _submit();
                          },
                          controller: _confirmController,
                          obscureText: _obscureConfirm,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s')),LengthLimitingTextInputFormatter(_maxPasswordLength),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Masukkan kembali password baru',
                            prefixIcon: const Icon(
                              Icons.verified_user_outlined,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: AppTheme.textMuted,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Konfirmasi password wajib diisi';
                            }
                            if (value != _passwordController.text) {
                              return 'Password tidak sama';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        _buildMatchIndicator(),
                      ],
                    ),
                  ),

                  // Catatan keamanan (di luar kartu)
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 15,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gunakan password yang berbeda dari akun lain. Jangan '
                            'membagikan password kepada siapa pun, termasuk petugas '
                            'atau administrator aplikasi.',
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _initials {
    final List<String> parts = widget.user.nama
        .trim()
        .split(RegExp(r'\s+'))
        .where((String s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  Widget _buildAccountTile() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              _initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textColor(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Kode: ${widget.user.kodeUser}',
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
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: AppTheme.textColor(context),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppTheme.danger),
            ),
        ],
      ),
    );
  }
}

class _RuleItem {
  const _RuleItem(this.label, this.isMet);
  final String label;
  final bool isMet;
}
