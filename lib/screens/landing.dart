import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:json_opener/screens/editor.dart';
import 'package:json_opener/screens/viewer.dart';
import 'package:json_opener/services/json_service.dart';
import 'package:json_opener/style/theme.dart';

class LandingPage extends StatefulWidget {
  final String? initialFileUri;
  const LandingPage({super.key, this.initialFileUri});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  dynamic _jsonData;
  bool _isLoading = false;
  String? _currentFileName;
  String? _fileSize;
  File? _currentFile;

  @override
  void initState() {
    super.initState();
    _handleInitialFile();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final data = {
      'example': {
        'key': 'value',
        'array': [1, 2, 3],
        'nested': {'item': 'data'}
      }
    };
    setState(() {
      _jsonData = data;
      _isLoading = false;
    });
  }

  Future<void> _handleInitialFile() async {
    print('Initial file URI: ${widget.initialFileUri}');
    if (widget.initialFileUri != null) {
      try {
        final file = File(widget.initialFileUri!);
        if (await file.exists()) {
          await _openFileFromUri(file);
        } else {
          print('File does not exist at path: ${file.path}');
        }
      } catch (e) {
        print('Error opening initial file: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening file: ${e.toString()}')),
          );
        }
      }
    } else {
      print('No initial file URI provided.');
    }
  }

  Future<void> _openFileFromUri(File file) async {
    setState(() => _isLoading = true);
    try {
      final data = await JsonService.openJsonFile(file);
      final size = await JsonService.getFileSize(file);

      setState(() {
        _jsonData = data;
        _currentFileName = file.path.split('/').last;
        _fileSize = size;
        _currentFile = file;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _openFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);

        final file = File(result.files.single.path!);
        final data = await JsonService.openJsonFile(file);
        final size = await JsonService.getFileSize(file);

        setState(() {
          _jsonData = data;
          _currentFileName = result.files.single.name;
          _fileSize = size;
          _currentFile = file;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _editJson() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JsonEditorScreen(
          initialJson: const JsonEncoder.withIndent('  ').convert(_jsonData),
          currentFile: _currentFile,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (result is Map &&
            result.containsKey('data') &&
            result.containsKey('file')) {
          _jsonData = result['data'];
          _currentFile = result['file'];
          _currentFileName = _currentFile!.path.split('/').last;
          _updateFileSize();
        } else {
          _jsonData = result;
          if (_currentFile != null) {
            _updateFileSize();
          }
        }
      });
    }
  }

  Future<void> _updateFileSize() async {
    if (_currentFile != null) {
      _fileSize = await JsonService.getFileSize(_currentFile!);
      setState(() {});
    }
  }

  Future<void> _closeJson() async {
    setState(() {
      _jsonData = null;
      _currentFileName = null;
      _fileSize = null;
      _currentFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        titleTextStyle: StylesForText().appBarStyle(isDarkMode),
        actions: [
          IconButton(
            icon: Icon(Icons.folder_open,
                color: isDarkMode ? Colors.white : Colors.grey.shade900),
            onPressed: _openFile,
            tooltip: 'Open JSON file',
          ),
          if (_jsonData != null)
            IconButton(
              icon: Icon(Icons.edit,
                  color: isDarkMode ? Colors.white : Colors.grey.shade900),
              onPressed: _editJson,
              tooltip: 'Edit JSON',
            ),
          if (_jsonData != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: _closeJson,
              tooltip: 'Close',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
            ))
          : _jsonData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No JSON file loaded',
                        style: StylesForText().bodyTextStyle(isDarkMode),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _openFile,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor:
                              isDarkMode ? Colors.grey[900] : Colors.grey[300],
                          foregroundColor:
                              isDarkMode ? Colors.white : Colors.black,
                        ),
                        child: const Text('Open JSON File'),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => _loadInitialData(),
                        child: Text(
                          'Load Example',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey.shade700
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_currentFileName != null || _fileSize != null)
                      Container(
                        color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              if (_currentFileName != null)
                                Text(
                                  'File: $_currentFileName',
                                  style: StylesForText()
                                      .bodyTextStyle(isDarkMode)
                                      .copyWith(fontSize: 14),
                                ),
                              const SizedBox(width: 20),
                              if (_fileSize != null)
                                Text(
                                  'Size: $_fileSize',
                                  style: StylesForText()
                                      .bodyTextStyle(isDarkMode)
                                      .copyWith(fontSize: 14),
                                ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: JsonViewerScreen(jsonData: _jsonData),
                    ),
                  ],
                ),
    );
  }
}
