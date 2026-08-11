class RegionOption {
  const RegionOption({required this.id, required this.name});

  final int id;
  final String name;

  factory RegionOption.fromJson(Map<String, dynamic> json) => RegionOption(
    id: int.parse(json['id'].toString()),
    name: json['nama']?.toString() ?? '-',
  );
}
