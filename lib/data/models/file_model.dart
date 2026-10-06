import 'dart:math' as math;
import 'package:hive_ce/hive.dart';

part 'file_model.g.dart';

@HiveType(typeId: 0)
class FileModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String url;

  @HiveField(2)
  final int size;

  @HiveField(3)
  final String time;

  @HiveField(4)
  final String category;

  /// Original size string from API (e.g., "4.7 GB")
  @HiveField(5)
  final String sizeFormatted;

  FileModel({
    required this.name,
    required this.url,
    required this.size,
    required this.time,
    required this.category,
    this.sizeFormatted = '',
  });

  /// Parse human-readable size string to bytes
  static int _parseSize(String sizeStr) {
    if (sizeStr.isEmpty) return 0;

    final parts = sizeStr.trim().split(' ');
    if (parts.length != 2) return 0;

    final value = double.tryParse(parts[0]) ?? 0;
    final unit = parts[1].toUpperCase();

    final exponent = switch (unit) {
      'B' || 'BYTES' => 0,
      'KB' => 1,
      'MB' => 2,
      'GB' => 3,
      'TB' => 4,
      _ => -1,
    };

    if (exponent < 0) return 0;
    return (value * math.pow(1024, exponent)).toInt();
  }

  factory FileModel.fromJson(Map<String, dynamic> json) {
    // API returns 'path' not 'url'
    final rawUrl = json['path']?.toString() ?? json['url']?.toString() ?? '';

    // Size is a formatted string like "4.7 GB"
    final rawSize = json['size']?.toString() ?? '';
    final size = _parseSize(rawSize);

    // Decode URL-encoded file name (with fallback for invalid encoding)
    final rawName = json['name']?.toString() ?? 'Unknown';
    String decodedName;
    try {
      decodedName = Uri.decodeComponent(rawName);
    } catch (_) {
      decodedName = rawName;
    }

    return FileModel(
      name: decodedName,
      url: rawUrl,
      size: size,
      time: json['time']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Unknown',
      sizeFormatted: rawSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': url,
      'size': sizeFormatted.isNotEmpty ? sizeFormatted : size.toString(),
      'time': time,
      'category': category,
    };
  }
}
