import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_opener/screens/landing.dart';
import 'package:json_opener/style/theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
const platform = MethodChannel('app.channel.shared.data');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.delayed(const Duration(milliseconds: 100));
  String? initialFileUri;
  try {
    initialFileUri = await platform.invokeMethod<String>('getSharedData');
  } on PlatformException catch (e) {
    print("Failed to get shared data: '${e.message}'.");
  } catch (e) {
    print("Error initializing app: $e");
  }

  runApp(
    MainApp(
      initialFileUri: initialFileUri,
    ),
  );
}

class MainApp extends StatefulWidget {
  final String? initialFileUri;
  const MainApp({super.key, this.initialFileUri});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  ThemeMode _themeMode = ThemeMode.system;
  String? _fileUri;
  @override
  void initState() {
    super.initState();
    _setupFileChannel();
  }

  void _setupFileChannel() {
    platform.setMethodCallHandler((call) async {
      if (call.method == "onFileOpened") {
        print('File opened event received: ${call.arguments}');
        setState(() {
          _fileUri = call.arguments;
        });
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      home: LandingPage(initialFileUri: widget.initialFileUri ?? _fileUri),
      routes: {},
    );
  }
}
