import 'package:flutter/material.dart';
class AsyncDropdownSingleSelect extends StatefulWidget {
  final List<String> items;
  final Future<String?> Function() loadInitialValue;
  final String labelText;
  final ValueChanged<String?> onChanged;

  const AsyncDropdownSingleSelect({
    Key? key,
    required this.items,
    required this.loadInitialValue,
    this.labelText = "请选择",
    required this.onChanged,
  }) : super(key: key);

  @override
  _AsyncDropdownSingleSelectState createState() =>
      _AsyncDropdownSingleSelectState();
}

class _AsyncDropdownSingleSelectState
    extends State<AsyncDropdownSingleSelect> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    widget.loadInitialValue().then((value) {
      setState(() {
        selectedValue = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请选择一项';
        }
        return null;
      },
      onChanged: (String? value) {
        setState(() {
          selectedValue = value;
        });
        widget.onChanged(value);
      },
      items: widget.items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    );
  }
}

typedef FetchInitialValue = Future<String> Function();

class AsyncTextField extends StatefulWidget {
  final FetchInitialValue fetchInitialValue;
  final String labelText;
  final TextEditingController controller;

  const AsyncTextField({
    Key? key,
    required this.fetchInitialValue,
    this.labelText = "请输入",
    required this.controller,
  }) : super(key: key);

  @override
  _AsyncTextFieldState createState() => _AsyncTextFieldState();
}

class _AsyncTextFieldState extends State<AsyncTextField> {
  bool _isLoaded = false;

  @override
  void didUpdateWidget(covariant AsyncTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _isLoaded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: widget.fetchInitialValue(),
      builder: (context, snapshot) {
        if (!snapshot.hasData && !_isLoaded) {
          return Center(child: CircularProgressIndicator());
        }

        if (!_isLoaded && snapshot.hasData) {
          widget.controller.text = snapshot.data!;
          _isLoaded = true;
        }

        return TextField(
          controller: widget.controller,
          decoration: InputDecoration(labelText: widget.labelText),
          onChanged: (value) {
            // 可选：监听输入变化
          },
        );
      },
    );
  }
}