import 'package:flutter/material.dart';

class BottomTextFieldWithIcon extends StatefulWidget {
  const BottomTextFieldWithIcon({
    Key? key,
    required this.onSubmit,
    this.onChanged,
    this.hintText,
    this.keyboardType,
    this.iconData = Icons.add,
  }) : super(key: key);

  final void Function(String) onSubmit;
  final void Function(String)? onChanged;
  final String? hintText;
  final TextInputType? keyboardType;
  final IconData iconData;

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
            icon: Icon(this.widget.iconData),
          ),
          // contentPadding: EdgeInsets.all(4.0),
        ),
        onChanged: this.widget.onChanged,
        onSubmitted: this._handleSubmit,
        keyboardType: this.widget.keyboardType,
      ),
    );
  }
}
