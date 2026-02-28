// lib/core/review/app_review.dart
//
// Conditional export so web builds do not require native in_app_review support.
export 'app_review_stub.dart' if (dart.library.io) 'app_review_io.dart';
