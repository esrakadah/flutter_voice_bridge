import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_bridge/core/branding/branding_cubit.dart';
import 'package:flutter_voice_bridge/core/branding/branding_model.dart';
import 'package:flutter_voice_bridge/core/branding/branding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('BrandingConfig', () {
    test('defaults to event mode off with no city, year or flag', () {
      const config = BrandingConfig();
      expect(config.isEventMode, isFalse);
      expect(config.title, 'DevFest');
      expect(config.year, isEmpty);
      expect(config.flag, isNull);
    });

    test('title skips empty parts', () {
      expect(const BrandingConfig(eventName: '', location: 'Berlin').title, 'Berlin');
      expect(const BrandingConfig(location: 'Berlin').title, 'DevFest Berlin');
    });

    test('copyWith can remove the flag', () {
      const config = BrandingConfig(flag: '🇩🇪');
      expect(config.copyWith(flag: () => null).flag, isNull);
      expect(config.copyWith(year: '2026').flag, '🇩🇪');
    });

    test('survives a JSON round trip', () {
      const config = BrandingConfig(isEventMode: true, location: 'Adana', year: '2026', flag: '🇹🇷');
      expect(BrandingConfig.fromJson(config.toJson()), config);
    });
  });

  group('BrandingCubit', () {
    blocTest<BrandingCubit, BrandingConfig>(
      'persists changes so a new cubit loads them',
      build: () => BrandingCubit(repository: BrandingRepository()),
      act: (cubit) async {
        await cubit.toggleEventMode(true);
        await cubit.updateEventDetails(location: 'Adana', year: '2026', flag: '🇹🇷');
      },
      verify: (_) async {
        final reloaded = BrandingCubit(repository: BrandingRepository());
        await reloaded.load();
        expect(
          reloaded.state,
          const BrandingConfig(isEventMode: true, location: 'Adana', year: '2026', flag: '🇹🇷'),
        );
      },
    );

    blocTest<BrandingCubit, BrandingConfig>(
      'an empty flag field removes the flag',
      build: () => BrandingCubit(repository: BrandingRepository()),
      seed: () => const BrandingConfig(flag: '🇩🇪'),
      act: (cubit) => cubit.updateEventDetails(flag: '  '),
      verify: (cubit) => expect(cubit.state.flag, isNull),
    );

    test('ignores unreadable saved data', () async {
      SharedPreferences.setMockInitialValues({'branding_config': 'not json'});
      expect(await BrandingRepository().load(), const BrandingConfig());
    });
  });
}
