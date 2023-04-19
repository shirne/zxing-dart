import 'package:test/test.dart';

void main() {
  test('test zxing', () {
    final a = <int>[];
    a.addAll(List.generate(10, (index) => 0));
    a.fillRange(0, 10, 1);
    expect(a[2], 1);
    a[1] = 2;
    a[2] = 4;
    expect(a[2], 4);
  });
}
