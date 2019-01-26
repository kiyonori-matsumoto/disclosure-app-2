class Filter {
  bool isSelected;
  String title;

  Filter(this.title, {this.isSelected = false});

  toggle() {
    this.isSelected = !this.isSelected;
  }

  @override
  String toString() {
    return "$title $isSelected";
  }
}
