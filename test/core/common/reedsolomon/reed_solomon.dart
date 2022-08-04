import 'dart:math';
import 'dart:typed_data';

import 'package:zxing_lib/common.dart';

const int DECODER_RANDOM_TEST_ITERATIONS = 3;
const int DECODER_TEST_ITERATIONS = 10;

String arrayToString(List<int> data) {
  final sb = StringBuilder('{');
  for (int i = 0; i < data.length; i++) {
    sb.write(
      i > 0 ? ',${data[i].toRadixString(16)}' : data[i].toRadixString(16),
    );
  }
  sb.write('}');
  return sb.toString();
}

Random getPseudoRandom() {
  return Random(0xDEADBEEF);
}

void assertDataEquals(String message, List<int> expected, List<int> received) {
  for (int i = 0; i < expected.length; i++) {
    assert(expected[i] == received[i],
        '$message. Mismatch at $i. Expected $expected, got ${received.getRange(0, expected.length)}');
  }
}

void corrupt(List<int> received, int howMany, Random random, int max) {
  final corrupted = <int>{};
  for (int j = 0; j < howMany; j++) {
    final int location = random.nextInt(received.length);
    final int value = random.nextInt(max);
    if (corrupted.contains(location) || received[location] == value) {
      j--;
    } else {
      corrupted.add(location);
      received[location] = value;
    }
  }
}

void testEncoder(GenericGF field, List<int> dataWords, List<int> ecWords) {
  final encoder = ReedSolomonEncoder(field);
  final messageExpected = Int32List(dataWords.length + ecWords.length);
  final message = Int32List(dataWords.length + ecWords.length);
  List.copyRange(messageExpected, 0, dataWords, 0, dataWords.length);
  //System.arraycopy(dataWords, 0, messageExpected, 0, dataWords.length);
  List.copyRange(messageExpected, dataWords.length, ecWords, 0, ecWords.length);
  List.copyRange(message, 0, dataWords, 0, dataWords.length);
  encoder.encode(message, ecWords.length);
  assertDataEquals(
    'Encode in $field (${dataWords.length},${ecWords.length}) failed',
    messageExpected,
    message,
  );
}

void testDecoder(GenericGF field, List<int> dataWords, List<int> ecWords) {
  final decoder = ReedSolomonDecoder(field);
  final message = Int32List(dataWords.length + ecWords.length);
  final maxErrors = ecWords.length ~/ 2;
  final random = getPseudoRandom();
  final iterations = field.size > 256 ? 1 : DECODER_TEST_ITERATIONS;
  for (int j = 0; j < iterations; j++) {
    for (int i = 0; i < ecWords.length; i++) {
      if (i > 10 && i < ecWords.length ~/ 2 - 10) {
        // performance improvement - skip intermediate cases in long-running tests
        i += ecWords.length ~/ 10;
      }
      List.copyRange(message, 0, dataWords, 0, dataWords.length);
      List.copyRange(message, dataWords.length, ecWords, 0, ecWords.length);

      corrupt(message, i, random, field.size);
      try {
        decoder.decode(message, ecWords.length);
      } catch (e) {
        // ReedSolomonException
        // fail only if maxErrors exceeded
        assert(i > maxErrors,
            'Decode in $field (${dataWords.length},${ecWords.length}) failed at $i errors: $e');
        // else stop
        break;
      }
      if (i < maxErrors) {
        assertDataEquals(
          'Decode in $field (${dataWords.length}, ${ecWords.length}) failed at $i errors',
          dataWords,
          message,
        );
      }
    }
  }
}

void testEncodeDecode(GenericGF field, List<int> dataWords, List<int> ecWords) {
  testEncoder(field, dataWords, ecWords);
  testDecoder(field, dataWords, ecWords);
}

void testEncodeDecodeRandom(GenericGF field, int dataSize, int ecSize) {
  assert(dataSize > 0 && dataSize <= field.size - 3,
      'Invalid data size for $field');
  assert(ecSize > 0 && ecSize + dataSize <= field.size,
      'Invalid ECC size for $field');
  final encoder = ReedSolomonEncoder(field);
  final message = Int32List(dataSize + ecSize);
  final dataWords = Int32List(dataSize);
  final ecWords = Int32List(ecSize);
  final random = getPseudoRandom();
  final int iterations = field.size > 256 ? 1 : DECODER_RANDOM_TEST_ITERATIONS;
  for (int i = 0; i < iterations; i++) {
    // generate random data
    for (int k = 0; k < dataSize; k++) {
      dataWords[k] = random.nextInt(field.size);
    }
    // generate ECC words
    List.copyRange(message, 0, dataWords, 0, dataWords.length);
    encoder.encode(message, ecWords.length);
    List.copyRange(ecWords, 0, message, dataSize, dataSize + ecSize);
    // check to see if Decoder can fix up to ecWords/2 random errors
    testDecoder(field, dataWords, ecWords);
  }
}
