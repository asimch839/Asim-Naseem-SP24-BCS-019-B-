import 'dart:typed_data';

class UserModel {
  final String id;
  String name;
  String email;
  String? phoneNumber;
  String? username;
  Uint8List? profilePic;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.username,
    this.profilePic,
  });
}
