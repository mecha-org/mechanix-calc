import 'package:calculator/core/utils/constant.dart';
import 'package:calculator/features/calculator/presentation/widgets/button_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/calculator_bloc.dart';
import '../../bloc/calculator_event.dart';
import '../../bloc/calculator_state.dart';
import '../widgets/display_panel.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final bloc = context.read<CalculatorBloc>();
    final key = event.logicalKey;

    // Special case: Shift + '=' => '+'
    if (key == LogicalKeyboardKey.equal &&
        HardwareKeyboard.instance.isShiftPressed) {
      bloc.add(const OperatorPressed('+'));
      return;
    }

    final action = logicalKeyboardKeyMap[key];
    if (action != null) {
      bloc.add(action);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: BlocBuilder<CalculatorBloc, CalculatorState>(
                  builder: (context, state) {
                    return DisplayPanel(
                      expression: state.expression,
                      result: state.result,
                      errorMessage: state.errorMessage,
                      history: state.history,
                      onHistoryItemTap: (expr) {
                        context.read<CalculatorBloc>().add(
                          ExpressionChanged(expr),
                        );
                      },
                    );
                  },
                ),
              ),
              const Expanded(child: ButtonGrid()),
            ],
          ),
        ),
      ),
    );
  }
}
