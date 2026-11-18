import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskapp/utils/currency_input_formatter.dart';

void main() {
  group('CurrencyInputFormatter', () {
    final formatter = CurrencyInputFormatter();

    test('format and parse static helpers', () {
      expect(CurrencyInputFormatter.format(0), '0');
      expect(CurrencyInputFormatter.format(500), '500');
      expect(CurrencyInputFormatter.format(1000), '1.000');
      expect(CurrencyInputFormatter.format(15000), '15.000');
      expect(CurrencyInputFormatter.format(1000000), '1.000.000');

      expect(CurrencyInputFormatter.parse(''), 0.0);
      expect(CurrencyInputFormatter.parse('0'), 0.0);
      expect(CurrencyInputFormatter.parse('15.000'), 15000.0);
      expect(CurrencyInputFormatter.parse('1,000,000'), 1000000.0);
      expect(CurrencyInputFormatter.parse('Rp 25.500'), 25500.0);
    });

    test('formatEditUpdate formats numbers as user types', () {
      // Empty input
      var result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: ''),
      );
      expect(result.text, '');
      expect(result.selection.baseOffset, 0);

      // Typing 1
      result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(result.text, '1');
      expect(result.selection.baseOffset, 1);

      // Typing 1000
      result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '100',
          selection: TextSelection.collapsed(offset: 3),
        ),
        const TextEditingValue(
          text: '1000',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(result.text, '1.000');
      expect(result.selection.baseOffset, 5);

      // Typing 50000
      result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '5.000',
          selection: TextSelection.collapsed(offset: 5),
        ),
        const TextEditingValue(
          text: '5.0000',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      expect(result.text, '50.000');
      expect(result.selection.baseOffset, 6);

      // Inserting digit in middle: in '10.000' cursor after '1' (offset 1), user types '5' -> '150.000'
      result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '10.000',
          selection: TextSelection.collapsed(offset: 1),
        ),
        const TextEditingValue(
          text: '150.000',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(result.text, '150.000');
      expect(result.selection.baseOffset, 2);
    });

    test('formatEditUpdate handles backspace correctly', () {
      // Backspace at the end: 1.000 -> 1.00 -> 100
      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '1.000',
          selection: TextSelection.collapsed(offset: 5),
        ),
        const TextEditingValue(
          text: '1.00',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(result.text, '100');
      expect(result.selection.baseOffset, 3);
    });

    test('formatEditUpdate handles backspacing separator', () {
      // In 1.000, cursor is after the dot (offset 2). User hits backspace to delete '.'
      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '1.000',
          selection: TextSelection.collapsed(offset: 2),
        ),
        const TextEditingValue(
          text: '1000',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      // Digit '1' before dot is also deleted, leaving '000' -> '0'
      expect(result.text, '0');
    });
  });
}
