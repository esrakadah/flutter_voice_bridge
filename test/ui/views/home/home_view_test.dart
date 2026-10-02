import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voice_bridge/core/theme/theme_provider.dart';
import 'package:flutter_voice_bridge/ui/views/home/home_cubit.dart';
import 'package:flutter_voice_bridge/ui/views/home/home_state.dart';
import 'package:flutter_voice_bridge/ui/views/home_view.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

void main() {
  late MockHomeCubit homeCubit;
  late ThemeCubit themeCubit;

  setUp(() {
    homeCubit = MockHomeCubit();
    themeCubit = ThemeCubit();
    when(() => homeCubit.state).thenReturn(const HomeInitial());
    when(() => homeCubit.startRecording()).thenAnswer((_) async {});
  });

  tearDown(() => themeCubit.close());

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>.value(value: themeCubit),
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
}
