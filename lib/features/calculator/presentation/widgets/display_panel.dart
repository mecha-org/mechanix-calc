import 'package:flutter/material.dart';
import 'package:mechanix_calculator/l10n/app_localizations.dart';
import 'package:widgets/widgets.dart';
import '../../bloc/calculator_state.dart';

class DisplayPanel extends StatefulWidget {
  final String expression;
  final String result;
  final String errorMessage;
  final List<HistoryItem> history;
  final bool isHistoryOpen;
  final ValueChanged<String>? onHistoryItemTap;
  final VoidCallback? onDismissHistory;

  const DisplayPanel({
    super.key,
    required this.expression,
    required this.result,
    required this.errorMessage,
    this.history = const [],
    this.isHistoryOpen = false,
    this.onHistoryItemTap,
    this.onDismissHistory,
  });

  @override
  State<DisplayPanel> createState() => _DisplayPanelState();
}

class _DisplayPanelState extends State<DisplayPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String topExpression;
    final String bottomText;

    if (widget.errorMessage.isNotEmpty) {
      topExpression = widget.expression;
      bottomText =
          l10n?.errorMessage(widget.errorMessage) ?? widget.errorMessage;
    } else if (widget.expression.isNotEmpty) {
      topExpression = '';
      bottomText = widget.expression;
    } else if (widget.history.isNotEmpty &&
        widget.history.first.result == widget.result) {
      topExpression = widget.history.first.expression;
      bottomText = widget.result.isNotEmpty ? widget.result : '0';
    } else {
      topExpression = '';
      bottomText = widget.result.isNotEmpty ? widget.result : '0';
    }

    final displayContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (topExpression.isNotEmpty && !widget.isHistoryOpen) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                topExpression,
                textAlign: TextAlign.end,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontFamily: MechanixFontFamily.geistMono,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              bottomText,
              textAlign: TextAlign.end,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: Theme.of(
                context,
              ).textTheme.displayMedium!.copyWith(fontFamily: 'GeistMono'),
            ),
          ),
        ],
      ),
    );

    if (widget.isHistoryOpen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: HistoryOverlay(
              history: widget.history,
              onHistoryItemTap: widget.onHistoryItemTap,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: widget.onDismissHistory,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 64),
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  reverse: true,
                  child: displayContent,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onDismissHistory,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          reverse: true,
          child: displayContent,
        ),
      ),
    );
  }
}

class HistoryOverlay extends StatelessWidget {
  final List<HistoryItem> history;
  final ValueChanged<String>? onHistoryItemTap;

  const HistoryOverlay({
    super.key,
    required this.history,
    this.onHistoryItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = history.reversed.toList();

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _HistoryTile(item: item, onTap: onHistoryItemTap);
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryItem item;
  final ValueChanged<String>? onTap;

  const _HistoryTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleSmall!.copyWith(
      fontFamily: MechanixFontFamily.geistMono,
      fontSize: 18,
      color: Theme.of(context).colorScheme.onSecondaryContainer,
    );

    return InkWell(
      onTap: () => onTap?.call(item.expression),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                item.expression,
                textAlign: TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('=', style: textStyle.copyWith(fontSize: 24)),
            ),
            Expanded(
              flex: 2,
              child: Text(
                item.result,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: textStyle.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
