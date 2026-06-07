// Read-only board timeline view that places all dated cards on a due-date grid
// and groups undated cards separately.
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/board/board_entities.dart';
import '../../../domain/board/board_timeline.dart';
import 'board_gantt_styles.dart';

class BoardGanttView extends StatelessWidget {
  const BoardGanttView({
    super.key,
    required this.columns,
    required this.onOpenItem,
  });
  static const double _labelWidth = 250;
  static const double _dayWidth = 84;

  final List<BoardColumn> columns;
  final ValueChanged<String> onOpenItem;

  @override
  Widget build(BuildContext context) {
    final timeline = BoardTimeline.fromColumns(columns);

    if (timeline.isEmpty) {
      return const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('No cards to show on the timeline.'),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: <Widget>[
            for (var index = 0; index < columns.length; index++)
              _BoardGanttLegendEntry(
                columnId: columns[index].id,
                title: columns[index].menuTitle,
                style: BoardGanttStyleResolver.resolve(index),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (timeline.datedEntries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No dated cards to place on the timeline yet.'),
            ),
          )
        else
          _buildTimeline(context, timeline.datedEntries),
        if (timeline.undatedEntries.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Text('No due date', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...timeline.undatedEntries.map(
            (entry) => _buildUndatedCard(context, entry),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    List<BoardTimelineEntry> entries,
  ) {
    final firstDate = _startOfDay(entries.first.effectiveStartDate!);
    final lastDate = entries
        .map((BoardTimelineEntry entry) => _startOfDay(entry.effectiveEndDate!))
        .reduce(
          (DateTime left, DateTime right) => left.isAfter(right) ? left : right,
        );
    final dayCount = lastDate.difference(firstDate).inDays + 1;
    final timelineWidth = dayCount * _dayWidth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _labelWidth + timelineWidth,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                const SizedBox(width: _labelWidth),
                for (var dayIndex = 0; dayIndex < dayCount; dayIndex++)
                  SizedBox(
                    width: _dayWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        TodoDateFormatter.format(
                          firstDate.add(Duration(days: dayIndex)),
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
              ],
            ),
            for (final entry in entries)
              _buildTimelineRow(context, entry, firstDate, dayCount),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(
    BuildContext context,
    BoardTimelineEntry entry,
    DateTime firstDate,
    int dayCount,
  ) {
    final offset = _startOfDay(
      entry.effectiveStartDate!,
    ).difference(firstDate).inDays;
    final width = (entry.effectiveDurationInDays! * _dayWidth) - 16.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: _labelWidth,
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(right: 12),
              title: Text(
                entry.item.displayTitle,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Row(
                children: <Widget>[
                  BoardGanttSwatch(style: _styleFor(entry)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.columnTitle,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              onTap: () => onOpenItem(entry.item.id),
            ),
          ),
          SizedBox(
            width: dayCount * _dayWidth,
            height: 56,
            child: Stack(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    for (var index = 0; index < dayCount; index++)
                      Container(
                        width: _dayWidth,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSoft,
                          border: Border.all(color: AppTheme.outline),
                        ),
                      ),
                  ],
                ),
                Positioned(
                  left: (offset * _dayWidth) + 8,
                  top: 8,
                  width: width,
                  bottom: 8,
                  child: BoardGanttMarker(
                    key: ValueKey<String>('marker-${entry.item.id}'),
                    itemId: entry.item.id,
                    style: _styleFor(entry),
                    onTap: () => onOpenItem(entry.item.id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUndatedCard(BuildContext context, BoardTimelineEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: SizedBox(
            width: 36,
            height: 36,
            child: BoardGanttMarker(
              key: ValueKey<String>('marker-${entry.item.id}'),
              itemId: entry.item.id,
              style: _styleFor(entry),
              onTap: () => onOpenItem(entry.item.id),
            ),
          ),
          title: Text(entry.item.displayTitle),
          subtitle: Row(
            children: <Widget>[
              BoardGanttSwatch(style: _styleFor(entry)),
              const SizedBox(width: 8),
              Expanded(child: Text(entry.columnTitle)),
            ],
          ),
          onTap: () => onOpenItem(entry.item.id),
        ),
      ),
    );
  }

  BoardGanttStyle _styleFor(BoardTimelineEntry entry) {
    return BoardGanttStyleResolver.resolve(entry.columnIndex);
  }
}

class _BoardGanttLegendEntry extends StatelessWidget {
  const _BoardGanttLegendEntry({
    required this.columnId,
    required this.title,
    required this.style,
  });

  final String columnId;
  final String title;
  final BoardGanttStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BoardGanttSwatch(
              key: ValueKey<String>('legend-swatch-$columnId'),
              style: style,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
      ),
    );
  }
}

DateTime _startOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
