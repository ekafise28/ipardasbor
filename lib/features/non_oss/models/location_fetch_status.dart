enum LocationFetchStatus {
  memintaIzin,
  mencariSinyalGps,
  memakaiLokasiTersimpanTanpaInternet,
  memakaiLokasiTersimpanSinyalLemah,
  berhasil,
  gagalTanpaCadangan,
}

/// Sumber koordinat yang berhasil didapat, dipakai untuk menampilkan
/// keterangan permanen di bawah koordinat (bukan cuma status sementara
/// selagi loading).
enum LocationSource {
  gpsLangsung,
  tersimpanTanpaInternet,
  tersimpanSinyalLemah,
}