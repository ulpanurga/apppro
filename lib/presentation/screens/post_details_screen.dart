import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../state/post_details_notifier.dart';
import '../widgets/error_view.dart';

class PostDetailsScreen extends StatelessWidget {
  const PostDetailsScreen({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          PostDetailsNotifier(ctx.read<PostRepository>(), post)..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Пост')),
        body: Consumer<PostDetailsNotifier>(
          builder: (context, n, _) {
            switch (n.status) {
              case DetailsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case DetailsStatus.error:
                return ErrorView(
                  message: n.error?.message ?? 'Ошибка загрузки',
                  onRetry: n.load,
                );
              case DetailsStatus.success:
                return _Content(n);
            }
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content(this.n);
  final PostDetailsNotifier n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = n.post;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(p.title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          n.author != null
              ? 'Автор: ${n.author!.name} (${n.author!.email})'
              : 'Автор: пользователь #${p.userId}',
          style: theme.textTheme.bodySmall,
        ),
        if (p.isLocal)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Chip(label: Text('создан локально')),
          ),
        const SizedBox(height: 12),
        Text(p.body),
        const Divider(height: 32),
        if (p.isLocal)
          const Text('У локально созданного поста нет комментариев на сервере.')
        else ...[
          Text('Комментарии (${n.comments.length})',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final c in n.comments)
            Card(
              child: ListTile(
                title: Text(c.name),
                subtitle: Text('${c.email}\n${c.body}'),
                isThreeLine: true,
              ),
            ),
        ],
      ],
    );
  }
}
