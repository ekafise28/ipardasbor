import 'package:flutter/material.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/utils/formatters.dart';
import 'package:ipardasbor/shared/widgets/detail_cards.dart'
    show Baris, DetailCard, KotakBaris, SectionCard;
import 'package:ipardasbor/shared/widgets/list_parts.dart';

import '../models/hotel_item.dart';
import '../services/data_hotel_service.dart';

typedef HotelFooterBuilder =
    Widget Function(BuildContext context, HotelItem item, bool lengkap);

/// Detail satu hotel. [footer] diisi halaman (mis. tombol Ubah/Hapus Admin).
Future<void> showHotelDetailSheet(
  BuildContext context, {
  required HotelItem item,
  required DataHotelService service,
  HotelFooterBuilder? footerBuilder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController controller) =>
          _DetailIsi(
            item: item,
            service: service,
            controller: controller,
            footerBuilder: footerBuilder,
          ),
    ),
  );
}

class _DetailIsi extends StatefulWidget {
  const _DetailIsi({
    required this.item,
    required this.service,
    required this.controller,
    this.footerBuilder,
  });

  final HotelItem item;
  final DataHotelService service;
  final ScrollController controller;
  final HotelFooterBuilder? footerBuilder;

  @override
  State<_DetailIsi> createState() => _DetailIsiState();
}

class _DetailIsiState extends State<_DetailIsi> {
  late HotelItem _item = widget.item;
  bool _memuat = true;
  bool _gagal = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _gagal = false;
    });
    try {
      final HotelItem lengkap = await widget.service.detail(widget.item.id);
      if (!mounted) return;
      setState(() {
        _item = lengkap;
        _memuat = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memuat = false;
        _gagal = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final HotelItem h = _item;
    final bool lengkap = !_memuat && !_gagal;
    String? hanyaLengkap(String? v) => lengkap ? v : null;

    return ListView(
      controller: widget.controller,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: <Widget>[
        Text(
          h.namaHotel,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            height: 1.25,
            color: AppTheme.textColor(context),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            if (h.statusHotel != null)
              TintChip(label: h.statusHotel!, color: AppTheme.secondaryColor),
            TintChip(
              label: '${h.kabKota}, ${h.provinsi}',
              color: AppTheme.primaryColor,
            ),
          ],
        ),
        if (_memuat)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_gagal)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Detail lengkap gagal dimuat.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ),
                TextButton(onPressed: _muat, child: const Text('Coba lagi')),
              ],
            ),
          ),
        const SizedBox(height: 14),
        _TabelKaryawan(item: h),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.apartment_outlined,
          title: 'Kapasitas',
          rows: <Baris>[
            Baris('Total kamar', formatNumber(h.kamar)),
            Baris('Meeting / MICE', formatNumber(h.meetingMice)),
            Baris(
              'Pelayanan dapur',
              lengkap ? formatNumber(h.pelayananDapur) : null,
            ),
            Baris('Alat transportasi', hanyaLengkap(h.alatTransportasi)),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.info_outline_rounded,
          title: 'Informasi',
          rows: <Baris>[
            Baris('Alamat', hanyaLengkap(h.alamat), kotak: KotakBaris.netral),
            Baris(
              'Kondisi dan dampak',
              hanyaLengkap(h.kondisiDanDampak),
              kotak: KotakBaris.peringatan,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.contact_phone_outlined,
          title: 'Kontak PIC',
          rows: <Baris>[
            Baris('Email', hanyaLengkap(h.picEmail), salin: true),
            Baris.telepon('WhatsApp', hanyaLengkap(h.picWhatsapp)),
          ],
        ),
        if (widget.footerBuilder != null) ...<Widget>[
          const SizedBox(height: 16),
          widget.footerBuilder!(context, h, lengkap),
        ],
      ],
    );
  }
}

/// Rincian karyawan per jenis: jumlah sebelumnya dan yang terdampak.
class _TabelKaryawan extends StatelessWidget {
  const _TabelKaryawan({required this.item});

  final HotelItem item;

  Widget _sel(
    BuildContext context,
    String teks, {
    bool kepala = false,
    bool kanan = true,
    Color? warna,
    bool tebal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        teks,
        textAlign: kanan ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          fontSize: kepala ? 11.5 : 13.5,
          fontWeight: (kepala || tebal) ? FontWeight.w800 : FontWeight.w600,
          letterSpacing: kepala ? 0.4 : 0,
          color:
              warna ??
              (kepala
                  ? AppTheme.textSecondary(context)
                  : AppTheme.textColor(context)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BorderSide garis = BorderSide(color: AppTheme.border(context));

    return DetailCard(
      icon: Icons.groups_2_outlined,
      title: 'Karyawan',
      child: Table(
        columnWidths: const <int, TableColumnWidth>{
          0: FlexColumnWidth(1.3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        children: <TableRow>[
          TableRow(
            children: <Widget>[
              _sel(context, 'JENIS', kepala: true, kanan: false),
              _sel(context, 'SEBELUMNYA', kepala: true),
              _sel(context, 'TERDAMPAK', kepala: true),
            ],
          ),
          for (final HotelKaryawan k in item.karyawan)
            TableRow(
              decoration: BoxDecoration(border: Border(top: garis)),
              children: <Widget>[
                _sel(context, k.label, kanan: false),
                _sel(context, formatNumber(k.sebelumnya)),
                _sel(
                  context,
                  formatNumber(k.terdampak),
                  warna: k.terdampak > 0 ? AppTheme.danger : null,
                ),
              ],
            ),
          TableRow(
            decoration: BoxDecoration(border: Border(top: garis)),
            children: <Widget>[
              _sel(context, 'Total', kanan: false, tebal: true),
              _sel(context, formatNumber(item.totalKaryawan), tebal: true),
              _sel(
                context,
                formatNumber(item.totalTerdampak),
                tebal: true,
                warna: item.totalTerdampak > 0 ? AppTheme.danger : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
