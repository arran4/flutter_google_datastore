import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HexEditor extends StatefulWidget {
  final Uint8List? data;
  final Function(Uint8List?) onSave;

  const HexEditor({Key? key, this.data, required this.onSave}) : super(key: key);

  @override
  State<HexEditor> createState() => _HexEditorState();
}

class _HexEditorState extends State<HexEditor> {
  late TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _bytesToHex(widget.data));
  }

  String _bytesToHex(Uint8List? bytes) {
    if (bytes == null) return "";
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i++) {
      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0').toUpperCase());
      if (i < bytes.length - 1) {
        buffer.write(" ");
      }
    }
    return buffer.toString();
  }

  Uint8List? _hexToBytes(String hex) {
    hex = hex.replaceAll(RegExp(r'\s+'), ''); // Remove spaces
    if (hex.isEmpty) return Uint8List(0);
    if (hex.length % 2 != 0) {
      throw FormatException("Hex string must have an even length");
    }
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      String byteString = hex.substring(i, i + 2);
      int? byte = int.tryParse(byteString, radix: 16);
      if (byte == null) {
        throw FormatException("Invalid hex character");
      }
      bytes.add(byte);
    }
    return Uint8List.fromList(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Hex Editor"),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'Courier'),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: "00 01 02 ...",
                  errorText: _error,
                ),
                onChanged: (_) {
                  if (_error != null) {
                    setState(() {
                      _error = null;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            try {
              Uint8List? data = _hexToBytes(_controller.text);
              widget.onSave(data);
              Navigator.of(context).pop();
            } catch (e) {
              setState(() {
                _error = e.toString();
              });
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
