import 'package:disclosure_app_fl/utils/disclosure_filter_helper.dart';
import 'package:flutter/material.dart';

const defaultFilterStrings = DisclosureFilterHelper.defaultFilterStrings;

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
