class ErrorItem {
  final String code;
  final String name;

  const ErrorItem({
    required this.code,
    required this.name,
  });

  @override
  String toString() => "$code - $name";
}
