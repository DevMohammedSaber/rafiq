import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq/main.dart';
import 'package:rafiq/features/auth/data/auth_repository.dart';
import 'package:rafiq/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:rafiq/features/profile/data/user_profile_repository.dart';
import 'package:rafiq/features/profile/presentation/cubit/settings_cubit.dart';
import 'package:rafiq/features/prayer/data/prayer_notification_service.dart';

// Simple Mocks
class MockAuthRepository extends AuthRepository {}

class MockUserProfileRepository extends UserProfileRepository {}

class MockPrayerNotificationService extends PrayerNotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<void> requestPermissions() async {}
}

class MockAuthCubit extends AuthCubit {
  MockAuthCubit(super.authRepository);
}

class MockSettingsCubit extends SettingsCubit {
  MockSettingsCubit(super.repository, super.notificationService);
}

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    final mockAuthRepo = MockAuthRepository();
    final mockUserProfileRepo = MockUserProfileRepository();
    final mockPrayerService = MockPrayerNotificationService();

    final mockAuthCubit = MockAuthCubit(mockAuthRepo);
    final mockSettingsCubit = MockSettingsCubit(
      mockUserProfileRepo,
      mockPrayerService,
    );

    await tester.pumpWidget(
      MuslimCompanionApp(
        authRepository: mockAuthRepo,
        userProfileRepository: mockUserProfileRepo,
        authCubit: mockAuthCubit,
        settingsCubit: mockSettingsCubit,
        prayerNotificationService: mockPrayerService,
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
