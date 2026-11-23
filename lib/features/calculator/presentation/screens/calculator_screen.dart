import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/data/utils/expression_builder.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/copied_text.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/button_grid.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/display_context_menu.dart';
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
  final ValueNotifier<bool> _isHistoryOpenNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> _expressionNotifier = ValueNotifier<String>('');
  final ValueNotifier<String> _errorMessageNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _focusNode.dispose();
    _isHistoryOpenNotifier.dispose();
    _expressionNotifier.dispose();
    _errorMessageNotifier.dispose();
    super.dispose();
  }

  bool get _hasFatalError =>
      _errorMessageNotifier.value == invalidOperationsErrorMessage;

  void _onNumberPressed(String number) {
    if (_hasFatalError) {
      _errorMessageNotifier.value = '';
      _expressionNotifier.value = number == '.' ? '0.' : number;
      context.read<CalculatorBloc>().add(const ClearPressed());
      return;
    }
    final res = ExpressionBuilder.handleNumber(
      _expressionNotifier.value,
      number,
    );
    _expressionNotifier.value = res.expression;
    _errorMessageNotifier.value = res.errorMessage;
  }

  void _onOperatorPressed(String operator) {
    if (_hasFatalError) {
      _errorMessageNotifier.value = '';
      _expressionNotifier.value = '';
      context.read<CalculatorBloc>().add(const ClearPressed());
      return;
    }
    // Only a calculated result continues: the "0" shown at start or after
    // AC is not one, so an operator there does nothing.
    final state = context.read<CalculatorBloc>().state;
    final res = ExpressionBuilder.handleOperator(
      _expressionNotifier.value,
      operator,
      previousResult: state.expression.isEmpty ? null : state.result,
    );
    _expressionNotifier.value = res.expression;
    _errorMessageNotifier.value = res.errorMessage;
  }

  void _onClearPressed() {
    _expressionNotifier.value = '';
    _errorMessageNotifier.value = '';
    context.read<CalculatorBloc>().add(const ClearPressed());
  }

  void _onDeletePressed() {
    if (_hasFatalError) {
      _onClearPressed();
      return;
    }
    final previous = _expressionNotifier.value;
    final res = ExpressionBuilder.handleDelete(previous);
    _expressionNotifier.value = res.expression;
    _errorMessageNotifier.value = res.errorMessage;

    // Clear the result when the expression becomes empty to avoid showing the previous result.
    if (previous.isNotEmpty && res.expression.isEmpty) {
      context.read<CalculatorBloc>().add(const ClearPressed());
    }
  }

  void _onToggleSignPressed() {
    if (_hasFatalError) {
      _onClearPressed();
      return;
    }
    final previousResult = context.read<CalculatorBloc>().state.result;
    final res = ExpressionBuilder.handleToggleSign(
      _expressionNotifier.value,
      previousResult: previousResult == '0' ? null : previousResult,
    );
    _expressionNotifier.value = res.expression;
    _errorMessageNotifier.value = res.errorMessage;
  }

  void _onSuperscriptPressed(String digit) {
    if (_hasFatalError) {
      _onClearPressed();
      return;
    }
    _apply(
      ExpressionBuilder.handleSuperscript(_expressionNotifier.value, digit),
    );
  }

  void _onOpenBracketPressed() {
    if (_hasFatalError) {
      _onClearPressed();
    }
    _apply(ExpressionBuilder.handleOpenBracket(_expressionNotifier.value));
  }

  void _onCloseBracketPressed() {
    if (_hasFatalError) {
      _onClearPressed();
      return;
    }
    _apply(ExpressionBuilder.handleCloseBracket(_expressionNotifier.value));
  }

  void _apply(ExpressionResult result) {
    _expressionNotifier.value = result.expression;
    _errorMessageNotifier.value = result.errorMessage;
  }

  void _onPercentagePressed() {
    if (_hasFatalError) {
      _onClearPressed();
      return;
    }
    final res = ExpressionBuilder.handlePercentage(_expressionNotifier.value);
    _expressionNotifier.value = res.expression;
    _errorMessageNotifier.value = res.errorMessage;
  }

  void _onCalculateResult() {
    if (_expressionNotifier.value.isNotEmpty) {
      final expr = ExpressionBuilder.closeBrackets(_expressionNotifier.value);
      _expressionNotifier.value = '';
      context.read<CalculatorBloc>().add(CalculateResult(expr));
    }
  }

  /// What the main line shows, decided by [displayLines] from the same
  /// values [_DisplayPanelSection] gives the display.
  ({String top, String main, bool showsError}) get _displayLines {
    final state = context.read<CalculatorBloc>().state;
    final errorMessage = _errorMessageNotifier.value;
    return displayLines(
      expression: _expressionNotifier.value,
      calculatedExpression: state.expression,
      result: state.result,
      errorMessage: _shownError(errorMessage, state.errorMessage),
    );
  }

  /// Copies the main line as plain ASCII (`8888×979999` -> `8888*979999`,
  /// `9.9×10¹⁷` -> `9.9*10^17`), so every app can paste it; nothing while an
  /// error is shown.
  Future<void> _onCopyPressed() async {
    final lines = _displayLines;
    if (lines.showsError) return;
    await Clipboard.setData(
      ClipboardData(text: CopiedText.fromDisplay(lines.main)),
    );
  }

  /// Adds the clipboard text at the end of the input, as if typed. After an
  /// error it starts from empty input, like any other key.
  Future<void> _onPastePressed() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (!mounted || text == null || text.trim().isEmpty) return;
    if (_hasFatalError) _onClearPressed();
    _apply(ExpressionBuilder.handlePaste(_expressionNotifier.value, text));
  }

  /// Context menu items for the display: Copy unless an error is shown,
  /// Paste always.
  List<ContextMenuButtonItem> _contextMenuItems() => [
    if (!_displayLines.showsError)
      ContextMenuButtonItem(
        type: ContextMenuButtonType.copy,
        onPressed: _onCopyPressed,
      ),
    ContextMenuButtonItem(
      type: ContextMenuButtonType.paste,
      onPressed: _onPastePressed,
    ),
  ];

  void _handleButtonAction(CalculatorButtonData button) {
    DisplayContextMenu.hide();
    switch (button.action) {
      case CalculatorActionType.number:
        _onNumberPressed(button.value ?? button.text ?? '');
      case CalculatorActionType.superscript:
        _onSuperscriptPressed(button.value!);
      case CalculatorActionType.operator:
        _onOperatorPressed(button.value ?? button.text ?? '');
      case CalculatorActionType.openBracket:
        _onOpenBracketPressed();
      case CalculatorActionType.closeBracket:
        _onCloseBracketPressed();
      case CalculatorActionType.clear:
        _onClearPressed();
      case CalculatorActionType.delete:
        _onDeletePressed();
      case CalculatorActionType.toggleSign:
        _onToggleSignPressed();
      case CalculatorActionType.percentage:
        _onPercentagePressed();
      case CalculatorActionType.calculate:
        _onCalculateResult();
      case CalculatorActionType.copy:
        _onCopyPressed();
      case CalculatorActionType.paste:
        _onPastePressed();
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (_isHistoryOpenNotifier.value &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _isHistoryOpenNotifier.value = false;
      return;
    }

    final keyboard = HardwareKeyboard.instance;
    final action = buttonForKey(
      event.logicalKey,
      shift: keyboard.isShiftPressed,
      control: keyboard.isControlPressed,
      alt: keyboard.isAltPressed,
      meta: keyboard.isMetaPressed,
    );
    if (action != null) {
      // Same as tapping the button grid: typing closes the history panel.
      _closeHistory();
      _handleButtonAction(action);
    }
  }

  void _closeHistory() {
    if (_isHistoryOpenNotifier.value) {
      _isHistoryOpenNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CalculatorBloc, CalculatorState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty &&
            state.errorMessage == invalidOperationsErrorMessage) {
          _errorMessageNotifier.value = state.errorMessage;
        } else if (state.errorMessage.isEmpty &&
            _errorMessageNotifier.value == invalidOperationsErrorMessage) {
          _errorMessageNotifier.value = '';
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: _CalculatorAppBar(
          isHistoryOpenNotifier: _isHistoryOpenNotifier,
        ),
        body: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _DisplayPanelSection(
                        expressionNotifier: _expressionNotifier,
                        errorMessageNotifier: _errorMessageNotifier,
                        isHistoryOpenNotifier: _isHistoryOpenNotifier,
                        contextMenuItems: _contextMenuItems,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Listener(
                        onPointerDown: (_) {
                          if (_isHistoryOpenNotifier.value) {
                            _isHistoryOpenNotifier.value = false;
                          }
                        },
                        child: ButtonGrid(onButtonPressed: _handleButtonAction),
                      ),
                    ),
                  ],
                ),
                _HistoryOverlaySection(
                  isHistoryOpenNotifier: _isHistoryOpenNotifier,
                  expressionNotifier: _expressionNotifier,
                  errorMessageNotifier: _errorMessageNotifier,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The error the display shows: one set by the input (a limit, an invalid
/// paste), else the calculator's (e.g. "Error" for 5÷0).
String _shownError(String inputError, String calculatorError) =>
    inputError.isNotEmpty ? inputError : calculatorError;

class _DisplayPanelSection extends StatelessWidget {
  final ValueNotifier<String> expressionNotifier;
  final ValueNotifier<String> errorMessageNotifier;
  final ValueNotifier<bool> isHistoryOpenNotifier;
  final List<ContextMenuButtonItem> Function() contextMenuItems;

  const _DisplayPanelSection({
    required this.expressionNotifier,
    required this.errorMessageNotifier,
    required this.isHistoryOpenNotifier,
    required this.contextMenuItems,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      CalculatorBloc,
      CalculatorState,
      ({
        String expression,
        String result,
        List<HistoryItem> history,
        String errorMessage,
      })
    >(
      selector: (state) => (
        expression: state.expression,
        result: state.result,
        history: state.history,
        errorMessage: state.errorMessage,
      ),
      builder: (context, state) {
        return ValueListenableBuilder<String>(
          valueListenable: expressionNotifier,
          builder: (context, expression, _) {
            return ValueListenableBuilder<String>(
              valueListenable: errorMessageNotifier,
              builder: (context, errorMessage, _) {
                return DisplayPanel(
                  expression: expression,
                  calculatedExpression: state.expression,
                  result: state.result,
                  errorMessage: _shownError(
                    errorMessage,
                    state.errorMessage,
                  ),
                  history: state.history,
                  isHistoryOpen: false,
                  contextMenuItems: contextMenuItems,
                  onDismissHistory: () {
                    isHistoryOpenNotifier.value = false;
                  },
                  onHistoryItemTap: (expr) {
                    expressionNotifier.value = expr;
                    errorMessageNotifier.value = '';
                    isHistoryOpenNotifier.value = false;
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HistoryOverlaySection extends StatelessWidget {
  final ValueNotifier<bool> isHistoryOpenNotifier;
  final ValueNotifier<String> expressionNotifier;
  final ValueNotifier<String> errorMessageNotifier;

  const _HistoryOverlaySection({
    required this.isHistoryOpenNotifier,
    required this.expressionNotifier,
    required this.errorMessageNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CalculatorBloc, CalculatorState, List<HistoryItem>>(
      selector: (state) => state.history,
      builder: (context, history) {
        return ValueListenableBuilder<bool>(
          valueListenable: isHistoryOpenNotifier,
          builder: (context, isHistoryOpen, _) {
            if (!isHistoryOpen || history.isEmpty) {
              return const SizedBox.shrink();
            }

            return Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  widthFactor: 1.0,
                  heightFactor: 0.36,
                  child: HistoryOverlay(
                    history: history,
                    onHistoryItemTap: (expr) {
                      expressionNotifier.value = expr;
                      errorMessageNotifier.value = '';
                      isHistoryOpenNotifier.value = false;
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CalculatorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ValueNotifier<bool> isHistoryOpenNotifier;

  const _CalculatorAppBar({required this.isHistoryOpenNotifier});

  @override
  Size get preferredSize => const MechanixAppBar().preferredSize;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CalculatorBloc, CalculatorState, bool>(
      selector: (state) => state.history.isNotEmpty,
      builder: (context, hasHistory) {
        return ValueListenableBuilder<bool>(
          valueListenable: isHistoryOpenNotifier,
          builder: (context, isHistoryOpen, _) {
            final isHistoryActive = isHistoryOpen && hasHistory;

            return MechanixAppBar.small(
              backgroundColor: isHistoryActive
                  ? Theme.of(context).colorScheme.surfaceContainerLow
                  : Colors.transparent,
              actions: [
                MechanixIconButton.standard(
                  key: const Key('history_button'),
                  onPressed: hasHistory
                      ? () {
                          isHistoryOpenNotifier.value =
                              !isHistoryOpenNotifier.value;
                        }
                      : null,
                  icon: Icon(isHistoryActive ? Icons.close : Icons.history),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
