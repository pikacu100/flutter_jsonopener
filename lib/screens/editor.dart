import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_opener/services/json_service.dart';
import 'package:json_opener/style/theme.dart';
import 'package:path_provider/path_provider.dart';

class JsonEditorScreen extends StatefulWidget {
  final String initialJson;
  final File? currentFile;

  const JsonEditorScreen({
    super.key,
    required this.initialJson,
    this.currentFile,
  });

  @override
  State<JsonEditorScreen> createState() => _JsonEditorScreenState();
}

class _JsonEditorScreenState extends State<JsonEditorScreen> {
  late TextEditingController _controller;
  bool _isValidJson = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialJson);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _validateJson() {
    try {
      json.decode(_controller.text);
      setState(() => _isValidJson = true);
    } catch (e) {
      setState(() => _isValidJson = false);
    }
  }

  Future<void> _saveFile() async {
  if (!_isValidJson) return;

  try {
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save JSON File',
      fileName: widget.currentFile?.path.split('/').last ?? 'new_file.json',
      allowedExtensions: ['json'],
      type: FileType.custom,
      lockParentWindow: true,
    );

    if (outputPath != null) {
      if (!outputPath.endsWith('.json')) {
        outputPath = '$outputPath.json';
      }

      String finalPath = outputPath;
      if (Platform.isAndroid && outputPath.startsWith('/')) {
        finalPath = outputPath;
      } else if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        finalPath = '${directory?.path}/$outputPath';
      }

      await JsonService.saveJsonToFile(
        finalPath,
        json.decode(_controller.text),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File saved successfully')),
      );

      if (mounted) {
        Navigator.pop(context, json.decode(_controller.text));
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving file: ${e.toString()}')),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isValidJson ? _saveFile : null,
            tooltip: 'Save Options',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isValidJson
                ? () => Navigator.pop(context, json.decode(_controller.text))
                : null,
            tooltip: 'Apply Changes',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            scrollController: _scrollController,
            scrollPhysics: const ClampingScrollPhysics(),
            keyboardType: TextInputType.multiline,
            style: StylesForText().bodyTextStyle(isDarkMode).copyWith(
                  fontFamily: 'monospace',
                  fontSize: 16,
                ),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: _isValidJson ? null : 'Invalid JSON',
              filled: true,
              fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (text) => _validateJson(),
          ),
        ),
      ),
    );
  }
}
