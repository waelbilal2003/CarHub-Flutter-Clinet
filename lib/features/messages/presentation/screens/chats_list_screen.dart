import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/client_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/message_provider.dart';

/// قائمة المحادثات — GET /messages
class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final myId = ref.watch(authProvider).user?.id ?? 0;

    return ClientScaffold(
      navIndex: 3,
      appBar: AppBar(title: const Text('الرسائل')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(conversationsProvider),
        child: conversationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spaceL),
                child: Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySecondary),
              ),
            ],
          ),
          data: (conversations) {
            if (conversations.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('لا توجد محادثات بعد.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final c = conversations[i];
                final other = c.counterpart(myId);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfaceAlt,
                    backgroundImage: other?.avatarUrl != null
                        ? NetworkImage(other!.avatarUrl!)
                        : null,
                    child: other?.avatarUrl == null
                        ? const Icon(Icons.person_outline)
                        : null,
                  ),
                  title: Text(other?.name ?? 'محادثة'),
                  subtitle: c.lastMessageAt != null
                      ? Text('آخر رسالة: ${_time(c.lastMessageAt!)}',
                          style: AppTextStyles.caption)
                      : null,
                  trailing: const Icon(Icons.chevron_left),
                  // نمرّر معرّف المحادثة كما يعود من الـ API.
                  onTap: () => context.push(AppRoutes.chat(c.id)),
                );
              },
            );
          },
        ),
      ),
    );
  }

  static String _time(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
