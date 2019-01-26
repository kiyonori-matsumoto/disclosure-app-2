class Company {
  String name;
  String code;

  Company(this.name, this.code);

  bool match(String text) {
    return this.name.contains(text) || this.code.startsWith(text);
  }
}
