import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_opener/style/theme.dart';

class JsonViewerScreen extends StatelessWidget {
  final dynamic jsonData;

  const JsonViewerScreen({super.key, required this.jsonData});

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

    return Scaffold(
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                jsonString,
                style: StylesForText().bodyTextStyle(isDarkMode).copyWith(
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Clipboard.setData(ClipboardData(text: jsonString));
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')));
        },
        backgroundColor:
            isDarkMode ? Colors.grey.shade900 : Colors.grey.shade300,
        child: Icon(
          Icons.copy,
          color: isDarkMode ? Colors.white : Colors.grey.shade900,
        ),
      ),
    );
  }
}
