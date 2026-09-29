import 'package:flutter/material.dart';
import 'package:ipardasbor/features/notifications/services/notification_local_service.dart';

import '../../../app/app_theme.dart';
import 'models/notification_item.dart';
import 'services/notification_category_preferences.dart';
import 'services/notification_retention_controller.dart';
import 'services/notification_service.dart';
import 'services/notification_statusbar_controller.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  static const Map<int, String> _retentionOptions = {
    7: '1 Minggu',
    14: '2 Minggu',
    30: '1 Bulan',
  };

  static const Map<NotificationType, (String, String)> _categoryLabels = {
    NotificationType.syncFailed: ('Gagal Sinkronisasi', 'Data gagal terkirim ke server'),
    NotificationType.syncSuccess: ('Sinkronisasi Berhasil', 'Ringkasan data yang berhasil terkirim'),
    NotificationType.waitingTooLong: ('Data Menunggu Lama', 'Data belum terkirim lebih dari 24 jam'),
    NotificationType.draftLingering: ('Draft Menggantung', 'Draft belum dilanjutkan lebih dari 3 hari'),
  };

  Future<void> _hapusSemua() async {
    final bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus semua notifikasi?', textAlign: TextAlign.center),
        content: const Text(
          'Seluruh notifikasi di perangkat ini akan dihapus permanen.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      await NotificationService.instance.deleteAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua notifikasi telah dihapus.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _SectionLabel('Masa Simpan'),
          const SizedBox(height: 10),
          ValueListenableBuilder<int>(
            valueListenable: NotificationRetentionController.instance,
            builder: (context, days, _) => _Tile(
              icon: Icons.auto_delete_outlined,
              title: 'Simpan Notifikasi Selama',
              subtitle: _retentionOptions[days] ?? '1 Bulan',
              trailing: DropdownButton<int>(
                value: _retentionOptions.containsKey(days) ? days : 30,
                underline: const SizedBox.shrink(),
                items: _retentionOptions.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) NotificationRetentionController.instance.setDays(v);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Notifikasi di Status Bar'),
          const SizedBox(height: 10),
          ValueListenableBuilder<bool>(
            valueListenable: NotificationStatusBarController.instance,
            builder: (context, enabled, _) => _Tile(
              icon: enabled ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
              title: 'Tampilkan di Status Bar HP',
              subtitle: enabled
                  ? 'Aktif - izin akan diminta saat dibutuhkan'
                  : 'Nonaktif - notifikasi hanya tampil di dalam aplikasi',
              trailing: Switch(
                value: enabled,
                activeTrackColor: AppTheme.menuTampilan,
                onChanged: (v) async {
                  if (v) {
                    final bool diizinkan =
                        await NotificationLocalService.instance.requestPermission();
                    if (!diizinkan) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Izin notifikasi ditolak. Aktifkan lewat pengaturan sistem HP.',
                            ),
                          ),
                        );
                      }
                      return;
                    }
                  } else {
                    await NotificationLocalService.instance.cancelWaitingTooLongReminder();
                    await NotificationLocalService.instance.cancelDraftLingeringReminder();
                  }
                  await NotificationStatusBarController.instance.setEnabled(v);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Jenis Notifikasi'),
          const SizedBox(height: 10),
          ValueListenableBuilder<Set<NotificationType>>(
            valueListenable: NotificationCategoryPreferences.instance,
            builder: (context, disabled, _) => Column(
              children: _categoryLabels.entries.map((entry) {
                final bool enabled = !disabled.contains(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _Tile(
                    icon: Icons.circle_notifications_outlined,
                    title: entry.value.$1,
                    subtitle: entry.value.$2,
                    trailing: Switch(
                      value: enabled,
                      activeTrackColor: AppTheme.menuTampilan,
                      onChanged: (v) =>
                          NotificationCategoryPreferences.instance.setEnabled(entry.key, v),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _hapusSemua,
              icon: Icon(Icons.delete_sweep_outlined, color: AppTheme.danger),
              label: Text('Hapus Semua Notifikasi', style: TextStyle(color: AppTheme.danger)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.trailing});

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary(context)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppTheme.textColor(context), fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11.5)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.2),
    );
  }
}