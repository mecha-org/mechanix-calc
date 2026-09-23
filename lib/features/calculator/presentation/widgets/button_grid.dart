import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_calculator/features/calculator/bloc/calculator_bloc.dart';
import 'package:mechanix_calculator/features/calculator/bloc/calculator_event.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/calculator_button.dart';

class CalculatorButtonItem {
  final String? text;
  final IconData? icon;
  final CalculatorButtonType type;
  final CalculatorEvent event;

  const CalculatorButtonItem({
    this.text,
    this.icon,
    this.type = CalculatorButtonType.standard,
    required this.event,
  });
}

const List<CalculatorButtonItem> calculatorButtons = [
  // Row 1
  CalculatorButtonItem(
    text: 'AC',
    type: CalculatorButtonType.action,
    event: ClearPressed(),
  ),
  CalculatorButtonItem(
    text: '+/-',
    type: CalculatorButtonType.action,
    event: ToggleSignPressed(),
  ),
  CalculatorButtonItem(
    icon: CupertinoIcons.percent,
    type: CalculatorButtonType.action,
    event: PercentagePressed(),
  ),
  CalculatorButtonItem(
    text: '÷',
    type: CalculatorButtonType.action,
    event: OperatorPressed('÷'),
  ),

  // Row 2
  CalculatorButtonItem(text: '7', event: NumberPressed('7')),
  CalculatorButtonItem(text: '8', event: NumberPressed('8')),
  CalculatorButtonItem(text: '9', event: NumberPressed('9')),
  CalculatorButtonItem(
    text: '×',
    type: CalculatorButtonType.action,
    event: OperatorPressed('×'),
  ),

  // Row 3
  CalculatorButtonItem(text: '4', event: NumberPressed('4')),
  CalculatorButtonItem(text: '5', event: NumberPressed('5')),
  CalculatorButtonItem(text: '6', event: NumberPressed('6')),
  CalculatorButtonItem(
    text: '-',
    type: CalculatorButtonType.action,
    event: OperatorPressed('-'),
  ),

  // Row 4
  CalculatorButtonItem(text: '1', event: NumberPressed('1')),
  CalculatorButtonItem(text: '2', event: NumberPressed('2')),
  CalculatorButtonItem(text: '3', event: NumberPressed('3')),
  CalculatorButtonItem(
    text: '+',
    type: CalculatorButtonType.action,
    event: OperatorPressed('+'),
  ),

  // Row 5
  CalculatorButtonItem(
    icon: Icons.backspace_outlined,
    type: CalculatorButtonType.action,
    event: DeletePressed(),
  ),
  CalculatorButtonItem(text: '0', event: NumberPressed('0')),
  CalculatorButtonItem(
    text: '.',
    event: NumberPressed('.'),
    type: CalculatorButtonType.action,
  ),
  CalculatorButtonItem(
    text: '=',
    type: CalculatorButtonType.primary,
    event: CalculateResult(),
  ),
];

class ButtonGrid extends StatelessWidget {
  const ButtonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CalculatorBloc>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double crossSpacing = 8.0;
          const double mainSpacing = 8.0;
          final double itemWidth =
              (constraints.maxWidth - (crossSpacing * 3)) / 4;
          final double itemHeight =
              (constraints.maxHeight - (mainSpacing * 4)) / 5;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: calculatorButtons.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: mainSpacing,
              crossAxisSpacing: crossSpacing,
              childAspectRatio: itemWidth / itemHeight,
            ),
            itemBuilder: (context, index) {
              final btn = calculatorButtons[index];
              return CalculatorButton(
                text: btn.text,
                icon: btn.icon,
                type: btn.type,
                onTap: () => bloc.add(btn.event),
              );
            },
          );
        },
      ),
    );
  }
}
