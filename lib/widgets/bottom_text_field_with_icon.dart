import 'package:flutter/material.dart';

class BottomTextFieldWithIcon extends StatefulWidget {
  const BottomTextFieldWithIcon({
    Key key,
    @required this.onSubmit,
    this.hintText,
    this.keyboardType,
  }) : super(key: key);

  final void Function(String) onSubmit;
  final String hintText;
  final TextInputType keyboardType;

  @override
  BottomTextFieldWithIconState createState() {
    return new BottomTextFieldWithIconState();
  }
}

class BottomTextFieldWithIconState extends State<BottomTextFieldWithIcon> {
  final TextEditingController _controller = TextEditingController();

  void _handleSubmit(String code) {
    this.widget.onSubmit(code);
    this._controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: this.widget.hintText,
          border: InputBorder.none,
          suffixIcon: IconButton(
            onPressed: () => this._handleSubmit(this._controller.text),
            icon: Icon(Icons.add),
          ),
          // contentPadding: EdgeInsets.all(4.0),
        ),
        onSubmitted: this._handleSubmit,
        keyboardType: this.widget.keyboardType,
      ),
    );
  }
}
