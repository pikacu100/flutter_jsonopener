import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class JsonService {
  static Future<File> _getLocalFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    return File('$path/$filename');
  }

  static Future<void> saveJson(String filename, dynamic jsonData) async {
    final file = await _getLocalFile(filename);
    await file.writeAsString(json.encode(jsonData));
  }

  static Future<dynamic> loadJson(String filename) async {
    try {
      final file = await _getLocalFile(filename);
      if (await file.exists()) {
        final contents = await file.readAsString();
        return json.decode(contents);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteJson(String filename) async {
    try {
      final file = await _getLocalFile(filename);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<dynamic> openJsonFile(File file) async {
    try {
      final contents = await file.readAsString();
      return json.decode(contents);
    } catch (e) {
      throw Exception('Failed to parse JSON: ${e.toString()}');
    }
  }

  static Future<String?> getFileSize(File file) async {
    try {
      final size = await file.length();
      if (size < 1024) {
        return '${size}B';
      } else if (size < 1024 * 1024) {
        return '${(size / 1024).toStringAsFixed(2)}KB';
      } else {
        return '${(size / (1024 * 1024)).toStringAsFixed(2)}MB';
      }
    } catch (e) {
      return null;
    }
  }

   static Future<void> saveJsonToFile(String filePath, dynamic jsonData) async {
    try {
      final file = File(filePath);
      final directory = file.parent;
      
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData),
        mode: FileMode.write,
      );
    } catch (e) {
      throw Exception('Failed to save file: ${e.toString()}');
    }
  }
}
