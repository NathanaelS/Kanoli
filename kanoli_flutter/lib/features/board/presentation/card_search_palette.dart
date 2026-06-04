// Command-palette UI for active-board card search.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/board/board_entities.dart';
import '../application/card_search.dart';

class CardSearchPalette extends StatefulWidget {
  const CardSearchPalette({
    super.key,
    required this.columns,
    required this.openBoards,
    required this.todoTextByCardId,
    required this.onSelected,
  });

  final List<BoardColumn> columns;
  final List<CardSearchBoard> openBoards;
  final Map<String, List<String>> todoTextByCardId;
  final ValueChanged<CardSearchResult> onSelected;

  @override
  State<CardSearchPalette> createState() => _CardSearchPaletteState();
}

class _CardSearchPaletteState extends State<CardSearchPalette> {
  final TextEditingController _queryController = TextEditingController();
  CardSearchScope _scope = CardSearchScope.currentBoard;
  int _selectedIndex = 0;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          _moveSelection(1, results.length);
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          _moveSelection(-1, results.length);
        },
        const SingleActivator(LogicalKeyboardKey.enter): () {
          _selectCurrent(results);
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).maybePop();
        },
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _queryController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search cards',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (_) {
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                  onSubmitted: (_) => _selectCurrent(_results()),
                ),
                const SizedBox(height: 10),
                SegmentedButton<CardSearchScope>(
                  segments: const <ButtonSegment<CardSearchScope>>[
                    ButtonSegment<CardSearchScope>(
                      value: CardSearchScope.currentBoard,
                      label: Text('Current Board'),
                    ),
                    ButtonSegment<CardSearchScope>(
                      value: CardSearchScope.allOpenBoards,
                      label: Text('All Open Boards'),
                    ),
                  ],
                  selected: <CardSearchScope>{_scope},
                  onSelectionChanged: (Set<CardSearchScope> selected) {
                    setState(() {
                      _scope = selected.single;
                      _selectedIndex = 0;
                    });
                  },
                ),
                const SizedBox(height: 10),
                const _SearchExamples(),
                const SizedBox(height: 12),
                Flexible(child: _resultsBody(results)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultsBody(List<CardSearchResult> results) {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      return const _PaletteEmptyState(
        icon: Icons.keyboard_command_key,
        message: 'Start typing to search cards.',
      );
    }

    if (results.isEmpty) {
      return const _PaletteEmptyState(
        icon: Icons.search_off,
        message: 'No matching cards.',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: results.length,
      itemBuilder: (BuildContext context, int index) {
        final result = results[index];
        final selected = index == _selectedIndex;

        return Card(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            key: ValueKey<String>('card-search-result-${result.itemId}'),
            selected: selected,
            title: Text(result.title),
            subtitle: Text(_resultSubtitle(result)),
            trailing: Wrap(
              spacing: 6,
              children: result.matchKinds.map(_matchChip).toList(),
            ),
            onTap: () => _select(result),
          ),
        );
      },
    );
  }

  Widget _matchChip(CardSearchMatchKind kind) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(_matchLabel(kind)),
    );
  }

  List<CardSearchResult> _results() {
    if (_scope == CardSearchScope.allOpenBoards) {
      return searchOpenBoardCards(
        boards: widget.openBoards,
        query: _queryController.text,
        todoTextByCardId: widget.todoTextByCardId,
      );
    }

    return searchBoardCards(
      columns: widget.columns,
      query: _queryController.text,
      todoTextByCardId: widget.todoTextByCardId,
    );
  }

  String _resultSubtitle(CardSearchResult result) {
    final boardTitle = result.boardTitle;
    if (_scope == CardSearchScope.allOpenBoards &&
        boardTitle != null &&
        boardTitle.trim().isNotEmpty) {
      return '$boardTitle / ${result.columnTitle}';
    }
    return result.columnTitle;
  }

  void _moveSelection(int direction, int resultCount) {
    if (resultCount == 0) {
      return;
    }

    setState(() {
      _selectedIndex = (_selectedIndex + direction) % resultCount;
      if (_selectedIndex < 0) {
        _selectedIndex = resultCount - 1;
      }
    });
  }

  void _selectCurrent(List<CardSearchResult> results) {
    if (results.isEmpty) {
      return;
    }
    _select(results[_selectedIndex.clamp(0, results.length - 1)]);
  }

  void _select(CardSearchResult result) {
    Navigator.of(context).pop();
    widget.onSelected(result);
  }

  String _matchLabel(CardSearchMatchKind kind) {
    switch (kind) {
      case CardSearchMatchKind.title:
        return 'Title';
      case CardSearchMatchKind.label:
        return 'Label';
      case CardSearchMatchKind.dueDate:
        return 'Date';
      case CardSearchMatchKind.checklist:
        return 'Checklist';
      case CardSearchMatchKind.note:
        return 'Note';
      case CardSearchMatchKind.todo:
        return 'Todo';
    }
  }
}

enum CardSearchScope { currentBoard, allOpenBoards }

class _SearchExamples extends StatelessWidget {
  const _SearchExamples();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text('Try:', style: style),
          const _ExampleChip(text: 'title text'),
          const _ExampleChip(text: '+urgent'),
          const _ExampleChip(text: 'due:2026-06-14'),
          const _ExampleChip(text: 'note text'),
          const _ExampleChip(text: 'checklist item'),
          const _ExampleChip(text: 'todo text'),
        ],
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(visualDensity: VisualDensity.compact, label: Text(text));
  }
}

class _PaletteEmptyState extends StatelessWidget {
  const _PaletteEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 36),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }
}
