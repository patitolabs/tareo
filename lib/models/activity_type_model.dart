import 'package:pocketbase/pocketbase.dart';

class ActivityTypeModel {
  final String id;
  final String name;

  ActivityTypeModel({required this.id, required this.name});

  factory ActivityTypeModel.fromRecord(RecordModel record) {
    return ActivityTypeModel(
      id: record.id,
      name: record.getStringValue('name'),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  @override
  String toString() => name;
}
