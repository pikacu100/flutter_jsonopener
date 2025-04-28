import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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

  static Future<String> saveJsonFile(String fileName, dynamic jsonData) async {
    try {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          throw Exception(
              'Storage permission denied. Please grant permissions in app settings.');
        }
      }

      String? selectedDirectory;

      try {
        String? directoryPath = await FilePicker.platform.getDirectoryPath();
        if (directoryPath != null) {
          selectedDirectory = directoryPath;
        }
      } catch (e) {
        print('Directory picker not supported: ${e.toString()}');
      }

      if (selectedDirectory == null) {
        Directory directory;
        if (Platform.isAndroid) {
          if (await Permission.manageExternalStorage.isGranted) {
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          } else {
            directory = await getExternalStorageDirectory() ??
                await getApplicationDocumentsDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
        selectedDirectory = directory.path;
      }

      if (!fileName.endsWith('.json')) {
        fileName = '$fileName.json';
      }

      final file = File('$selectedDirectory/$fileName');

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData),
      );

      return file.path;
    } catch (e) {
      throw Exception('Failed to save file: ${e.toString()}');
    }
  }

  static Future<String> saveToSpecificPath(
      String path, dynamic jsonData) async {
    try {
      final file = File(path);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(jsonData),
      );
      return file.path;
    } catch (e) {
      throw Exception('Failed to save file: ${e.toString()}');
    }
  }
}
