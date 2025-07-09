import 'package:flutter/material.dart';
import 'app.dart';
import 'di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  await DependencyInjection.init();

  runApp(const App());
}
