import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;

class ReaderSettingsModal extends StatefulWidget {
  final double initialFontSize;
  final double initialLineHeight;
  final double initialLetterSpacing;
  final Function(double, double, double) onSettingsChanged;

  const ReaderSettingsModal({
    super.key,
    required this.initialFontSize,
    required this.initialLineHeight,
    required this.initialLetterSpacing,
    required this.onSettingsChanged,
  });

  @override
  State<ReaderSettingsModal> createState() => _ReaderSettingsModalState();
}

class _ReaderSettingsModalState extends State<ReaderSettingsModal> {
  late double _fontSize;
  late double _lineHeight;
  late double _letterSpacing;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.initialFontSize;
    _lineHeight = widget.initialLineHeight;
    _letterSpacing = widget.initialLetterSpacing;
  }

  void _notifyChange() {
    widget.onSettingsChanged(_fontSize, _lineHeight, _letterSpacing);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 20),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const Text(
                'Personalización de Lectura',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildSliderRow(
                label: 'Tamaño de letra',
                value: _fontSize,
                min: 12.0,
                max: 32.0,
                onChanged: (val) => setState(() {
                  _fontSize = val;
                  _notifyChange();
                }),
                displayValue: '${_fontSize.toInt()} px',
              ),
              const Divider(height: 32, color: CupertinoColors.separator),
              _buildSliderRow(
                label: 'Interlineado',
                value: _lineHeight,
                min: 1.0,
                max: 2.5,
                onChanged: (val) => setState(() {
                  _lineHeight = val;
                  _notifyChange();
                }),
                displayValue: _lineHeight.toStringAsFixed(1),
              ),
              const Divider(height: 32, color: CupertinoColors.separator),
              _buildSliderRow(
                label: 'Espaciado',
                value: _letterSpacing,
                min: -1.0,
                max: 2.0,
                onChanged: (val) => setState(() {
                  _letterSpacing = val;
                  _notifyChange();
                }),
                displayValue: _letterSpacing.toStringAsFixed(1),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String displayValue,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: CupertinoColors.label,
              ),
            ),
            Text(
              displayValue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: CupertinoSlider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
