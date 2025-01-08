class UserModel {
  final String uid;
  final String email;
  final String userType; // 'patient', 'doctor', 'admin'
  final DateTime createdAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.userType,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      userType: json['userType'],
      createdAt: json['createdAt'].toDate(),
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'userType': userType,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}