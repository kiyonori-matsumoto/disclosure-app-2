import 'package:flutter/material.dart';

class Company {
  String name;
  String code;
  Key key;

  Company(this.code, {this.name}) {
    this.key = Key(this.code);
  }

  bool match(String text) {
    return this.name.toLowerCase().contains(text) || this.code.startsWith(text);
  }

  @override
  String toString() {
    return '${code.length > 4 ? code.substring(0, 4) : code} $name';
  }
}
