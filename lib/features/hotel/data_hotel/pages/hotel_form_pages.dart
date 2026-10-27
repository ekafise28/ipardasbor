import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ipardasbor/app/app_theme.dart';
import 'package:ipardasbor/shared/widgets/detail_cards.dart' show DetailCard;

import '../../../../core/api/api_exception.dart';
import '../models/hotel_item.dart';
import '../services/data_hotel_service.dart';

/// Form tambah/ubah hotel. [item] null = tambah. Untuk ubah, [item] harus
/// data LENGKAP (hasil endpoint detail), bukan baris daftar.
/// Menutup dengan `true` kalau berhasil disimpan.
class HotelFormPage extends StatefulWidget {
  const HotelFormPage({
    super.key,
    required this.service,
    this.item,
    this.provinsiSaran = const <String>[],
  });

  final DataHotelService service;
  final HotelItem? item;
  final List<String> provinsiSaran;

  @override
  State<HotelFormPage> createState() => _HotelFormPageState();
}

class _HotelFormPageState extends State<HotelFormPage> {
  // Urutan sama dengan HotelItem.karyawan (Tetap, PKWT, PKWTT, DW, Casual).
  static const List<String> _jenis = <String>['tetap', 'pkwt', 'pkwtt', 'dw', 'casual'];
  static const List<String> _jenisLabel = <String>['Tetap', 'PKWT', 'PKWTT', 'DW', 'Casual'];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _c = <String, TextEditingController>{};
  final Map<String, String> _errServer = <String, String>{};

  bool _menyimpan = false;
  String? _pesanUmum;

  bool get _edit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final HotelItem? h = widget.item;
    String t(String? v) => v ?? '';
    String n(int? v) => _edit ? '${v ?? 0}' : '';

    final Map<String, String> awal = <String, String>{
      'nama_hotel': t(h?.namaHotel),
      'provinsi': t(h?.provinsi),
      'kab_kota': t(h?.kabKota),
      'alamat': t(h?.alamat),
      'status_hotel': t(h?.statusHotel),
      'kondisi_dan_dampak': t(h?.kondisiDanDampak),
      'pic_email': t(h?.picEmail),
      'pic_whatsapp': t(h?.picWhatsapp),
      'kapasitas_alat_transportasi': t(h?.alatTransportasi),
      'kapasitas_total_kamar': n(h?.kamar),
      'kapasitas_meeting_mice': n(h?.meetingMice),
      'kapasitas_pelayanan_dapur': n(h?.pelayananDapur),
    };
    for (int i = 0; i < _jenis.length; i++) {
      awal['total_karyawan_${_jenis[i]}_sebelumnya'] = n(h?.karyawan[i].sebelumnya);
      awal['total_karyawan_${_jenis[i]}_terdampak'] = n(h?.karyawan[i].terdampak);
    }
    awal.forEach((String k, String v) => _c[k] = TextEditingController(text: v));
  }

  @override
  void dispose() {
    for (final TextEditingController c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  /* ---------- simpan ---------- */

  Map<String, dynamic> _payload() {
    String? s(String k) {
      final String v = _c[k]!.text.trim();
      return v.isEmpty ? null : v;
    }

    int n(String k) => int.tryParse(_c[k]!.text.trim()) ?? 0;

    return <String, dynamic>{
      'nama_hotel': s('nama_hotel'),
      'provinsi': s('provinsi'),
      'kab_kota': s('kab_kota'),
      'alamat': s('alamat'),
      'status_hotel': s('status_hotel'),
      'kondisi_dan_dampak': s('kondisi_dan_dampak'),
      'pic_email': s('pic_email'),
      'pic_whatsapp': s('pic_whatsapp'),
      'kapasitas_alat_transportasi': s('kapasitas_alat_transportasi'),
      'kapasitas_total_kamar': n('kapasitas_total_kamar'),
      'kapasitas_meeting_mice': n('kapasitas_meeting_mice'),
      'kapasitas_pelayanan_dapur': n('kapasitas_pelayanan_dapur'),
      for (final String j in _jenis) ...<String, dynamic>{
        'total_karyawan_${j}_sebelumnya': n('total_karyawan_${j}_sebelumnya'),
        'total_karyawan_${j}_terdampak': n('total_karyawan_${j}_terdampak'),
      },
    };
  }

  Map<String, String> _galatField(Map<String, dynamic>? errors) {
    final Map<String, String> hasil = <String, String>{};
    errors?.forEach((String k, dynamic v) {
      if (!_c.containsKey(k)) return;
      hasil[k] = v is List && v.isNotEmpty ? '${v.first}' : '$v';
    });
    return hasil;
  }

  Future<void> _simpan() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _pesanUmum = null;
      _errServer.clear();
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _menyimpan = true);
    try {
      final Map<String, dynamic> data = _payload();
      if (_edit) {
        await widget.service.update(widget.item!.id, data);
      } else {
        await widget.service.create(data);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _pesanUmum = e.message;
        _errServer.addAll(_galatField(e.errors));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _pesanUmum = 'Data gagal disimpan. Silakan coba lagi.';
      });
    }
  }

  Future<void> _pilihProvinsi() async {
    final String? p = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              for (final String p in widget.provinsiSaran)
                ListTile(title: Text(p), onTap: () => Navigator.of(ctx).pop(p)),
            ],
          ),
        ),
      ),
    );
    if (p == null) return;
    _c['provinsi']!.text = p;
    setState(() => _errServer.remove('provinsi'));
  }

  /* ---------- kolom ---------- */

  Widget _teks(
    String key,
    String label, {
    bool wajib = false,
    int maxLines = 1,
    TextInputType? tipe,
    String? hint,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c[key],
        keyboardType: tipe,
        maxLines: maxLines,
        textInputAction:
            maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        decoration: InputDecoration(
          labelText: wajib ? '$label *' : label,
          hintText: hint,
          suffixIcon: suffix,
          errorText: _errServer[key],
          alignLabelWithHint: maxLines > 1,
        ),
        onChanged: (_) {
          if (_errServer.containsKey(key)) {
            setState(() => _errServer.remove(key));
          }
        },
        validator: (String? v) {
          if (wajib && (v == null || v.trim().isEmpty)) {
            return '$label wajib diisi.';
          }
          return validator?.call(v);
        },
      ),
    );
  }

  Widget _angka(String key, String label) {
    return TextFormField(
      controller: _c[key],
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
        errorText: _errServer[key],
      ),
      onChanged: (_) {
        if (_errServer.containsKey(key)) {
          setState(() => _errServer.remove(key));
        }
      },
      validator: (String? v) =>
          (v != null && v.length > 9) ? 'Angka terlalu besar.' : null,
    );
  }

  Widget _seksi(IconData icon, String judul, List<Widget> isi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DetailCard(
        icon: icon,
        title: judul,
        child: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(children: isi),
        ),
      ),
    );
  }

  String? _cekEmail(String? v) {
    final String e = (v ?? '').trim();
    if (e.isEmpty) return null;
    return (e.contains('@') && e.contains('.')) ? null : 'Format email tidak valid.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldColorDynamic(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        title: Text(_edit ? 'Ubah Data Hotel' : 'Tambah Data Hotel'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_pesanUmum != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _pesanUmum!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.danger,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: _menyimpan ? null : _simpan,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: _menyimpan
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(_menyimpan ? 'Menyimpan...' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
      body: Theme(
        data: AppTheme.formTheme(context),
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              _seksi(Icons.hotel_outlined, 'Identitas Hotel', <Widget>[
                _teks('nama_hotel', 'Nama hotel', wajib: true),
                _teks(
                  'provinsi',
                  'Provinsi',
                  wajib: true,
                  suffix: widget.provinsiSaran.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Pilih dari daftar',
                          icon: const Icon(Icons.arrow_drop_down_rounded),
                          onPressed: _pilihProvinsi,
                        ),
                ),
                _teks('kab_kota', 'Kabupaten/Kota', wajib: true),
                _teks('status_hotel', 'Status hotel'),
                _teks('alamat', 'Alamat', maxLines: 3, tipe: TextInputType.multiline),
                _teks(
                  'kondisi_dan_dampak',
                  'Kondisi dan dampak',
                  maxLines: 4,
                  tipe: TextInputType.multiline,
                ),
              ]),
              _seksi(Icons.groups_2_outlined, 'Karyawan', <Widget>[
                for (int i = 0; i < _jenis.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: _angka(
                            'total_karyawan_${_jenis[i]}_sebelumnya',
                            '${_jenisLabel[i]} sebelumnya',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _angka(
                            'total_karyawan_${_jenis[i]}_terdampak',
                            '${_jenisLabel[i]} terdampak',
                          ),
                        ),
                      ],
                    ),
                  ),
              ]),
              _seksi(Icons.apartment_outlined, 'Kapasitas', <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: _angka('kapasitas_total_kamar', 'Total kamar')),
                      const SizedBox(width: 10),
                      Expanded(child: _angka('kapasitas_meeting_mice', 'Meeting / MICE')),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _angka('kapasitas_pelayanan_dapur', 'Pelayanan dapur'),
                ),
                _teks('kapasitas_alat_transportasi', 'Alat transportasi', maxLines: 2),
              ]),
              _seksi(Icons.contact_phone_outlined, 'Kontak PIC', <Widget>[
                _teks('pic_email', 'Email', tipe: TextInputType.emailAddress, validator: _cekEmail),
                _teks('pic_whatsapp', 'WhatsApp', tipe: TextInputType.phone),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}