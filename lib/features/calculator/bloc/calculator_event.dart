import 'package:equatable/equatable.dart';

abstract class CalculatorEvent extends Equatable {
  const CalculatorEvent();

  @override
  List<Object> get props => [];
}

class NumberPressed extends CalculatorEvent {
  final String number;
  const NumberPressed(this.number);

  @override
  List<Object> get props => [number];
}

class ExpressionChanged extends CalculatorEvent {
  final String expression;
  const ExpressionChanged(this.expression);

  @override
  List<Object> get props => [expression];
}

class OperatorPressed extends CalculatorEvent {
  final String operator;
  const OperatorPressed(this.operator);

  @override
  List<Object> get props => [operator];
}

class ClearPressed extends CalculatorEvent {
  const ClearPressed();
}

class DeletePressed extends CalculatorEvent {
  const DeletePressed();
}

class CalculateResult extends CalculatorEvent {
  const CalculateResult();
}

class ToggleSignPressed extends CalculatorEvent {
  const ToggleSignPressed();
}

class PercentagePressed extends CalculatorEvent {
  const PercentagePressed();
}

