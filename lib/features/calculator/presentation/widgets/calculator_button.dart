import 'package:flutter/material.dart';
import 'package:widgets/widgets.dart';

enum CalculatorButtonType { standard, action, primary }

class CalculatorButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onTap;
  final CalculatorButtonType type;

  const CalculatorButton({
    super.key,
    this.text,
    this.icon,
    required this.onTap,
    this.type = CalculatorButtonType.standard,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = switch (type) {
      CalculatorButtonType.primary => colorScheme.primary,
      CalculatorButtonType.action => colorScheme.surfaceContainer,
      CalculatorButtonType.standard => colorScheme.surfaceContainerHigh,
    };
    final foregroundColor = switch (type) {
      CalculatorButtonType.primary => colorScheme.onPrimary,
      CalculatorButtonType.action => colorScheme.onSecondaryContainer,
      CalculatorButtonType.standard => colorScheme.onSurface,
    };

    return MechanixButton(
      onPressed: onTap,
      widthSizing: ButtonLayoutSizing.fill,
      heightSizing: ButtonLayoutSizing.fill,
      icon: icon,
      theme: const ButtonThemeDataConfig(padding: EdgeInsets.zero),
      labelText: text != null
          ? (["AC", "+/-"].contains(text))
                ? Text(
                    text!,
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontFamily: MechanixFontFamily.geistMono,
                      color: foregroundColor,
                    ),
                  )
                : Text(
                    text!,
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontFamily: MechanixFontFamily.geistMono,
                      color: foregroundColor,
                      fontSize: 32,
                    ),
                  )
          : null,
      backgroundColor: text == '.'
          ? colorScheme.surfaceContainer
          : backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}
