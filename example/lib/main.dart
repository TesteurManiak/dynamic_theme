import 'dart:math';

import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:example/theme.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
      onThemeModeChanged: (themeMode, fallbackBrightness) {
        switch (themeMode) {
          case ThemeMode.system:
            return AppTheme.fromBrightness(fallbackBrightness);
          case ThemeMode.light:
            return AppTheme.light;
          case ThemeMode.dark:
            return AppTheme.dark;
        }
      },
      themedWidgetBuilder: (context, mode, data) => MaterialApp(
        themeMode: mode,
        title: 'Flutter Demo',
        theme: data,
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Easy Theme'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => DynamicTheme.toggleThemeMode(context),
              child: const Text('Toggle brightness'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: changeColor,
              child: const Text('Change color'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showChooser,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_drive_file),
            label: 'Tab 1',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Tab 2',
          ),
        ],
      ),
    );
  }

  void showChooser() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return BrightnessSwitcherDialog(
          onSelectedTheme: (mode) => DynamicTheme.setThemeMode(context, mode),
        );
      },
    );
  }

  void changeColor() {
    final currentTheme = Theme.of(context);
    final color = randomColor();
    DynamicTheme.setThemeData(
      context,
      currentTheme.copyWith(
        colorScheme: currentTheme.colorScheme.copyWith(
          primary: color,
          secondary: color,
          tertiary: color,
        ),
      ),
    );
  }
}

Color randomColor() {
  final random = Random();
  return Color.fromRGBO(
    random.nextInt(256),
    random.nextInt(256),
    random.nextInt(256),
    1.0,
  );
}
