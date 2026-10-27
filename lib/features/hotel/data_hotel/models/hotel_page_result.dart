import 'hotel_item.dart';

class HotelPagination {
  const HotelPagination({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.hasNextPage,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final bool hasNextPage;

  factory HotelPagination.fromJson(Map<String, dynamic> j) => HotelPagination(
    currentPage: (j['current_page'] as num?)?.toInt() ?? 1,
    perPage: (j['per_page'] as num?)?.toInt() ?? 10,
    total: (j['total'] as num?)?.toInt() ?? 0,
    lastPage: (j['last_page'] as num?)?.toInt() ?? 1,
    hasNextPage: j['has_next_page'] == true,
  );
}

/// Satu batang grafik: jumlah hotel per provinsi.
class HotelChartPoint {
  const HotelChartPoint(this.label, this.value);
  final String label;
  final int value;
}

class HotelPageResult {
  const HotelPageResult({
    required this.items,
    required this.pagination,
    required this.chart,
  });

  final List<HotelItem> items;
  final HotelPagination pagination;
  final List<HotelChartPoint> chart;

  factory HotelPageResult.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> daftar(dynamic v) => (v as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList();

    return HotelPageResult(
      items: daftar(j['items']).map(HotelItem.fromJson).toList(),
      pagination: HotelPagination.fromJson(
        (j['pagination'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      chart: daftar(j['chart'])
          .map((Map<String, dynamic> e) => HotelChartPoint(
                '${e['label'] ?? ''}',
                (e['value'] as num?)?.toInt() ?? 0,
              ))
          .toList(),
    );
  }
}