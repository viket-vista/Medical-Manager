
import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'package:provider/provider.dart';
import 'models/settings_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsModel = SettingsModel();
  await settingsModel.init();
  runApp(ChangeNotifierProvider.value(
      value: settingsModel,
      child: MyApp(),
    ),);
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:  AllMHpage(),
      theme: settings.darkMode 
          ? ThemeData.dark() 
          : ThemeData.light(),
    );
  }
  
}