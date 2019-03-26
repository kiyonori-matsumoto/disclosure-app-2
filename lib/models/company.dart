import 'package:flutter/material.dart';

class Company {
  String name;
  String code;
  String edinetCode;
  Key key;

  Company(this.code, {String name = '', String edinetCode = ''}) {
    this.name = name.trim();
    this.key = Key(this.code);
    this.edinetCode = edinetCode;
  }

  bool match(String text) {
    return this.name.toLowerCase().contains(text) || this.code.startsWith(text);
  }

  @override
  String toString() {
    return '${code.length > 4 ? code.substring(0, 4) : code} $name';
  }
}
