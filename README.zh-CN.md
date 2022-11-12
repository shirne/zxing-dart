# zxing-dart
[![pub package](https://img.shields.io/pub/v/zxing_lib.svg)](https://pub.dartlang.org/packages/zxing_lib)

[zxing](https://github.com/zxing/zxing) Dart版，用于各种条码、二维码编码和解码.

| | |
|:---:|:---:|
|ZXing二维码/条码生成组件|[![pub package](https://img.shields.io/pub/v/zxing_widget.svg)](https://pub.dartlang.org/packages/zxing_widget)|
|ZXing扫码组件|[![pub package](https://img.shields.io/pub/v/zxing_scanner.svg)](https://pub.dartlang.org/packages/zxing_scanner)|



## 为什么做这个包

* 纯Dart实现，无需依赖原生包，平台兼容性好
* 为所有平台提供纯Dart编码功能
* 为所有平台提供纯Dart解码功能
* 研究学习，以及对Dart语言的一种探索

...目前这个包在解码速度和准确率上远不如其它原生包，可以做为编码工具和部分平台(如：Web, Desktop)的解码之用。本人也会持续关注zxing的改进以及本项目中性能问题的改进，欢迎有解码算法及图像算法经验的大佬提供改进建议。

## 功能计划

- ✅ 核心库翻译
- ✅ 核心库测试翻译
- ✅ 核心库单元测试
- ✅ 演示APP生成二维码
- ✅ 演示APP扫描二维码(案例中有捕获照片和通过Stream获取的CameraImage两种方式)
- ✅ 针对dart的优化

- 🚧 zxing java 持续同步中...

## 预览

|演示App预览图| |
|:---:|:---:|
|![01](preview/01.png "01")|![02](preview/02.png "02")|

## Flutter

This project is a starting point for a Dart
[package](https://flutter.dev/developing-packages/),
a library module containing code that can be shared easily across
multiple Flutter or Dart projects.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.
