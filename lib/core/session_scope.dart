import 'package:flutter/material.dart';

class SessionScope extends InheritedNotifier<ValueNotifier<int>> {
  const SessionScope({
    super.key,
    required ValueNotifier<int> notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static ValueNotifier<int> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope nedostaje u widget tree');
    return scope!.notifier!;
  }
}