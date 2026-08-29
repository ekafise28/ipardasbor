import 'package:flutter/material.dart';

class BarSeries {
  final String name;
  final Color color;
  final List<double> values;

  const BarSeries({
    required this.name,
    required this.color,
    required this.values,
  });
}

class ChartSeriesData {
  final List<String> labels;
  final List<BarSeries> series;

  const ChartSeriesData({required this.labels, required this.series});

  static List<double> _numList(dynamic value) {
    if (value is! List) return <double>[];
    return value.map((e) {
      if (e is num) return e.toDouble();
      if (e == null) return 0.0;
      return double.tryParse(e.toString()) ?? 0.0;
    }).toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return <String>[];
    return value.map((e) => e.toString()).toList();
  }

  factory ChartSeriesData.fromDynamic(
    dynamic json, {
    required List<MapEntry<String, Color>> seriesConfig,
    Map<String, String>? seriesLabelOverride,
  }) {
    if (json is! Map) {
      return const ChartSeriesData(labels: [], series: []);
    }

    final labels = _stringList(json['labels']);

    final series = seriesConfig.map((entry) {
      return BarSeries(
        name: seriesLabelOverride?[entry.key] ?? entry.key,
        color: entry.value,
        values: _numList(json[entry.key]),
      );
    }).toList();

    return ChartSeriesData(labels: labels, series: series);
  }
}
