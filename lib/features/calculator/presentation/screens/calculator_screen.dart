import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/button_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgets/widgets.dart';
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
  bool _isHistoryOpen = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (_isHistoryOpen && event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        _isHistoryOpen = false;
      });
      return;
    }

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
    return BlocBuilder<CalculatorBloc, CalculatorState>(
      builder: (context, state) {
        final hasHistory = state.history.isNotEmpty;
        final isHistoryOpen = _isHistoryOpen && hasHistory;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          appBar: MechanixAppBar.small(
            backgroundColor: isHistoryOpen
                ? Theme.of(context).colorScheme.surfaceContainerLow
                : Colors.transparent,
            actions: [
              MechanixIconButton.standard(
                onPressed: hasHistory
                    ? () {
                        setState(() {
                          _isHistoryOpen = !isHistoryOpen;
                        });
                      }
                    : null,
                icon: Icon(isHistoryOpen ? Icons.close : Icons.history),
              ),
            ],
          ),
          body: KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _handleKeyEvent,
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: DisplayPanel(
                      expression: state.expression,
                      result: state.result,
                      errorMessage: state.errorMessage,
                      history: state.history,
                      isHistoryOpen: isHistoryOpen,
                      onDismissHistory: () {
                        setState(() {
                          _isHistoryOpen = false;
                        });
                      },
                      onHistoryItemTap: (expr) {
                        context.read<CalculatorBloc>().add(
                          ExpressionChanged(expr),
                        );
                        setState(() {
                          _isHistoryOpen = false;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    height: 304,
                    child: Listener(
                      onPointerDown: (_) {
                        if (_isHistoryOpen) {
                          setState(() {
                            _isHistoryOpen = false;
                          });
                        }
                      },
                      child: const ButtonGrid(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
