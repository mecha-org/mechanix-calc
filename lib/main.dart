import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_calculator/l10n/app_localizations.dart';
import 'package:mechanix_common/mechanix_common.dart';
import 'package:show_fps/show_fps.dart';
import 'package:widgets/widgets.dart';

import 'features/calculator/bloc/calculator_bloc.dart';
import 'features/calculator/presentation/screens/calculator_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MechanixApp.registerSingleton('mechanix_calculator', (_) {
    // Single instance activation handler (no arguments required for calc)
  });
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final showFps =
        Platform.environment['SHOW_FPS'] == 'true' ||
        const String.fromEnvironment('SHOW_FPS') == 'true';

    return MechanixTheme(
      builder: (context, theme, child) {
        final darkTheme = theme.dark;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Calculator',
          theme: darkTheme,
          darkTheme: darkTheme,
          themeMode: theme.mode,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: showFps
              ? (context, child) {
                  return ShowFPS(
                    visible: showFps,
                    showChart: false,
                    child: child!,
                  );
                }
              : null,
          home: BlocProvider(
            create: (context) => CalculatorBloc(),
            child: const CalculatorScreen(),
          ),
        );
      },
    );
  }
}
