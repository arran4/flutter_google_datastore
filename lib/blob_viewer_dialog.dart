import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class BlobViewerDialog extends StatefulWidget {
  final String blobValue;

  const BlobViewerDialog(this.blobValue, {super.key});

  @override
  State<BlobViewerDialog> createState() => _BlobViewerDialogState();
}

class _BlobViewerDialogState extends State<BlobViewerDialog> {
  late Uint8List bytes;
  int _selectedView = 0; // 0: Text, 1: Image, 2: Hex

  @override
  void initState() {
    super.initState();
    try {
      bytes = base64Decode(widget.blobValue);
    } catch (e) {
      bytes = Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Blob Content"),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ToggleButtons(
                  isSelected: [
                    _selectedView == 0,
                    _selectedView == 1,
                    _selectedView == 2
                  ],
                  onPressed: (int index) {
                    setState(() {
                      _selectedView = index;
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("Text"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("Image"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text("Hex"),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _downloadFile,
          child: const Text("Download"),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Close"),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (bytes.isEmpty) {
      return const Center(child: Text("Empty or Invalid Blob Data"));
    }

    switch (_selectedView) {
      case 0:
        return _buildTextView();
      case 1:
        return _buildImageView();
      case 2:
        return _buildHexView();
      default:
        return const SizedBox();
    }
  }

  Widget _buildTextView() {
    try {
      String text = utf8.decode(bytes);
      return SingleChildScrollView(
        child: SelectableText(text),
      );
    } catch (e) {
      return const Center(
        child: Text("Content is not valid UTF-8 text."),
      );
    }
  }

  Widget _buildImageView() {
    return Center(
      child: Image.memory(
        bytes,
        errorBuilder: (context, error, stackTrace) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text("Content is not a valid image."),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHexView() {
    return SingleChildScrollView(
      child: SelectableText(
        _formatHex(bytes),
        style: const TextStyle(fontFamily: 'Courier'),
      ),
    );
  }

  String _formatHex(Uint8List bytes) {
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i += 16) {
      // Offset
      buffer.write(i.toRadixString(16).padLeft(8, '0'));
      buffer.write("  ");

      // Hex bytes
      for (int j = 0; j < 16; j++) {
        if (i + j < bytes.length) {
          buffer.write(bytes[i + j].toRadixString(16).padLeft(2, '0'));
          buffer.write(" ");
        } else {
          buffer.write("   ");
        }
        if (j == 7) buffer.write(" ");
      }

      buffer.write(" |");

      // ASCII representation
      for (int j = 0; j < 16; j++) {
        if (i + j < bytes.length) {
          int byte = bytes[i + j];
          if (byte >= 32 && byte <= 126) {
            buffer.writeCharCode(byte);
          } else {
            buffer.write(".");
          }
        }
      }
      buffer.write("|\n");
    }
    return buffer.toString();
  }

  Future<void> _downloadFile() async {
    String? filePath = await FilePicker.platform.saveFile(
      dialogTitle: "Save Blob",
      fileName: "blob.bin",
    );

    if (filePath == null) {
      return;
    }

    try {
      File file = File(filePath);
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving file: $e')),
        );
      }
    }
  }
}
