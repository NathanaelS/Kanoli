import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/board/todo_board_store.dart';
import '../../../domain/board/board_entities.dart';

class ItemEditorSheet extends StatefulWidget {
  const ItemEditorSheet({
    super.key,
    required this.item,
    required this.boardFilePath,
    required this.columnTitle,
    required this.allColumns,
    required this.onOpenItem,
    required this.onSave,
  });

  final BoardItem item;
  final String? boardFilePath;
  final String? columnTitle;
  final List<BoardColumn> allColumns;
  final ValueChanged<String> onOpenItem;
  final ValueChanged<BoardItem> onSave;

  @override
  State<ItemEditorSheet> createState() => _ItemEditorSheetState();
}

class _ItemEditorSheetState extends State<ItemEditorSheet> {
  final TodoBoardStore _todoStore = TodoBoardStore();

  late BoardItem _draft;
  late List<BoardNote> _notes;
  late List<BoardChecklist> _checklists;

  String? _selectedLabelFilter;

  String? _todoListPath;
  List<TodoListEntry> _todoItems = <TodoListEntry>[];
  List<String> _otherTodoLines = <String>[];
  final TextEditingController _todoAddController = TextEditingController();
  final TextEditingController _labelsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _draft = BoardItem(
      id: widget.item.id,
      title: widget.item.title,
      notes: List<BoardNote>.from(widget.item.notes),
      checklists: List<BoardChecklist>.from(widget.item.checklists),
      dueDate: widget.item.dueDate,
      priority: widget.item.priority,
      labels: List<String>.from(widget.item.labels),
    );
    _notes = List<BoardNote>.from(widget.item.notes);
    _checklists = widget.item.checklists
        .map(
          (BoardChecklist checklist) => BoardChecklist(
            id: checklist.id,
            title: checklist.title,
            items: checklist.items
                .map(
                  (BoardChecklistItem item) => BoardChecklistItem(
                    id: item.id,
                    text: item.text,
                    isDone: item.isDone,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
    _labelsController.text = _draft.labels.join(', ');

    _loadTodoListIfAvailable();
  }

  @override
  void dispose() {
    _saveDraft();
    _todoAddController.dispose();
    _labelsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _draft.displayTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (_selectedLabelFilter != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedLabelFilter = null;
                        });
                      },
                      child: const Text('Back to Editor'),
                    ),
                  IconButton(
                    onPressed: () {
                      _saveDraft();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _selectedLabelFilter != null
                  ? _labelFilterView(_selectedLabelFilter!)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _titleEditor(),
                          const SizedBox(height: 16),
                          _metadataEditor(),
                          const SizedBox(height: 16),
                          _labelsEditor(),
                          const SizedBox(height: 16),
                          _notesEditor(),
                          const SizedBox(height: 16),
                          _checklistEditor(),
                          const SizedBox(height: 16),
                          _todoEditor(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleEditor() {
    return TextFormField(
      initialValue: _draft.title,
      decoration: const InputDecoration(labelText: 'Title'),
      onChanged: (String value) {
        _draft.title = value;
        _saveDraft();
      },
    );
  }

  Widget _metadataEditor() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            initialValue: _draft.priority ?? '',
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: '', child: Text('None')),
              DropdownMenuItem<String>(value: 'A', child: Text('A')),
              DropdownMenuItem<String>(value: 'B', child: Text('B')),
              DropdownMenuItem<String>(value: 'C', child: Text('C')),
              DropdownMenuItem<String>(value: 'D', child: Text('D')),
            ],
            onChanged: (String? value) {
              setState(() {
                _draft.priority = (value == null || value.isEmpty)
                    ? null
                    : value;
                _saveDraft();
              });
            },
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Checkbox(
              value: _draft.dueDate != null,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _draft.dueDate ??= DateTime.now();
                  } else {
                    _draft.dueDate = null;
                  }
                  _saveDraft();
                });
              },
            ),
            const Text('Has due date'),
            if (_draft.dueDate != null)
              TextButton(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: _draft.dueDate ?? DateTime.now(),
                  );

                  if (selected == null) {
                    return;
                  }

                  setState(() {
                    _draft.dueDate = DateTime(
                      selected.year,
                      selected.month,
                      selected.day,
                    );
                    _saveDraft();
                  });
                },
                child: Text(TodoDateFormatter.format(_draft.dueDate!)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _labelsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Labels', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _labelsController,
          decoration: const InputDecoration(hintText: 'comma-separated labels'),
          onSubmitted: (_) => _commitLabels(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _draft.labels
              .map(
                (String label) => InputChip(
                  label: Text('+$label'),
                  onPressed: () {
                    setState(() {
                      _selectedLabelFilter = label;
                    });
                  },
                  onDeleted: () {
                    setState(() {
                      _draft.labels.remove(label);
                      _labelsController.text = _draft.labels.join(', ');
                      _saveDraft();
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _notesEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _notes.add(BoardNote(text: ''));
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add note'),
            ),
          ],
        ),
        ..._notes.map((BoardNote note) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        initialValue: note.text,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(hintText: 'Note'),
                        onChanged: (String value) {
                          note.text = value;
                          _saveDraft();
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 6),
                      _HyperlinkedText(note.text),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _notes.remove(note);
                      _saveDraft();
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _checklistEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text(
              'Checklists',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _checklists.add(BoardChecklist(title: 'Checklist'));
                  _saveDraft();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add checklist'),
            ),
          ],
        ),
        ..._checklists.map((BoardChecklist checklist) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          initialValue: checklist.title,
                          decoration: const InputDecoration(
                            hintText: 'Checklist title',
                          ),
                          onChanged: (String value) {
                            checklist.title = value;
                            _saveDraft();
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _checklists.remove(checklist);
                            _saveDraft();
                          });
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  ...checklist.items.map((BoardChecklistItem item) {
                    return Row(
                      children: <Widget>[
                        Checkbox(
                          value: item.isDone,
                          onChanged: (bool? value) {
                            setState(() {
                              item.isDone = value ?? false;
                              _saveDraft();
                            });
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            initialValue: item.text,
                            decoration: const InputDecoration(
                              hintText: 'Checklist item',
                            ),
                            onChanged: (String value) {
                              item.text = value;
                              _saveDraft();
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              checklist.items.remove(item);
                              _saveDraft();
                            });
                          },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          checklist.items.add(BoardChecklistItem(text: ''));
                          _saveDraft();
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add item'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _todoEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text(
              'Todo List',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            if (_todoListPath == null)
              TextButton(
                onPressed: _createTodoList,
                child: const Text('Create Todo List'),
              )
            else
              Text(
                _todoListPath!.split(Platform.pathSeparator).last,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        if (_todoListPath != null) ...<Widget>[
          ..._todoItems.map((TodoListEntry entry) {
            return Row(
              children: <Widget>[
                Checkbox(
                  value: entry.isCompleted,
                  onChanged: (bool? value) {
                    setState(() {
                      entry.isCompleted = value ?? false;
                      entry.completionDate = entry.isCompleted
                          ? DateTime.now()
                          : null;
                      _saveTodoList();
                    });
                  },
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: entry.text,
                    decoration: const InputDecoration(hintText: 'Todo item'),
                    onChanged: (String value) {
                      entry.text = value;
                      _saveTodoList();
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _todoItems.remove(entry);
                      _saveTodoList();
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            );
          }),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _todoAddController,
                  decoration: const InputDecoration(hintText: 'Add todo'),
                  onSubmitted: (_) => _addTodo(),
                ),
              ),
              IconButton(onPressed: _addTodo, icon: const Icon(Icons.add)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _labelFilterView(String label) {
    final matches = _labelMatches(label);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Items with +$label',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (matches.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text('No other items with this label.'),
            ),
          )
        else
          ...matches.map((match) {
            return Card(
              child: ListTile(
                title: Text(match.item.displayTitle),
                subtitle: Text(match.columnTitle),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onOpenItem(match.item.id);
                },
              ),
            );
          }),
      ],
    );
  }

  List<_LabelMatch> _labelMatches(String label) {
    final results = <_LabelMatch>[];

    for (final column in widget.allColumns) {
      for (final item in column.items) {
        if (item.id == _draft.id) {
          continue;
        }

        if (item.labels.any(
          (String value) => value.toLowerCase() == label.toLowerCase(),
        )) {
          results.add(_LabelMatch(columnTitle: column.menuTitle, item: item));
        }
      }
    }

    return results;
  }

  void _commitLabels() {
    setState(() {
      _draft.labels = _labelsController.text
          .split(',')
          .map(_normalizeTag)
          .where((String value) => value.isNotEmpty)
          .toList();
      _saveDraft();
    });
  }

  String _normalizeTag(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .join('-');
  }

  void _saveDraft() {
    _draft.notes = _notes
        .where((BoardNote note) => note.text.trim().isNotEmpty)
        .toList();
    _draft.checklists = _checklists
        .map(
          (BoardChecklist checklist) => BoardChecklist(
            id: checklist.id,
            title: checklist.title.trim().isEmpty
                ? 'Checklist'
                : checklist.title.trim(),
            items: checklist.items
                .where((BoardChecklistItem item) => item.text.trim().isNotEmpty)
                .toList(),
          ),
        )
        .where(
          (BoardChecklist checklist) =>
              checklist.title.trim().isNotEmpty || checklist.items.isNotEmpty,
        )
        .toList();

    widget.onSave(_draft);
  }

  void _loadTodoListIfAvailable() {
    final boardFilePath = widget.boardFilePath;
    if (boardFilePath == null) {
      return;
    }

    final defaultPath = _todoStore.defaultTodoListPath(
      boardFilePath: boardFilePath,
    );
    final existing = _todoStore.existingTodoListPath(defaultPath);

    if (existing == null) {
      return;
    }

    final text = File(existing).readAsStringSync();
    final parsed = _todoStore.parse(text: text, cardId: _draft.id);

    setState(() {
      _todoListPath = existing;
      _todoItems = parsed.currentCardItems;
      _otherTodoLines = parsed.otherLines;
    });
  }

  void _createTodoList() {
    final boardFilePath = widget.boardFilePath;
    if (boardFilePath == null) {
      return;
    }

    final path = _todoStore.defaultTodoListPath(boardFilePath: boardFilePath);
    _todoStore.createTodoListIfNeeded(path);

    setState(() {
      _todoListPath = path;
      _todoItems = <TodoListEntry>[];
      _otherTodoLines = <String>[];
      _saveTodoList();
    });
  }

  void _addTodo() {
    final text = _todoAddController.text.trim();
    if (text.isEmpty || _todoListPath == null) {
      return;
    }

    setState(() {
      _todoItems.add(TodoListEntry.fromLine(line: text, isCompleted: false));
      _todoAddController.clear();
      _saveTodoList();
    });
  }

  void _saveTodoList() {
    final path = _todoListPath;
    if (path == null) {
      return;
    }

    _todoStore.saveTodoList(
      todoListPath: path,
      currentCardItems: _todoItems,
      otherLines: _otherTodoLines,
      cardId: _draft.id,
      columnContext: widget.columnTitle == null
          ? null
          : _normalizeTag(widget.columnTitle!),
    );
  }
}

class _LabelMatch {
  _LabelMatch({required this.columnTitle, required this.item});

  final String columnTitle;
  final BoardItem item;
}

class _HyperlinkedText extends StatelessWidget {
  const _HyperlinkedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'(https?:\/\/[^\s]+|www\.[^\s]+)');

    var cursor = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      final raw = match.group(0)!;
      final url = raw.startsWith('http') ? raw : 'https://$raw';
      spans.add(
        TextSpan(
          text: raw,
          style: const TextStyle(
            decoration: TextDecoration.underline,
            color: Color(0xFF54C59F),
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri);
              }
            },
        ),
      );

      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: spans,
        ),
      ),
    );
  }
}
