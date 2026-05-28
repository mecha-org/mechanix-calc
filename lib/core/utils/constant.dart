import 'package:calculator/features/calculator/bloc/calculator_event.dart';
import 'package:flutter/services.dart';

final Map<LogicalKeyboardKey, CalculatorEvent> logicalKeyboardKeyMap = {
  LogicalKeyboardKey.digit0: const NumberPressed('0'),
  LogicalKeyboardKey.numpad0: const NumberPressed('0'),
  LogicalKeyboardKey.digit1: const NumberPressed('1'),
  LogicalKeyboardKey.numpad1: const NumberPressed('1'),
  LogicalKeyboardKey.digit2: const NumberPressed('2'),
  LogicalKeyboardKey.numpad2: const NumberPressed('2'),
  LogicalKeyboardKey.digit3: const NumberPressed('3'),
  LogicalKeyboardKey.numpad3: const NumberPressed('3'),
  LogicalKeyboardKey.digit4: const NumberPressed('4'),
  LogicalKeyboardKey.numpad4: const NumberPressed('4'),
  LogicalKeyboardKey.digit5: const NumberPressed('5'),
  LogicalKeyboardKey.numpad5: const NumberPressed('5'),
  LogicalKeyboardKey.digit6: const NumberPressed('6'),
  LogicalKeyboardKey.numpad6: const NumberPressed('6'),
  LogicalKeyboardKey.digit7: const NumberPressed('7'),
  LogicalKeyboardKey.numpad7: const NumberPressed('7'),
  LogicalKeyboardKey.digit8: const NumberPressed('8'),
  LogicalKeyboardKey.numpad8: const NumberPressed('8'),
  LogicalKeyboardKey.digit9: const NumberPressed('9'),
  LogicalKeyboardKey.numpad9: const NumberPressed('9'),

  LogicalKeyboardKey.period: const NumberPressed('.'),
  LogicalKeyboardKey.numpadDecimal: const NumberPressed('.'),

  LogicalKeyboardKey.add: const OperatorPressed('+'),
  LogicalKeyboardKey.numpadAdd: const OperatorPressed('+'),

  LogicalKeyboardKey.minus: const OperatorPressed('-'),
  LogicalKeyboardKey.numpadSubtract: const OperatorPressed('-'),

  LogicalKeyboardKey.asterisk: const OperatorPressed('×'),
  LogicalKeyboardKey.numpadMultiply: const OperatorPressed('×'),

  LogicalKeyboardKey.slash: const OperatorPressed('÷'),
  LogicalKeyboardKey.numpadDivide: const OperatorPressed('÷'),

  LogicalKeyboardKey.percent: PercentagePressed(),

  LogicalKeyboardKey.enter: CalculateResult(),
  LogicalKeyboardKey.numpadEnter: CalculateResult(),

  LogicalKeyboardKey.backspace: DeletePressed(),
  LogicalKeyboardKey.escape: const ClearPressed(),
};

final List<String> calcGridButtons = [
  'AC',
  '+/-',
  '%',
  '÷',
  '7',
  '8',
  '9',
  '×',
  '4',
  '5',
  '6',
  '-',
  '1',
  '2',
  '3',
  '+',
  '⌫',
  '0',
  '.',
  '=',
];
