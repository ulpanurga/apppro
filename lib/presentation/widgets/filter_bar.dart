import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/post_list_notifier.dart';

/// Поиск, фильтр по автору, сортировка и сброс.
class FilterBar extends StatefulWidget {
  const FilterBar({super.key});

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<PostListNotifier>();

    // После «Сбросить фильтры» очищаем поле поиска.
    if (n.query.isEmpty && _controller.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.clear());
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            onChanged: n.setQuery,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск по заголовку',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              'Поиск работает только среди загруженных постов '
              '(загружено: ${n.loadedCount}), а не по всему набору данных.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: n.users.any((u) => u.id == n.userId) ? n.userId : null,
                  hint: const Text('Автор'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Все авторы'),
                    ),
                    ...n.users.map(
                      (u) => DropdownMenuItem<int?>(
                        value: u.id,
                        child: Text('${u.id}. ${u.name}',
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: n.setUserId,
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('ID ↑')),
                  ButtonSegment(value: false, label: Text('ID ↓')),
                ],
                selected: {n.ascending},
                onSelectionChanged: (s) => n.setAscending(s.first),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
