
class AuthUser {
  final String id;
  final String number;
  final bool allowed;

  const AuthUser({
    required this.id,
    required this.number,
    required this.allowed,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
      allowed: json['allowed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'allowed': allowed,
    };
  }
}
