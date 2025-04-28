import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:json_opener/services/json_service.dart';
import 'package:json_opener/style/theme.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _hasChanges = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialJson);
    _controller.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _controller.removeListener(_checkForChanges);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    setState(() {
      _hasChanges = _controller.text != widget.initialJson;
    });
    _validateJson();
  }

  void _validateJson() {
    try {
      json.decode(_controller.text);
      setState(() => _isValidJson = true);
    } catch (e) {
      setState(() => _isValidJson = false);
    }
  }

  Future<void> _showSaveOptions() async {
    if (!_isValidJson) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix JSON errors before saving')),
      );
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text('Save Options'),
        content: const Text('How would you like to save this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save_as'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );

    if (choice == 'save_as') {
      await _saveAsNewFile();
    }
  }

  Future<void> _saveAsNewFile() async {
    try {
      final jsonData = json.decode(_controller.text);

      final fileName = await _showSaveDialog();
      if (fileName == null) return;

      String safeName =
          fileName.endsWith('.json') ? fileName : '$fileName.json';

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select save location...')));

      try {
        final savedPath = await JsonService.saveJsonFile(safeName, jsonData);

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to: $savedPath'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
            duration: const Duration(seconds: 5),
          ),
        );

        if (mounted) {
          Navigator.pop(context, {
            'data': jsonData,
            'file': File(savedPath),
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () async {
                await openAppSettings();
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid JSON: ${e.toString()}')),
      );
    }
  }

  Future<String?> _showSaveDialog() async {
    final TextEditingController controller = TextEditingController(
        text:
            widget.currentFile?.path.split('/').last.replaceAll('.json', '') ??
                'data');

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save JSON File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
              labelText: 'Filename',
              hintText: 'Enter filename (without extension)',
              suffixText: '.json'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    final shouldDiscard = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Unsaved Changes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Discard',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );

    if (shouldDiscard == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          await _confirmDiscard();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(widget.currentFile?.path.split('/').last ?? 'JSON Editor'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.save,
                  color: isDarkMode
                      ? _hasChanges
                          ? Colors.white
                          : Colors.grey.shade700
                      : _hasChanges
                          ? Colors.grey.shade900
                          : Colors.grey.shade400),
              onPressed: _hasChanges ? _showSaveOptions : null,
              tooltip: 'Save Options',
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.red,
              ),
              onPressed: () => _confirmDiscard(),
              tooltip: 'Close',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (!_isValidJson)
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red[900],
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text('Invalid JSON',
                          style: TextStyle(color: Colors.white)),
                      const Spacer(),
                      if (_hasChanges)
                        const Text(
                          'Unsaved changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
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
                      border: InputBorder.none,
                      filled: true,
                      fillColor:
                          isDarkMode ? Colors.grey[900] : Colors.grey[100],
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
