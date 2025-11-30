import 'package:pocketbase/pocketbase.dart';

class OperationModel {
  final String id;
  final String name;

  OperationModel({required this.id, required this.name});

  factory OperationModel.fromRecord(RecordModel record) {
    return OperationModel(id: record.id, name: record.getStringValue('name'));
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  @override
  String toString() => name;
}
