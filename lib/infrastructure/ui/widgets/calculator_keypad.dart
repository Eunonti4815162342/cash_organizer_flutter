import 'package:flutter/material.dart';

/// Evaluates a simple +,-,×,÷ expression string (left-to-right per operator,
/// with × and ÷ resolved before + and -). Returns null on malformed input.
class CalculatorExpression {
  static const operators = ['÷', '×', '-', '+'];

  static bool isOperator(String ch) => operators.contains(ch);

  static double? evaluate(String expr) {
    if (expr.isEmpty) return null;
    var clean = expr;
    while (clean.isNotEmpty && isOperator(clean[clean.length - 1])) {
      clean = clean.substring(0, clean.length - 1);
    }
    if (clean.isEmpty) return null;

    final tokens = _tokenize(clean);
    if (tokens.isEmpty) return null;

    try {
      // Pass 1: resolve × and ÷ left-to-right.
      final pass1 = <String>[tokens.first];
      for (var i = 1; i < tokens.length; i += 2) {
        final op = tokens[i];
        final num = double.parse(tokens[i + 1]);
        if (op == '×' || op == '÷') {
          final prev = double.parse(pass1.removeLast());
          pass1.add((op == '×' ? prev * num : (num == 0 ? prev : prev / num)).toString());
        } else {
          pass1.add(op);
          pass1.add(num.toString());
        }
      }
      // Pass 2: resolve + and - left-to-right.
      double total = double.parse(pass1.first);
      for (var i = 1; i < pass1.length; i += 2) {
        final num = double.parse(pass1[i + 1]);
        total = pass1[i] == '+' ? total + num : total - num;
      }
      return total;
    } catch (_) {
      return null;
    }
  }

  static List<String> _tokenize(String expr) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    for (final ch in expr.split('')) {
      if (isOperator(ch)) {
        tokens.add(buffer.toString());
        buffer.clear();
        tokens.add(ch);
      } else {
        buffer.write(ch);
      }
    }
    tokens.add(buffer.toString());
    return tokens;
  }

  static String formatResult(double value) => value.toStringAsFixed(2);
}

/// Calculator-style keypad for entering a transaction amount, matching the
/// reference app: digits + C/backspace on the left, operators (÷ × − +) and
/// = / confirm stacked on the right.
class CalculatorKeypad extends StatelessWidget {
  final String expression;
  final Color themeColor;
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onConfirm;

  const CalculatorKeypad({
    super.key,
    required this.expression,
    required this.themeColor,
    required this.onKeyPressed,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final opBg = themeColor.withValues(alpha: 0.12);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row([
          _funcKey('C', Colors.grey.shade100, themeColor, flex: 1),
          _iconKey(Icons.backspace_outlined, Colors.grey.shade100, Colors.grey.shade800, 'BACKSPACE', flex: 1),
          _funcKey('÷', opBg, themeColor, flex: 1),
          _funcKey('×', opBg, themeColor, flex: 1),
        ]),
        _row([
          _digitKey('7'), _digitKey('8'), _digitKey('9'),
          _funcKey('-', opBg, themeColor, flex: 1),
        ]),
        _row([
          _digitKey('4'), _digitKey('5'), _digitKey('6'),
          _funcKey('+', opBg, themeColor, flex: 1),
        ]),
        _row([
          _digitKey('1'), _digitKey('2'), _digitKey('3'),
          _funcKey('=', opBg, themeColor, flex: 1),
        ]),
        _row([
          _digitKey('0', flex: 2),
          _digitKey('.'),
          _iconKey(Icons.check, themeColor, Colors.white, 'CONFIRM', flex: 1, onTapOverride: onConfirm),
        ]),
      ],
    );
  }

  Widget _row(List<Widget> children) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: children));

  Widget _key({required Widget child, required Color bg, int flex = 1, VoidCallback? onTapOverride, String? value}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTapOverride ?? () => onKeyPressed(value!),
            child: SizedBox(height: 56, child: Center(child: child)),
          ),
        ),
      ),
    );
  }

  Widget _digitKey(String digit, {int flex = 1}) => _key(
        child: Text(digit, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF16232B))),
        bg: Colors.transparent,
        flex: flex,
        value: digit,
      );

  Widget _funcKey(String label, Color bg, Color fg, {int flex = 1}) => _key(
        child: Text(label, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fg)),
        bg: bg,
        flex: flex,
        value: label,
      );

  Widget _iconKey(IconData icon, Color bg, Color fg, String action, {int flex = 1, VoidCallback? onTapOverride}) => _key(
        child: Icon(icon, color: fg, size: 20),
        bg: bg,
        flex: flex,
        onTapOverride: onTapOverride,
        value: action,
      );
}
