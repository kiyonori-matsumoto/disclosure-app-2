import 'package:flutter/material.dart';

class Company {
  String? name;
  String? code;
  String? edinetCode;
  String? nameKana;
  Key? key;

  Company(this.code,
      {String name = '', String? edinetCode = '', this.nameKana = ''}) {
    this.name = name.trim();
    this.key = this.code != null ? Key(this.code!) : null;
    this.edinetCode = edinetCode ?? '';
  }

  bool match(String text, [String? kanaText]) {
    // Optimization: avoid converting text on every match if already computed.
    final kana = kanaText ?? hiraToKanaStatic(text);
    return this.name!.toLowerCase().contains(text) ||
        this.code!.startsWith(text) ||
        this.nameKana!.contains(kana);
  }

  bool operator ==(o) => o is Company && code == o.code;
  int get hashCode => this.code.hashCode;

  @override
  String toString() {
    return '${code!.length > 4 ? code!.substring(0, 4) : code} $name';
  }

  String hiraToKana(String str) {
    return hiraToKanaStatic(str);
  }

  // Optimization: use static RegExp to avoid recompiling it for every method call.
  static final RegExp _hiraRegExp = RegExp("[ぁ-ゔ]");
  static String hiraToKanaStatic(String str) {
    return str.replaceAllMapped(_hiraRegExp,
        (Match m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) + 0x60));
  }
}
