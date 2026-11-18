import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatter input teks untuk memformat angka dengan pemisah ribuan otomatis (standar Indonesia, contoh: 10.000).
class CurrencyInputFormatter extends TextInputFormatter {
  static final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  /// Memformat angka numeric ke format string ribuan (contoh: 10000 -> "10.000").
  static String format(num value) {
    if (value == 0) return '0';
    return _formatter.format(value.toInt());
  }

  /// Membaca string berpemisah ribuan kembali menjadi [double].
  static double parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    String newText = newValue.text;
    int newCursor = newValue.selection.end;

    // Handle backspace saat karakter pemisah (titik/koma) dihapus
    if (oldValue.text.isNotEmpty &&
        newValue.text.length == oldValue.text.length - 1 &&
        oldValue.selection.isCollapsed &&
        oldValue.selection.baseOffset > 0) {
      final deletedIndex = oldValue.selection.baseOffset - 1;
      if (deletedIndex < oldValue.text.length &&
          (oldValue.text[deletedIndex] == '.' ||
              oldValue.text[deletedIndex] == ',')) {
        // Pemisah dihapus via backspace; hapus juga angka di depannya agar tidak stuck
        if (deletedIndex > 0) {
          final before = oldValue.text.substring(0, deletedIndex - 1);
          final after = oldValue.text.substring(deletedIndex + 1);
          newText = before + after;
          newCursor = deletedIndex - 1;
        }
      }
    }

    final clean = newText.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Batasi maksimal 15 digit (ratusan triliun) untuk mencegah overflow
    final safeClean = clean.length > 15 ? clean.substring(0, 15) : clean;
    final number = int.tryParse(safeClean) ?? 0;
    final formatted = _formatter.format(number);

    // Hitung posisi kursor berdasarkan jumlah digit sebelum kursor
    final safeCursor = newCursor.clamp(0, newText.length);
    final textBeforeCursor = newText.substring(0, safeCursor);
    final digitsBeforeCursor =
        textBeforeCursor.replaceAll(RegExp(r'[^0-9]'), '').length;

    int newOffset = 0;
    int digitCount = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(formatted[i])) {
        digitCount++;
      }
      if (digitCount == digitsBeforeCursor) {
        newOffset = i + 1;
        break;
      }
    }

    if (digitsBeforeCursor == 0) {
      newOffset = 0;
    } else if (digitCount < digitsBeforeCursor) {
      newOffset = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newOffset.clamp(0, formatted.length),
      ),
    );
  }
}
