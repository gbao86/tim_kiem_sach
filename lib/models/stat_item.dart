class StatItem {
  final String name;
  final int count;

  StatItem({
    required this.name,
    required this.count,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'count': count,
    };
  }

  factory StatItem.fromMap(Map<String, dynamic> map) {
    return StatItem(
      name: map['name'] as String,
      count: map['count'] as int,
    );
  }
}