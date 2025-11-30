import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  final UserModel? user;

  const UserAvatar({super.key, this.radius = 20, this.user});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = user ?? authService.currentUser;

    if (currentUser == null) {
      return CircleAvatar(radius: radius, child: const Icon(Icons.person));
    }

    if (currentUser.avatar != null && currentUser.avatar!.isNotEmpty) {
      // Construct the URL manually since we don't have the RecordModel handy
      // and we know the collection is 'users'
      final baseUrl = authService.pb.baseURL;
      final avatarUrl =
          '$baseUrl/api/files/users/${currentUser.id}/${currentUser.avatar}';

      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          child: Image.network(
            avatarUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.person, size: radius);
            },
          ),
        ),
      );
    }

    return CircleAvatar(radius: radius, child: const Icon(Icons.person));
  }
}
