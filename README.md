# ZXing-Dart
[![pub package](https://img.shields.io/pub/v/zxing_lib.svg)](https://pub.dartlang.org/packages/zxing_lib)

A Dart port of [zxing](https://github.com/zxing/zxing) that encode and decode multiple 1D/2D barcodes, Supported qrcode, pdf417, oned, maxicode, datamatrix, aztec.


## Progress

- [x] Core package translate
- [x] Core test translate
- [x] Core unit test(all passed)
- [x] Demo Creator
- [x] Demo Scanner
- [x] Code optimization
- [ ] Keep syncing from zxing java...

## Preview

|Demo App| |
|:---:|:---:|
|![01](preview/01.png "01")|![02](preview/02.png "02")|

## Exception Type
* IllegalArgumentException => ArgumentError
* FormatException => FormatsException
* IllegalStateException => StateError

## Issue
* Because there is no float type in dart, the results of some test cases are different from zxing

## Flutter

This project is a starting point for a Dart
[package](https://flutter.dev/developing-packages/),
a library module containing code that can be shared easily across
multiple Flutter or Dart projects.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.
