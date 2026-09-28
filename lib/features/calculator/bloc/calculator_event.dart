import 'package:equatable/equatable.dart';

abstract class CalculatorEvent extends Equatable {
  const CalculatorEvent();

  @override
  List<Object> get props => [];
}

class CalculateResult extends CalculatorEvent {
  final String expression;
  const CalculateResult([this.expression = '']);

  @override
  List<Object> get props => [expression];
}

class ClearPressed extends CalculatorEvent {
  const ClearPressed();
}


