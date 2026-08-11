class AuthUser {
  const AuthUser({
    required this.id,
    required this.nama,
    this.kodeUser,
    this.nik,
    this.email,
    this.jabatan,
    this.role,
    this.fotoUser,
    this.nohp,
    this.unitkerja,
    this.atasanId,
    this.distrik,
  });

  final dynamic id;
  final String nama;
  final String? kodeUser;
  final String? nik;
  final String? email;
  final String? jabatan;
  final String? role;
  final String? fotoUser;
  final String? nohp;
  final String? unitkerja;
  final dynamic atasanId;
  final String? distrik;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      nama: json['nama']?.toString() ?? 'Petugas Pengawasan',
      kodeUser: json['kode_user']?.toString(),
      nik: json['nik']?.toString(),
      email: json['email']?.toString(),
      jabatan: json['jabatan']?.toString(),
      role: json['role']?.toString(),
      fotoUser: json['foto_user']?.toString(),
      nohp: json['nohp']?.toString(),
      unitkerja: json['unitkerja']?.toString(),
      atasanId: json['atasan_id'],
      distrik: json['distrik']?.toString(),
    );
  }
}
