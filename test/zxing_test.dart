import 'package:flutter_test/flutter_test.dart';

import 'package:zxing/zxing.dart';

void main() {
  test('adds one to input values', () {
    final calculator = Calculator();
    expect(calculator.addOne(2), 3);
    expect(calculator.addOne(-7), -6);
    expect(calculator.addOne(0), 1);
  });

  test('test List', () {
    List<int> a = [];
    a.addAll(List.generate(10, (index) => 0));
    a.fillRange(0, 10, 1);
    print(a);
    a[1] = 2;
    a[2] = 4;
    print(a);
  });
}
