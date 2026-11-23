import 'package:flutter/material.dart';

/// Displays a Copy/Paste context menu on long-press or right-click,
/// with dynamically generated actions.
class DisplayContextMenu extends StatefulWidget {
  const DisplayContextMenu({
    super.key,
    required this.buttonItems,
    required this.child,
  });

  final List<ContextMenuButtonItem> Function() buttonItems;
  final Widget child;

  /// Closes any open menu, e.g. when a key is pressed.
  static void hide() => ContextMenuController.removeAny();

  @override
  State<DisplayContextMenu> createState() => _DisplayContextMenuState();
}

class _DisplayContextMenuState extends State<DisplayContextMenu> {
  final _menu = ContextMenuController();

  @override
  void dispose() {
    _menu.remove();
    super.dispose();
  }

  void _show(Offset position) {
    final items = widget.buttonItems();
    if (items.isEmpty) return;

    _menu.show(
      context: context,
      contextMenuBuilder: (context) => TapRegion(
        onTapOutside: (_) => _menu.remove(),
        child: TextSelectionToolbar(
          anchorAbove: position,
          anchorBelow: position,
          toolbarBuilder: (context, child) => Material(
            borderRadius: BorderRadius.circular(0),
            clipBehavior: Clip.antiAlias,
            elevation: 1,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: child,
          ),
          children: [
            for (final item in items)
              TextSelectionToolbarTextButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                onPressed: () {
                  _menu.remove();
                  item.onPressed?.call();
                },
                child: Text(
                  AdaptiveTextSelectionToolbar.getButtonLabel(context, item),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (details) => _show(details.globalPosition),
      onSecondaryTapUp: (details) => _show(details.globalPosition),
      child: widget.child,
    );
  }
}
