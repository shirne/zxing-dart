import 'package:flutter/cupertino.dart';

class TypePicker<T> extends StatefulWidget {
  final T value;
  final List<T> values;
  final void Function(T type)? onChange;

  const TypePicker({
    Key? key,
    required this.value,
    this.onChange,
    required this.values,
  }) : super(key: key);

  @override
  State<TypePicker> createState() => _TypePickerState<T>();
}

class _TypePickerState<T> extends State<TypePicker<T>> {
  late FixedExtentScrollController _scrollController;
  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(
      initialItem: widget.values.indexOf(widget.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      itemExtent: 30,
      scrollController: _scrollController,
      onSelectedItemChanged: (idx) {
        if (widget.onChange != null) {
          widget.onChange!(widget.values[idx]);
        }
      },
      children: widget.values.map<Widget>((e) => Text(e.toString())).toList(),
    );
  }
}

Future<T?>? pickerType<T>(BuildContext context, List<T> values, T value) {
  return showCupertinoDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 200, horizontal: 50),
          child: CupertinoPopupSurface(
            child: Column(
              children: [
                const Text(
                  '请选择',
                  style: TextStyle(
                    height: 2.4,
                  ),
                ),
                Expanded(
                  child: Container(
                    color: CupertinoColors.white,
                    child: TypePicker<T>(
                      value: value,
                      values: values,
                      onChange: (T newType) {
                        value = newType;
                      },
                    ),
                  ),
                ),
                CupertinoButton(
                  child: const Text('确定'),
                  onPressed: () {
                    Navigator.of(context).pop(value);
                  },
                )
              ],
            ),
          ),
        ),
      );
    },
  );
}
