class UserProfile {
  String name;
  String campus;
  String studyProgram;
  int semester;

  UserProfile({
    this.name = 'Mahasiswa Juara',
    this.campus = 'Universitas Indonesia',
    this.studyProgram = 'Teknik Informatika',
    this.semester = 5,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'campus': campus,
      'studyProgram': studyProgram,
      'semester': semester,
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      name: map['name'] as String? ?? 'Mahasiswa Juara',
      campus: map['campus'] as String? ?? '',
      studyProgram: map['studyProgram'] as String? ?? '',
      semester: map['semester'] as int? ?? 1,
    );
  }
}

