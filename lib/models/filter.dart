import 'package:flutter/material.dart';

class Filter {
  bool isSelected;
  final bool isCustom;
  final String title;

  Filter(this.title, {this.isSelected = false, this.isCustom = false});

  toggle() {
    this.isSelected = !this.isSelected;
  }

  @override
  String toString() {
    return "$title $isSelected";
  }

  Key get key => ObjectKey({'title': this.title, 'isCustom': this.isCustom});
}
