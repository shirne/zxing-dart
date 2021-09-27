/// Any utils
class Utils {
  static arrayEquals(List<dynamic>? a, List<dynamic>? b) {
    if (a == null || b == null) {
      if (a == null && b == null) {
        return true;
      }
      return false;
    }
    if (a.runtimeType != b.runtimeType) {
      return false;
    }
    if (a.length != b.length) {
      return false;
    }

    for (int i = 0; i < a.length; i++) {
      if (a[i] is List) {
        if (!arrayEquals(a[i], b[i])) {
          return false;
        }
      } else if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }

  static int arrayHashCode(List<int>? a) {
    if (a == null) {
      return 0;
    }
    int result = 1;
    for (int element in a) {
      result = 31 * result + element;
    }
    return result;
  }

  static int reverseSign32(int x) {
    x = ((x >> 1) & 0x55555555) | ((x & 0x55555555) << 1).toUnsigned(32);
    x = ((x >> 2) & 0x33333333) | ((x & 0x33333333) << 2).toUnsigned(32);
    x = ((x >> 4) & 0x0f0f0f0f) | ((x & 0x0f0f0f0f) << 4).toUnsigned(32);
    x = ((x >> 8) & 0x00ff00ff) | ((x & 0x00ff00ff) << 8).toUnsigned(32);
    x = ((x >> 16) & 0x0000ffff) | ((x & 0x0000ffff) << 16).toUnsigned(32);
    return x;
  }

  static int reverse(int x) {
    x = ((x >> 1) & 0x55555555) | ((x & 0x55555555) << 1);
    x = ((x >> 2) & 0x33333333) | ((x & 0x33333333) << 2);
    x = ((x >> 4) & 0x0f0f0f0f) | ((x & 0x0f0f0f0f) << 4);
    x = ((x >> 8) & 0x00ff00ff) | ((x & 0x00ff00ff) << 8);
    x = ((x >> 16) & 0x0000ffff) | ((x & 0x0000ffff) << 16);

    return x;
  }
}
