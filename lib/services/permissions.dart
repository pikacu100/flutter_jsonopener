import 'package:permission_handler/permission_handler.dart';

Future<bool> storagePermission() async {
  final status = await Permission.storage.status;
  
  if (!status.isGranted) {
    final result = await Permission.storage.request();
    return result.isGranted || result.isLimited;
  }
  
  return true;
}