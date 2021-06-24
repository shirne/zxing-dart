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
}
