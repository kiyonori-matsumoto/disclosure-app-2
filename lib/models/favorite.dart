import 'package:flutter/material.dart';

class Favorite {
  final String name;
  final String code;
  Key key;

  Favorite(this.name, this.code) {
    this.key = Key(this.code);
  }

  @override
  String toString() {
    return '$code $name';
  }
}
