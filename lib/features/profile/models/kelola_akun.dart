// //Mobile - Model Data Akun Pengguna untuk CRUD Kelola Akun
class KelolaAkunModel {
  final int? id;
  final String kodeUser;
  final String nama;
  final String? nik;
  final String email;
  final String? jabatan;
  final String role;
  final String? fotoUser;
  final String? nohp;
  final String? unitkerja;
  final String? distrik;

  KelolaAkunModel({
    this.id,
    required this.kodeUser,
    required this.nama,
    this.nik,
    required this.email,
    this.jabatan,
    required this.role,
    this.fotoUser,
    this.nohp,
    this.unitkerja,
    this.distrik,
  });

  // //Mobile - Mengubah data JSON dari Laravel API menjadi Objek KelolaAkunModel
  factory KelolaAkunModel.fromJson(Map<String, dynamic> json) {
    return KelolaAkunModel(
      id: json['id'],
      kodeUser: json['kode_user'] ?? '',
      nama: json['nama'] ?? '',
      nik: json['nik'],
      email: json['email'] ?? '',
      jabatan: json['jabatan'],
      role: json['role'] ?? 'Operator',
      fotoUser: json['foto_user'],
      nohp: json['nohp'],
      unitkerja: json['unitkerja'],
      distrik: json['distrik'],
    );
  }

  // //Mobile - Mengubah Objek KelolaAkunModel menjadi Map / JSON untuk dikirim ke Laravel
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kode_user': kodeUser,
      'nama': nama,
      'nik': nik,
      'email': email,
      'jabatan': jabatan,
      'role': role,
      'foto_user': fotoUser,
      'nohp': nohp,
      'unitkerja': unitkerja,
      'distrik': distrik,
    };
  }
}
