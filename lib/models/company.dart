import 'package:flutter/material.dart';

class Company {
  String name;
  String code;
  String edinetCode;
  String nameKana;
  Key key;

  Company(this.code,
      {String name = '', String edinetCode = '', this.nameKana = ''}) {
    this.name = name.trim();
    this.key = Key(this.code);
    this.edinetCode = edinetCode ?? '';
  }

  bool match(String text) {
    return this.name.toLowerCase().contains(text) ||
        this.code.startsWith(text) ||
        this.nameKana.contains(hiraToKana((text)));
  }

  bool operator ==(o) => o is Company && code == o.code;
  int get hashCode => int.parse(this.code);

  @override
  String toString() {
    return '${code.length > 4 ? code.substring(0, 4) : code} $name';
  }

  String hiraToKana(String str) {
    return str.replaceAllMapped(new RegExp("[ぁ-ゔ]"),
        (Match m) => String.fromCharCode(m.group(0).codeUnitAt(0) + 0x60));
  }
}
