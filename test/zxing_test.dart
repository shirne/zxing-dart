import 'package:flutter_test/flutter_test.dart';

import 'package:zxing_lib/zxing.dart';

void main() {
  test('test zxing', () {
    List<int> a = [];
    a.addAll(List.generate(10, (index) => 0));
    a.fillRange(0, 10, 1);
    print(a);
    a[1] = 2;
    a[2] = 4;
    print(a);
  });
}
