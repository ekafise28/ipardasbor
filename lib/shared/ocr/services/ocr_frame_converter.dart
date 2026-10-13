import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Mengubah frame stream kamera menjadi [InputImage] untuk ML Kit.
///
/// Dipisah dari layar kamera karena ini bagian yang paling bergantung pada
/// platform (format piksel dan rotasi sensor). Kalau kotak/teks live
/// terbaca miring atau kosong di perangkat tertentu, periksa [_rotation]
/// lebih dulu.
class OcrFrameConverter {
  OcrFrameConverter._();

  /// Format stream yang diminta dari kamera. ML Kit di Android butuh NV21,
  /// di iOS BGRA8888.
  static ImageFormatGroup get streamFormat =>
      Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888;

  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// Null kalau frame tidak bisa dipakai (format tidak didukung atau
  /// rotasi tidak diketahui). Pemanggil menganggap deteksi live tidak
  /// tersedia kalau ini terjadi terus-menerus.
  static InputImage? convert(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    final InputImageRotation? rotation = _rotation(camera, deviceOrientation);
    if (rotation == null) return null;

    final InputImageFormat? format = InputImageFormatValue.fromRawValue(
      image.format.raw as int,
    );
    if (format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    if (image.planes.length != 1) return null;

    final Plane plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  static InputImageRotation? _rotation(
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    final int sensor = camera.sensorOrientation;
    if (Platform.isIOS) return InputImageRotationValue.fromRawValue(sensor);

    int? compensation = _orientations[deviceOrientation];
    if (compensation == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {
      compensation = (sensor + compensation) % 360;
    } else {
      compensation = (sensor - compensation + 360) % 360;
    }
    return InputImageRotationValue.fromRawValue(compensation);
  }
}