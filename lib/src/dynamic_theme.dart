import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef ThemedWidgetBuilder = Widget Function(
  BuildContext context,
  ThemeData themeData,
);

typedef ThemeModeChangedCallback = ThemeData Function(
  ThemeMode themeMode,
  Brightness fallbackBrightness,
);

/// Creates a widget that applies a theme to a child widget. You can change the
/// theme by calling `setThemeMode`.
class DynamicTheme extends StatefulWidget {
  const DynamicTheme({
    super.key,
    required this.themedWidgetBuilder,
    this.onThemeModeChanged,
    this.defaultThemeMode = ThemeMode.system,
    this.loadThemeOnStart = true,
  });

  /// Builder that gets called when the theme changes.
  final ThemedWidgetBuilder themedWidgetBuilder;

  /// Method called each time the [ThemeMode] changes. You can use it to return
  /// custom [ThemeData] depending of the [ThemeMode].
  final ThemeModeChangedCallback? onThemeModeChanged;

  /// The default theme on start.
  ///
  /// Defaults to `ThemeMode.system`.
  final ThemeMode defaultThemeMode;

  /// Whether or not to load the theme on start.
  ///
  /// Defaults to `true`
  final bool loadThemeOnStart;

  @override
  DynamicThemeState createState() => DynamicThemeState();

  /// Return the nearest instance of [DynamicThemeState] in the widget tree.
  static DynamicThemeState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_DynamicTheme>();
    return scope!._state;
  }

  /// Return the nearest instance of [DynamicThemeState] in the widget tree.
  ///
  /// If no instance was found returns null.
  static DynamicThemeState? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_DynamicTheme>();
    return scope?._state;
  }

  /// Changes the theme using the provided [theme].
  static void setThemeData(BuildContext context, ThemeData theme) =>
      DynamicTheme.maybeOf(context)?._themeData.value = theme;

  /// Toggles [ThemeMode.light] to [ThemeMode.dark] and vice versa.
  ///
  /// If the current theme is [ThemeMode.system], it will be set to
  /// [ThemeMode.light] or [ThemeMode.dark] depending on the current system
  /// brightness.
  static FutureOr<void> toggleThemeMode(BuildContext context) =>
      DynamicTheme.maybeOf(context)?._toggleThemeMode();

  static FutureOr<void> setThemeMode(BuildContext context, ThemeMode mode) =>
      DynamicTheme.maybeOf(context)?._setThemeMode(mode);
}

class DynamicThemeState extends State<DynamicTheme> {
  static const _sharedPreferencesKey = 'themeMode';

  late final _fallbackBrightness =
      SchedulerBinding.instance.window.platformBrightness;
  late final _shouldLoadThemeMode = widget.loadThemeOnStart;
  late final _themeMode = ValueNotifier<ThemeMode>(widget.defaultThemeMode);
  late final _themeData = ValueNotifier<ThemeData>(
    widget.onThemeModeChanged?.call(themeMode, _fallbackBrightness) ??
        _getThemeFromBrightness(_fallbackBrightness),
  );

  /// Get the current `ThemeMode`.
  ThemeMode get themeMode => _themeMode.value;

  /// Get the current `ThemeData`
  ThemeData get themeData => _themeData.value;

  SharedPreferences? _prefs;
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.onThemeModeChanged != null) {
      _themeData.value =
          widget.onThemeModeChanged!.call(themeMode, themeData.brightness);
    }
  }

  @override
  void didUpdateWidget(DynamicTheme oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onThemeModeChanged != null) {
      _themeData.value = widget.onThemeModeChanged!.call(
        themeMode,
        themeData.brightness,
      );
    }
  }

  @override
  void dispose() {
    _themeMode.dispose();
    _themeData.dispose();
    super.dispose();
  }

  /// Sets the new theme.
  Future<void> _setThemeMode(ThemeMode themeMode) {
    // Update state with new values
    if (widget.onThemeModeChanged != null) {
      _themeData.value =
          widget.onThemeModeChanged!.call(themeMode, themeData.brightness);
    }
    _themeMode.value = themeMode;
    return _saveThemeMode(themeMode);
  }

  Future<void> _toggleThemeMode() {
    switch (_themeMode.value) {
      case ThemeMode.system:
        // If brightness is dark, set it to light
        // If it's not dark, set it to dark
        if (_fallbackBrightness == Brightness.dark) {
          return _setThemeMode(ThemeMode.light);
        } else {
          return _setThemeMode(ThemeMode.dark);
        }
      case ThemeMode.light:
        return _setThemeMode(ThemeMode.dark);
      case ThemeMode.dark:
        return _setThemeMode(ThemeMode.light);
    }
  }

  /// Saves the provided themeMode in [SharedPreferences].
  Future<void> _saveThemeMode(ThemeMode themeMode) async {
    //! Shouldn't save the themeMode if you don't want to load it
    if (!_shouldLoadThemeMode) return;
    await (await prefs).setString(_sharedPreferencesKey, themeMode.string);
  }

  /// Returns a [ThemeMode] that gives you the latest brightness.
  Future<ThemeMode> _getThemeMode() async {
    // Gets the ThemeMode stored in prefs or returns the [defaultThemeMode].
    return (await prefs).getString(_sharedPreferencesKey)?.toThemeMode() ??
        widget.defaultThemeMode;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, mode, _) => ValueListenableBuilder<ThemeData>(
        valueListenable: _themeData,
        builder: (context, theme, _) => _DynamicTheme(
          state: this,
          child: widget.themedWidgetBuilder(context, theme),
        ),
      ),
    );
  }

  /// Loads the theme depending on the `loadThemeOnStart` value.
  Future<void> _loadThemeMode() async {
    if (!_shouldLoadThemeMode) return;
    final myThemeMode = await _getThemeMode();
    _themeMode.value = myThemeMode;
    if (widget.onThemeModeChanged != null) {
      _themeData.value =
          widget.onThemeModeChanged!.call(themeMode, themeData.brightness);
    }
  }

  ThemeData _getThemeFromBrightness(Brightness brightness) {
    switch (brightness) {
      case Brightness.light:
        return ThemeData.light();
      case Brightness.dark:
        return ThemeData.dark();
    }
  }
}

class _DynamicTheme extends InheritedWidget {
  final DynamicThemeState _state;

  const _DynamicTheme({
    required super.child,
    required DynamicThemeState state,
  }) : _state = state;

  DynamicTheme get widget => _state.widget;

  @override
  bool updateShouldNotify(_DynamicTheme oldWidget) => true;
}

extension on ThemeMode {
  String get string => toString().split('.').last;
}

extension on String {
  ThemeMode toThemeMode() {
    switch (this) {
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        throw Exception('Unknown theme mode: $this');
    }
  }
}
