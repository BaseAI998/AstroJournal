import 'package:fl_chart/fl_chart.dart';
void main() {
  final event = FlTapUpEvent(0, const Offset(10, 10));
  print(event.localPosition);
}