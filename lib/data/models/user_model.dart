class UserModel {
  final int? id;
  final String username;
  final String encryptedPassword;

  const UserModel({
    this.id,
    required this.username,
    required this.encryptedPassword,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'encrypted_password': encryptedPassword,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as int?,
        username: map['username'] as String,
        encryptedPassword: map['encrypted_password'] as String,
      );
}
