import 'package:flutter/material.dart';

/// Ditampilkan saat tidak ada ajuan yang menunggu sinkronisasi.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.check_circle_rounded, color: Colors.green),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Semua data sudah tersinkronisasi.',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}