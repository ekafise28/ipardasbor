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
/// PLACEHOLDER — cek Network tab di web versi "Ubah Password" untuk
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

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

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

  bool get _isPasswordValid => _rulesMet == 6;

  double get _strengthRatio =>
      _passwordController.text.isEmpty ? 0 : _rulesMet / 6;

  Color get _strengthColor {
    if (_passwordController.text.isEmpty) return AppTheme.border(context);
    if (_rulesMet <= 2) return AppTheme.danger;
    if (_rulesMet <= 4) return Colors.orange;
    return Colors.green;
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
    _profileService.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isPasswordValid) {
      _showSnackBar(
        'Password belum memenuhi seluruh persyaratan keamanan.',
        isError: true,
      );
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      _showSnackBar('Konfirmasi password tidak sama.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _profileService.changePassword(
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
      );
      if (!mounted) return;
      _showSnackBar('Password berhasil diubah.');
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
        backgroundColor: isError ? AppTheme.danger : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ubah Password',
          style: TextStyle(
            color: AppTheme.textColor(context),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Simpan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              // Header gradient mirip desain
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppTheme.brandGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UBAH PASSWORD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Gunakan kombinasi password yang kuat untuk menjaga keamanan akun.',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.vpn_key_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password Baru',
                                style: TextStyle(
                                  color: AppTheme.textColor(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Password harus memenuhi seluruh persyaratan keamanan.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: AppTheme.border(context)),
                    const SizedBox(height: 16),

                    // Akun pengguna
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AKUN PENGGUNA',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary(context),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.user.nama,
                                  style: TextStyle(
                                    color: AppTheme.textColor(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Kode: ${widget.user.kodeUser}',
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Password baru
                    _buildFieldLabel('Password Baru', required: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
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
                        if (value == null || value.isEmpty)
                          return 'Password baru wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Kekuatan password
                    Container(
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
                                'Tingkat kekuatan password',
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _strengthRatio,
                              minHeight: 7,
                              backgroundColor: AppTheme.border(context),
                              valueColor: AlwaysStoppedAnimation(
                                _strengthColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildRuleRow(
                            _RuleItem('Minimal 8 karakter', _hasMinLength),
                            _RuleItem('Minimal 1 huruf besar', _hasUppercase),
                          ),
                          const SizedBox(height: 8),
                          _buildRuleRow(
                            _RuleItem('Minimal 1 huruf kecil', _hasLowercase),
                            _RuleItem('Minimal 1 angka', _hasDigit),
                          ),
                          const SizedBox(height: 8),
                          _buildRuleRow(
                            _RuleItem('Minimal 1 simbol', _hasSymbol),
                            _RuleItem('Tidak mengandung spasi', _noSpaces),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Konfirmasi password
                    _buildFieldLabel(
                      'Konfirmasi Password Baru',
                      required: true,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
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
                        if (value == null || value.isEmpty)
                          return 'Konfirmasi password wajib diisi';
                        if (value != _passwordController.text)
                          return 'Password tidak sama';
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Masukkan kembali password yang sama.',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Catatan keamanan
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Gunakan password yang berbeda dari akun lain. '
                              'Jangan membagikan password kepada siapa pun, termasuk petugas atau administrator aplikasi.',
                              style: TextStyle(
                                color: AppTheme.textColor(
                                  context,
                                ).withValues(alpha: 0.85),
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
            ],
          ),
        ),
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

  Widget _buildRuleRow(_RuleItem left, _RuleItem right) {
    return Row(
      children: [
        Expanded(child: _buildRuleChip(left)),
        const SizedBox(width: 10),
        Expanded(child: _buildRuleChip(right)),
      ],
    );
  }

  Widget _buildRuleChip(_RuleItem item) {
    final bool active = item.isMet && _passwordController.text.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? Colors.green.withValues(alpha: 0.5)
              : AppTheme.border(context),
        ),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 15,
            color: active ? Colors.green : AppTheme.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                color: active
                    ? AppTheme.textColor(context)
                    : AppTheme.textSecondary(context),
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
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
