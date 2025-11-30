import 'package:pocketbase/pocketbase.dart';
import 'package:tareo/utils/date_utils.dart';
import 'activity_type_model.dart';
import 'user_model.dart';

class ActivityModel {
  final String id;
  final String userId;
  final DateTime started;
  final DateTime ended;
  final String typeId;
  final String description;

  // Expanded fields
  final ActivityTypeModel? type;
  final UserModel? user;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.started,
    required this.ended,
    required this.typeId,
    required this.description,
    this.type,
    this.user,
  });

  factory ActivityModel.fromRecord(RecordModel record) {
    ActivityTypeModel? type;
    final expandedType = record.get<List<RecordModel>>('expand.type', []);
    if (expandedType.isNotEmpty) {
      type = ActivityTypeModel.fromRecord(expandedType.first);
    }

    UserModel? user;
    final expandedUser = record.get<List<RecordModel>>('expand.user', []);
    if (expandedUser.isNotEmpty) {
      user = UserModel.fromRecord(expandedUser.first);
    }

    return ActivityModel(
      id: record.id,
      userId: record.getStringValue('user'),
      started: DateTime.parse(record.getStringValue('started')).toLocal(),
      ended: DateTime.parse(record.getStringValue('ended')).toLocal(),
      typeId: record.getStringValue('type'),
      description: record.getStringValue('description'),
      type: type,
      user: user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'started': formatDateTimeForPocketBase(started),
      'ended': formatDateTimeForPocketBase(ended),
      'type': typeId,
      'description': description,
    };
  }
}
