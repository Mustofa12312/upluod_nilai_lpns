class StudentUjianAkhir {
  final int id;
  final String name;
  final int classId;

  StudentUjianAkhir({
    required this.id,
    required this.name,
    required this.classId,
  });

  factory StudentUjianAkhir.fromJson(Map<String, dynamic> json) {
    return StudentUjianAkhir(
      id: json['id'],
      name: json['name'],
      classId: json['class_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'class_id': classId};
  }
}
