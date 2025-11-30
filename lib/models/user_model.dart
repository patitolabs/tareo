import 'package:pocketbase/pocketbase.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String operationId;
  final String? operationName;
  final String? avatar;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.operationId,
    this.operationName,
    this.avatar,
  });

  factory UserModel.fromRecord(RecordModel record) {
    String? opName;
    final expandedOperation = record.get<List<RecordModel>>(
      'expand.operation',
      [],
    );
    if (expandedOperation.isNotEmpty) {
      opName = expandedOperation.first.getStringValue('name');
    }

    return UserModel(
      id: record.id,
      email: record.getStringValue('email'),
      name: record.getStringValue('name'),
      role: record.getStringValue('role'),
      operationId: record.getStringValue('operation'),
      operationName: opName,
      avatar: record.getStringValue('avatar'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'operation': operationId,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isTechnician => role == 'technician';
}
