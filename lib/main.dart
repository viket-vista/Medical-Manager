import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'package:provider/provider.dart';
import 'models/settings_model.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsModel = SettingsModel();
  await settingsModel.init();
  initializeDateFormatting().then((_) => runApp(ChangeNotifierProvider.value(value: settingsModel, child: MyApp())));
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const _defaultColorSeed = Colors.blueAccent;
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // 亮色模式 Monet 取色
          lightColorScheme = lightDynamic.harmonized();
          // 暗色模式 Monet 取色
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // Fallback 颜色，当不支持 Monet 取色的时候使用
          lightColorScheme = ColorScheme.fromSeed(seedColor: _defaultColorSeed);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: _defaultColorSeed,
            brightness: Brightness.dark,
          );
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh', 'CN'),
            localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate, // 如果使用了Cupertino组件
  ],
          home: AllMHpage(),
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            colorScheme: lightColorScheme,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
              },
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            colorScheme: darkColorScheme,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
              },
            ),
          ),
          themeMode: settings.autoDarkMode
              ? ThemeMode.system
              : settings.darkMode
              ? ThemeMode.dark
              : ThemeMode.light,
        );
      },
    );
  }
}
