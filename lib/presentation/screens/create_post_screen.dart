import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../data/repositories/post_repository.dart';
import '../state/create_post_notifier.dart';
import '../state/post_list_notifier.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CreatePostNotifier(ctx.read<PostRepository>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Новый пост')),
        body: const _CreatePostForm(),
      ),
    );
  }
}

class _CreatePostForm extends StatefulWidget {
  const _CreatePostForm();

  @override
  State<_CreatePostForm> createState() => _CreatePostFormState();
}

class _CreatePostFormState extends State<_CreatePostForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  int? _userId;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return; // проверка до отправки
    final form = context.read<CreatePostNotifier>();
    final list = context.read<PostListNotifier>();
    final messenger = ScaffoldMessenger.of(context);

    final post = await form.submit(
      title: _title.text.trim(),
      body: _body.text.trim(),
      userId: _userId!,
    );

    if (post != null) {
      await list.addLocalPost(post);
      _title.clear();
      _body.clear();
      messenger.showSnackBar(const SnackBar(
        content: Text('Пост создан и добавлен в список (локально)'),
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(form.error?.message ?? 'Не удалось создать пост'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<CreatePostNotifier>();
    final users = context.watch<PostListNotifier>().users;
    final created = form.createdPost;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Заголовок',
                  border: OutlineInputBorder(),
                ),
                validator: PostValidators.title,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _body,
                maxLength: 1000,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Текст поста',
                  border: OutlineInputBorder(),
                ),
                validator: PostValidators.body,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _userId,
                decoration: InputDecoration(
                  labelText: 'Автор',
                  border: const OutlineInputBorder(),
                  helperText: users.isEmpty ? 'Список авторов не загружен' : null,
                ),
                items: [
                  for (final u in users)
                    DropdownMenuItem(value: u.id, child: Text('${u.id}. ${u.name}')),
                ],
                onChanged: (v) => setState(() => _userId = v),
                validator: PostValidators.userId,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  // null => кнопка заблокирована на время запроса
                  onPressed: form.isSubmitting ? null : _submit,
                  child: form.isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Создать'),
                ),
              ),
            ],
          ),
        ),
        if (created != null) ...[
          const SizedBox(height: 24),
          Text('Ответ сервера', style: Theme.of(context).textTheme.titleMedium),
          Card(
            child: ListTile(
              title: Text(created.title),
              subtitle: Text(
                '${created.body}\n\nid: ${created.id} · userId: ${created.userId}',
              ),
              isThreeLine: true,
            ),
          ),
          const Text(
            'JSONPlaceholder только имитирует создание: пост не сохраняется '
            'на сервере, поэтому в списке он помечен «создан локально».',
          ),
        ],
      ],
    );
  }
}
