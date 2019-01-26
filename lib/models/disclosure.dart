class Disclosure {
  String code;
  String company;
  String title;
  String document;
  String exchanges;
  String timeStr;
  List<String> tags;
  bool isSelected;

  Disclosure({
    this.code,
    this.company,
    this.title,
    this.document,
    this.exchanges,
    this.timeStr,
    this.tags,
    this.isSelected = false
  });
}