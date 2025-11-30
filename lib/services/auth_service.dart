import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  static const String _baseUrl = 'https://tareo.patito.lat';
  static const String _authKey = 'pb_auth';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late PocketBase _pb;
  UserModel? _currentUser;
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _pb.authStore.isValid;
  PocketBase get pb => _pb;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    final authData = await _storage.read(key: _authKey);

    final store = AsyncAuthStore(
      save: (String data) async {
        await _storage.write(key: _authKey, value: data);
      },
      initial: authData,
    );

    _pb = PocketBase(_baseUrl, authStore: store);

    if (_pb.authStore.isValid) {
      try {
        // Refresh the token to ensure it's valid and get up-to-date user data
        await _pb.collection('users').authRefresh();
        _updateCurrentUser();
      } catch (e) {
        // If refresh fails, clear auth
        _pb.authStore.clear();
        await _storage.delete(key: _authKey);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void _updateCurrentUser() {
    if (_pb.authStore.record != null && _pb.authStore.record is RecordModel) {
      _currentUser = UserModel.fromRecord(_pb.authStore.record as RecordModel);
    } else {
      _currentUser = null;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _pb.collection('users').authWithPassword(email, password);
      _updateCurrentUser();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _pb.authStore.clear();
    await _storage.delete(key: _authKey);
    _currentUser = null;
    notifyListeners();
  }
}
