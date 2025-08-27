import 'package:flutter/widgets.dart';

/// Links multiple [ScrollController]s so they stay in sync.
class LinkedScrollControllerGroup {
  final _controllers = <ScrollController>[];
  bool _syncing = false;

  /// Adds a new controller to the group and returns it.
  ScrollController addAndGet() {
    // Disable keepScrollOffset so controllers don't read/write values
    // from PageStorage. This avoids type cast issues when an ancestor
    // uses the same [PageStorageKey] for unrelated state like
    // [ExpansionTile]'s expansion boolean.
    final controller = ScrollController(keepScrollOffset: false);
    _controllers.add(controller);
    controller.addListener(() {
      if (_syncing) return;
      if (!controller.hasClients) return;
      _syncing = true;
      for (final other in _controllers) {
        if (identical(other, controller)) continue;
        if (!other.hasClients) continue;
        other.jumpTo(controller.offset);
      }
      _syncing = false;
    });
    return controller;
  }

  /// Dispose all linked controllers.
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
  }
}
