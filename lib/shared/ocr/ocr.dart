/// Titik masuk fitur OCR untuk kode di luar `shared/ocr/`.
///
/// Halaman form cukup `import 'package:ipardasbor/shared/ocr/ocr.dart';`.
/// File di dalam `shared/ocr/` sendiri tetap mengimpor satu sama lain
/// langsung (bukan lewat file ini) supaya tidak melingkar.
library;

// Alur yang dipanggil dari form.
export 'flows/ocr_paste_flow.dart' show runPaste;
export 'flows/ocr_scan_flow.dart' show runOcrScan;

// Tipe yang dipakai pemanggil untuk menentukan target dan membaca hasil.
export 'models/ocr_field_type.dart';
export 'models/ocr_result.dart';

// Widget siap pakai untuk field form.
export 'widgets/ocr_field_actions.dart';
export 'widgets/ocr_scan_button.dart';
export 'widgets/ocr_result_sheet.dart' show OcrSheetResult, showOcrResultSheet;

export 'parsing/ocr_paste_cleaner.dart' show OcrPasteCleaner;