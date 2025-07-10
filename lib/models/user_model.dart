class AppUser {
  final String id;
  final String fullName;
  final String userName;
  final String email;
  final String role;

  AppUser({
    required this.id,
    required this.fullName,
    required this.userName,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      fullName: json['fullName'] ?? "",
      userName: json['userName'] ?? "",
      email: json['email'] ?? "",
      role: json['role'] ?? "USER",
    );
  }
}
