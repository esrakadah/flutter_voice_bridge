import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_bridge/core/branding/branding_cubit.dart';
import 'package:flutter_voice_bridge/core/branding/branding_model.dart';
import 'package:flutter_voice_bridge/core/theme/theme_provider.dart';
import 'package:flutter_voice_bridge/ui/views/home/home_cubit.dart';
import 'package:flutter_voice_bridge/ui/views/home/home_state.dart';
import 'package:flutter_voice_bridge/ui/views/home_view.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockBrandingCubit extends MockCubit<BrandingConfig> implements BrandingCubit {}

void main() {
  late MockHomeCubit homeCubit;
  late ThemeCubit themeCubit;
  late MockBrandingCubit brandingCubit;

  setUp(() {
    homeCubit = MockHomeCubit();
    themeCubit = ThemeCubit();
    brandingCubit = MockBrandingCubit();
    when(() => brandingCubit.state).thenReturn(const BrandingConfig());
    when(() => homeCubit.state).thenReturn(const HomeState());
    when(() => homeCubit.startRecording()).thenAnswer((_) async {});
  });

  tearDown(() => themeCubit.close());

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>.value(value: themeCubit),
          BlocProvider<BrandingCubit>.value(value: brandingCubit),
          BlocProvider<HomeCubit>.value(value: homeCubit),
        ],
        child: const MaterialApp(home: HomeViewContent()),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the empty state when there are no recordings', (tester) async {
    await pumpHome(tester);

    expect(find.text('No recordings yet'), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsWidgets);
  });

  testWidgets('tapping the record button starts a recording', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    verify(() => homeCubit.startRecording()).called(1);
  });

  testWidgets('event mode shows the event title, year and flag in the app bar', (tester) async {
    when(() => brandingCubit.state).thenReturn(
      const BrandingConfig(isEventMode: true, location: 'Adana', year: '2026', flag: '🇹🇷'),
    );
    await pumpHome(tester);

    expect(find.text('DevFest Adana'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('🇹🇷'), findsOneWidget);
  });
}
