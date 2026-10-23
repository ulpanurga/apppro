import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/post_list_notifier.dart';
import '../widgets/error_view.dart';
import '../widgets/filter_bar.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';
import 'post_details_screen.dart';

class PostsListScreen extends StatefulWidget {
  const PostsListScreen({super.key});

  @override
  State<PostsListScreen> createState() => _PostsListScreenState();
}

class _PostsListScreenState extends State<PostsListScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      context.read<PostListNotifier>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<PostListNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Explorer'),
        actions: [
          IconButton(
            tooltip: 'Сбросить фильтры',
            icon: const Icon(Icons.filter_alt_off),
            onPressed: n.resetFilters,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Новый пост'),
      ),
      body: Column(
        children: [
          const FilterBar(),
          if (n.status == ListStatus.cached) _CachedBanner(n),
          Expanded(child: _body(n)),
        ],
      ),
    );
  }

  Widget _body(PostListNotifier n) {
    switch (n.status) {
      case ListStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ListStatus.error:
        return ErrorView(
          message: n.error?.message ?? 'Не удалось загрузить посты',
          onRetry: n.load,
        );
      case ListStatus.empty:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  n.query.trim().isNotEmpty
                      ? 'По запросу «${n.query}» ничего не найдено среди загруженных постов.'
                      : 'Постов нет.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: n.resetFilters,
                  child: const Text('Сбросить фильтры'),
                ),
              ],
            ),
          ),
        );
      case ListStatus.success:
      case ListStatus.cached:
        final posts = n.visiblePosts;
        return RefreshIndicator(
          onRefresh: () => n.load(refresh: true),
          child: ListView.builder(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: posts.length + 1,
            itemBuilder: (context, i) {
              if (i == posts.length) return _Footer(n);
              final post = posts[i];
              return PostCard(
                post: post,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostDetailsScreen(post: post),
                  ),
                ),
              );
            },
          ),
        );
    }
  }
}

class _CachedBanner extends StatelessWidget {
  const _CachedBanner(this.n);
  final PostListNotifier n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              n.isRefreshing
                  ? 'Показаны сохранённые данные. Обновляем…'
                  : 'Показаны сохранённые данные. ${n.error?.message ?? ''}',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          if (!n.isRefreshing)
            TextButton(
              onPressed: () => n.load(refresh: true),
              child: const Text('Обновить'),
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer(this.n);
  final PostListNotifier n;

  @override
  Widget build(BuildContext context) {
    switch (n.nextPageStatus) {
      case NextPageStatus.loading:
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      case NextPageStatus.error:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(n.pageError?.message ?? 'Не удалось загрузить страницу',
                  textAlign: TextAlign.center),
              TextButton.icon(
                onPressed: n.retryNextPage,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ),
        );
      case NextPageStatus.idle:
        if (n.status == ListStatus.success && n.hasMore) {
          return Center(
            child: TextButton(
              onPressed: () => n.loadMore(),
              child: const Text('Загрузить ещё'),
            ),
          );
        }
        return const SizedBox(height: 88); // место под FAB
    }
  }
}
