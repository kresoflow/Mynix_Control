import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class BarcodeScannerListener extends StatefulWidget {
  final Widget child;
  final void Function(String barcode) onBarcodeScanned;
  final Duration timeout;

  const BarcodeScannerListener({
    super.key,
    required this.child,
    required this.onBarcodeScanned,
    this.timeout = const Duration(milliseconds: 200),
  });

  @override
  State<BarcodeScannerListener> createState() => _BarcodeScannerListenerState();
}

class _BarcodeScannerListenerState extends State<BarcodeScannerListener> {
  final FocusNode _focusNode = FocusNode();
  final StringBuffer _buffer = StringBuffer();
  Timer? _timer;

  @override
  void dispose() {
    _focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _resetBuffer() {
    _buffer.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            final barcode = _buffer.toString().trim();
            if (barcode.isNotEmpty) {
              widget.onBarcodeScanned(barcode);
            }
            _resetBuffer();
            return KeyEventResult.handled;
          } else if (event.character != null && event.character!.isNotEmpty) {
            _buffer.write(event.character);
            
            // Timeout to clear buffer if typing is too slow (not a scanner)
            _timer?.cancel();
            _timer = Timer(widget.timeout, () {
              _resetBuffer();
            });
            
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}
