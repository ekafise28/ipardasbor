import 'package:flutter/material.dart';

import '../models/menu_data.dart';

class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({super.key, required this.menu});

  final MenuData menu;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          menu.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: menu.backgroundColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(menu.icon, size: 48, color: menu.color),
              ),
              const SizedBox(height: 24),
              Text(
                menu.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF17243A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${menu.description}. Fitur ini akan kita kembangkan '
                'pada tahap berikutnya.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF748197),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Kembali ke Menu Utama'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
