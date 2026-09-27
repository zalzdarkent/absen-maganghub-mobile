import '../../domain/models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/sqlite_database_service.dart';
import '../services/standalone_storage_service.dart';

class AuthRepository {
  final SqliteDatabaseService sqliteDatabaseService;
  final LocalStorageService localStorageService;
  final StandaloneStorageService standaloneStorageService;

  UserModel? _currentUser;

  AuthRepository({
    required this.sqliteDatabaseService,
    required this.localStorageService,
    required this.standaloneStorageService,
  });

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<UserModel?> checkSession() async {
    final activeId = await localStorageService.getActiveUserId();
    if (activeId == null) {
      _currentUser = null;
      standaloneStorageService.setActiveUserId(null);
      return null;
    }

    final user = await sqliteDatabaseService.getUserById(activeId);
    if (user != null) {
      _currentUser = user;
      standaloneStorageService.setActiveUserId(user.id);
      if (user.username.toLowerCase() == 'alif') {
        await sqliteDatabaseService.seedLogbookForUser(user.id);
      }
      return user;
    } else {
      await localStorageService.setActiveUserId(null);
      _currentUser = null;
      standaloneStorageService.setActiveUserId(null);
      return null;
    }
  }

  Future<UserModel> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final user = await sqliteDatabaseService.loginUser(
      usernameOrEmail: usernameOrEmail,
      password: password,
    );
    _currentUser = user;
    standaloneStorageService.setActiveUserId(user.id);
    await localStorageService.setActiveUserId(user.id);
    if (user.username.toLowerCase() == 'alif') {
      await sqliteDatabaseService.seedLogbookForUser(user.id);
    }
    return user;
  }

  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    String? name,
  }) async {
    final user = await sqliteDatabaseService.registerUser(
      username: username,
      email: email,
      password: password,
      name: name,
    );
    _currentUser = user;
    standaloneStorageService.setActiveUserId(user.id);
    await localStorageService.setActiveUserId(user.id);
    if (user.username.toLowerCase() == 'alif') {
      await sqliteDatabaseService.seedLogbookForUser(user.id);
    }
    return user;
  }

  Future<void> logout() async {
    _currentUser = null;
    standaloneStorageService.setActiveUserId(null);
    await localStorageService.setActiveUserId(null);
  }
}
