import 'package:calculator/core/utils/constant.dart';
import 'package:calculator/features/calculator/bloc/calculator_bloc.dart';
import 'package:calculator/features/calculator/bloc/calculator_event.dart';
import 'package:calculator/features/calculator/presentation/widgets/calculator_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ButtonGrid extends StatelessWidget {
  const ButtonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CalculatorBloc>();

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate the aspect ratio dynamically based on available space
          // 4 columns and 5 rows
          final double horizontalSpacing = 5.0 * 3; // 3 gaps between 4 columns
          final double verticalSpacing = 4.0 * 4; // 4 gaps between 5 rows

          final double itemWidth =
              (constraints.maxWidth - horizontalSpacing) / 4;
          final double itemHeight =
              (constraints.maxHeight - verticalSpacing) / 5;

          final double dynamicAspectRatio = itemWidth / itemHeight;

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: calcGridButtons.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 4,
              crossAxisSpacing: 5,
              childAspectRatio: dynamicAspectRatio,
            ),
            itemBuilder: (context, index) {
              final text = calcGridButtons[index];
              return CalcButton(
                text: text,
                onTap: () => _handleTap(bloc, text),
              );
            },
          );
        },
      ),
    );
  }

  void _handleTap(CalculatorBloc bloc, String text) {
    final event = switch (text) {
      'AC' => const ClearPressed(),
      '⌫' => DeletePressed(),
      '=' => CalculateResult(),
      '+/-' => ToggleSignPressed(),
      '%' => PercentagePressed(),
      '÷' || '×' || '-' || '+' => OperatorPressed(text),
      _ => NumberPressed(text), // '_' acts as the 'else' / default case
    };

    bloc.add(event);
  }
}

class CalcButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;

  const CalcButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isOperator = ['÷', '×', '-', '+', '='].contains(text);
    final isAction = ['AC', '+/-', '%'].contains(text);
    final color = (isOperator || isAction)
        ? const Color(0xFF2C2C2C)
        : const Color(0xFF1A1A1A);

    return CalculatorButton(
      text: text,
      icon: text == '⌫' ? Icons.backspace_outlined : icon,
      color: color,
      onTap: onTap,
    );
  }
}
