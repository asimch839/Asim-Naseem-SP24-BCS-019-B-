import '../models/user.dart';
import '../models/business_settings.dart';

class SampleData {
  static final BusinessSettings settings = BusinessSettings();

  static final List<AppUser> users = [
    AppUser(
      id: 'USR-001',
      name: 'Administrator',
      username: 'admin',
      phone: '0000-0000000',
      role: UserRole.owner,
      createdAt: DateTime.now(),
    ),
  ];
}
