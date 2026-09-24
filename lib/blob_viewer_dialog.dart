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
  bool _isEditing = false;
  late TextEditingController _textController;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    try {
      bytes = base64Decode(widget.blobValue);
    } catch (e) {
      bytes = Uint8List(0);
    }
    _textController = TextEditingController();
    _hexController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
      if (_selectedView == 0) {
        // Text
        try {
          _textController.text = utf8.decode(bytes);
        } catch (e) {
          _textController.text = ""; // Or show error?
        }
      } else if (_selectedView == 2) {
        // Hex
        _hexController.text = bytes
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(' ');
      }
    });
  }

  void _saveChanges() {
    if (_isEditing) {
      try {
        if (_selectedView == 0) {
          bytes = Uint8List.fromList(utf8.encode(_textController.text));
        } else if (_selectedView == 2) {
          String cleanHex = _hexController.text.replaceAll(RegExp(r'\s+'), '');
          if (cleanHex.length % 2 != 0) {
            // Handle odd length? pad with 0? or error?
            // For now, let's just ignore the last char if odd, or error.
            // A common behavior is to error or pad.
            // Let's assume the user knows what they are doing, but if not, we try our best.
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Invalid Hex String")));
            return;
          }
          List<int> newBytes = [];
          for (int i = 0; i < cleanHex.length; i += 2) {
            newBytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
          }
          bytes = Uint8List.fromList(newBytes);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving changes: $e")));
        return;
      }
      setState(() {
        _isEditing = false;
      });
    }
    Navigator.of(context).pop(base64Encode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Blob Content"),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(value: 0, label: Text('Text')),
                ButtonSegment<int>(value: 1, label: Text('Image')),
                ButtonSegment<int>(value: 2, label: Text('Hex')),
              ],
              selected: <int>{_selectedView},
              onSelectionChanged: _isEditing
                  ? null
                  : (Set<int> newSelection) {
                      setState(() {
                        _selectedView = newSelection.first;
                      });
                    },
            ),
            const SizedBox(height: 16),
            Flexible(child: _buildContent()),
          ],
        ),
      ),
      actions: [
        if (_isEditing) ...[
          TextButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
              });
            },
            child: const Text("Cancel"),
          ),
          FilledButton(onPressed: _saveChanges, child: const Text("Save")),
        ] else ...[
          TextButton(onPressed: _downloadFile, child: const Text("Download")),
          if (_selectedView == 0 || _selectedView == 2)
            TextButton(onPressed: _enterEditMode, child: const Text("Edit")),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ],
    );
  }

  Widget _buildContent() {
    if (bytes.isEmpty && !_isEditing) {
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
    if (_isEditing) {
      return TextField(
        controller: _textController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      );
    }
    try {
      String text = utf8.decode(bytes);
      return SingleChildScrollView(child: SelectableText(text));
    } catch (e) {
      return const Center(child: Text("Content is not valid UTF-8 text."));
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
    if (_isEditing) {
      return TextField(
        controller: _hexController,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: const TextStyle(fontFamily: 'Courier'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: "Enter hex bytes (e.g. 00 A1 FF)",
        ),
      );
    }
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
    String? filePath = await FilePicker.saveFile(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to $filePath')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
      }
    }
  }
}
