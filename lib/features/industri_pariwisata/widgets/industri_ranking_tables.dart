// Seksi "Peringkat Usaha": 4 tabel Top 20 (Jenis Usaha, KBLI, Provinsi,
// Kabupaten/Kota). Padanan blok executive-table di index.blade.php.
//
// Tiap tabel punya status sendiri (memuat / berhasil / gagal), jadi yang
// lambat atau gagal tidak menahan tabel lain dan bisa dicoba lagi sendiri.

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../shared/widgets/skeleton.dart';
import '../industri_format.dart';
import '../models/industri_ranking.dart';
import 'industri_charts.dart' show IndustriSectionTitle;

enum IndustriRankingStatus { loading, success, error }

/// Keadaan satu tabel peringkat. Awalnya "memuat".
class IndustriRankingState {
  const IndustriRankingState({
    this.status = IndustriRankingStatus.loading,
    this.rows = const <IndustriRankingRow>[],
  });

  final IndustriRankingStatus status;
  final List<IndustriRankingRow> rows;
}

class IndustriRankingSectionView extends StatelessWidget {
  const IndustriRankingSectionView({
    super.key,
    required this.states,
    required this.onRetry,
  });

  final Map<IndustriRankingSection, IndustriRankingState> states;

  /// Dipanggil saat tombol "Coba lagi" ditekan di salah satu tabel.
  final ValueChanged<IndustriRankingSection> onRetry;

  static const List<
    ({
      IndustriRankingSection section,
      String kicker,
      String title,
      String header,
    })
  >
  _configs = [
    (
      section: IndustriRankingSection.pariwisata,
      kicker: 'Kategori',
      title: 'Jenis Usaha Pariwisata',
      header: 'Jenis Usaha',
    ),
    (
      section: IndustriRankingSection.kbli,
      kicker: 'Klasifikasi',
      title: 'Kode KBLI',
      header: 'KBLI dan Judul',
    ),
    (
      section: IndustriRankingSection.provinsi,
      kicker: 'Wilayah',
      title: 'Provinsi',
      header: 'Provinsi',
    ),
    (
      section: IndustriRankingSection.kota,
      kicker: 'Wilayah',
      title: 'Kabupaten/Kota',
      header: 'Kabupaten/Kota',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const IndustriSectionTitle(
          title: 'Peringkat Usaha',
          subtitle:
              '20 kategori dengan jumlah usaha terbesar berdasarkan filter aktif.',
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < _configs.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 14),
          _RankingCard(
            section: _configs[i].section,
            kicker: _configs[i].kicker,
            title: _configs[i].title,
            header: _configs[i].header,
            state: states[_configs[i].section] ?? const IndustriRankingState(),
            onRetry: () => onRetry(_configs[i].section),
          ),
        ],
      ],
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({
    required this.section,
    required this.kicker,
    required this.title,
    required this.header,
    required this.state,
    required this.onRetry,
  });

  final IndustriRankingSection section;
  final String kicker;
  final String title;
  final String header;
  final IndustriRankingState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D17243A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      kicker.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textColor(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'Top 20',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (state.status) {
      case IndustriRankingStatus.loading:
        return _buildLoading();
      case IndustriRankingStatus.error:
        return _buildMessage(
          context,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Data gagal dimuat.',
                style: TextStyle(color: AppTheme.danger, fontSize: 12),
              ),
              TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
            ],
          ),
        );
      case IndustriRankingStatus.success:
        if (state.rows.isEmpty) {
          return _buildMessage(
            context,
            child: Text(
              'Tidak ada data untuk filter ini.',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
              ),
            ),
          );
        }
        return _buildTable(context);
    }
  }

  Widget _buildLoading() {
    return const SkeletonShimmer(
      child: Column(
        children: <Widget>[
          SkeletonBox(height: 34, radius: 10),
          SizedBox(height: 8),
          SkeletonBox(height: 34, radius: 10),
          SizedBox(height: 8),
          SkeletonBox(height: 34, radius: 10),
          SizedBox(height: 8),
          SkeletonBox(height: 34, radius: 10),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildTable(BuildContext context) {
    final Color border = AppTheme.border(context);
    final TextStyle styleHeader = TextStyle(
      color: AppTheme.textSecondary(context),
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              color: AppTheme.surfaceMuted(context),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: <Widget>[
                  SizedBox(width: 34, child: Text('#', style: styleHeader)),
                  Expanded(
                    child: Text(header.toUpperCase(), style: styleHeader),
                  ),
                  Text('TOTAL', style: styleHeader),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < state.rows.length; i++)
                      _buildRow(context, i, state.rows[i], border),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    int index,
    IndustriRankingRow row,
    Color border,
  ) {
    final bool adaKode =
        section == IndustriRankingSection.kbli && row.code != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        border: index == state.rows.length - 1
            ? null
            : Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted(context),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: adaKode
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        row.code!,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        row.label,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.textColor(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : Text(
                    row.label,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textColor(context),
                      fontSize: 12,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Text(
            formatAngka(row.total),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
