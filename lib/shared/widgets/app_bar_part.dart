import 'package:flutter/material.dart';

/// Judul AppBar dua baris: judul tebal dan keterangan kecil di bawahnya.
class TwoLineTitle extends StatelessWidget {
  const TwoLineTitle({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

/// Tombol filter di AppBar dengan lencana jumlah filter aktif. Lencana
/// disembunyikan saat [activeCount] nol. Warna ikon mengikuti
/// foregroundColor AppBar.
class FilterAction extends StatelessWidget {
  const FilterAction({
    super.key,
    required this.onPressed,
    this.activeCount = 0,
  });

  final VoidCallback onPressed;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: activeCount > 0 ? 'Filter ($activeCount aktif)' : 'Filter',
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: activeCount > 0,
        label: Text('$activeCount'),
        backgroundColor: Colors.amberAccent,
        textColor: Colors.black87,
        child: const Icon(Icons.filter_list_rounded),
      ),
    );
  }
}