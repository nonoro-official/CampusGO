class SchoolIdModel {
  final String id;
  final bool isUsed;
  final String? usedBy;

  SchoolIdModel({
    required this.id,
    required this.isUsed,
    this.usedBy,
  });

  factory SchoolIdModel.fromMap(Map<String, dynamic> data, String id) {
    return SchoolIdModel(
      id: id,
      isUsed: data['isUsed'] ?? false,
      usedBy: data['usedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isUsed': isUsed,
      'usedBy': usedBy,
    };
  }
}
