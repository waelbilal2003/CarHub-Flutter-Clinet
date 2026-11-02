import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/ai_reply.dart';
import '../providers/ai_chat_provider.dart';
import '../widgets/ai_chat_widgets.dart';

/// شاشة المساعد الذكي — مطابقة لـ 23_ai_assistant.html:
/// رأس كحلي متدرّج، فقاعات العميل خضراء وردود المساعد بيضاء،
/// بطاقات منتجات وبطاقات إجراء أفقية، وشريط إدخال سفلي.
///
/// كل الطلبات عبر Laravel (`POST /ai/ask`)؛ لا اتصال مباشر بخدمة الذكاء.
/// اختلافان مقصودان عن التصميم: لا زر «+» ولا ميكروفون (لا مرفقات ولا
/// صوت في v0)، و⋮ في الرأس يفتح «محادثة جديدة».
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? text]) async {
    final message = (text ?? _input.text).trim();
    if (message.isEmpty) return;
    if (text == null) _input.clear();
    FocusScope.of(context).unfocus();
    await ref.read(aiChatProvider.notifier).send(message);
  }

  // ───────────── بطاقات الإجراء ─────────────

  void _onCard(AiCard card, AiReply reply) {
    switch (card) {
      case OpenProductCard(:final productIds):
        if (productIds.length == 1) {
          context.push(AppRoutes.productDetails(productIds.first));
        } else {
          _showProductsSheet(
            reply.products.where((p) => productIds.contains(p.id)).toList(),
          );
        }
      case OpenMarketplaceSearchCard(
          :final query,
          :final carMake,
          :final carModel,
          :final year,
        ):
        context.push(AppRoutes.marketplaceSearch(
          search: query,
          carMake: carMake,
          carModel: carModel,
          year: year,
        ));
      case CreateTenderCard(:final category, :final title, :final city):
        context.push(AppRoutes.createTenderPrefilled(
          category: category,
          title: title,
          city: city,
        ));
    }
  }

  /// open_product بأكثر من منتج: لا توجد شاشة «قائمة منتجات محددة» في
  /// التطبيق، فنعرض المنتجات نفسها في ورقة سفلية، وكل منتج يفتح تفاصيله.
  void _showProductsSheet(List<AiProduct> products) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(AppDimensions.containerPadding, 0,
              AppDimensions.containerPadding, AppDimensions.spaceL),
          children: [
            for (final p in products)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(p.title, style: AppTextStyles.labelBold),
                subtitle: Text('${p.price} ${p.currency}'),
                trailing: CompatibilityBadge(p.compatibility),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push(AppRoutes.productDetails(p.id));
                },
              ),
          ],
        ),
      ),
    );
  }

  // ───────────── البناء ─────────────

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(aiChatProvider);
    ref.listen(aiChatProvider, (prev, next) {
      if (prev?.entries.length != next.entries.length ||
          prev?.isSending != next.isSending) {
        _scrollToEnd();
      }
    });

    final lastAssistant =
        chat.entries.lastIndexWhere((e) => e is AssistantEntry);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _header(context, chat.isSending),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scroll,
              padding: const EdgeInsets.all(AppDimensions.containerPadding),
              itemCount: chat.entries.length + 1 + (chat.isSending ? 1 : 0),
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.stackLg),
              itemBuilder: (context, i) {
                if (i == 0) return const _DateChip();
                final index = i - 1;
                if (index >= chat.entries.length) {
                  return const _AssistantRow(child: TypingIndicator());
                }
                return _entry(chat.entries[index],
                    isLatestAssistant: index == lastAssistant && !chat.isSending);
              },
            ),
          ),
          _InputBar(
            controller: _input,
            enabled: !chat.isSending,
            onSend: () => _send(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _header(BuildContext context, bool isSending) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navyGradientStart, Color(0xFF112240)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_forward, color: AppColors.onPrimary),
                  tooltip: 'رجوع',
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy,
                      color: AppColors.onPrimaryContainer),
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Expanded(
                  child: Text('المساعد الذكي',
                      style: AppTextStyles.headlineLgMobile
                          .copyWith(color: AppColors.onPrimary)),
                ),
                PopupMenuButton<String>(
                  enabled: !isSending,
                  icon: const Icon(Icons.more_vert, color: AppColors.onPrimary),
                  onSelected: (_) =>
                      ref.read(aiChatProvider.notifier).newConversation(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'new',
                      child: Row(children: [
                        Icon(Icons.add_comment_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('محادثة جديدة'),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _entry(ChatEntry entry, {required bool isLatestAssistant}) {
    return switch (entry) {
      UserEntry(:final text) => UserBubble(text: text),
      AssistantEntry(:final text, :final reply) => _AssistantRow(
          child: _assistantContent(text, reply, isLatestAssistant),
        ),
      ErrorEntry(:final message, :final retryable, :final canWatchAd) => _AssistantRow(
          child: AssistantTextBubble(
            text: message,
            background: AppColors.errorContainer.withValues(alpha: 0.4),
            borderColor: AppColors.errorContainer,
            trailing: retryable
                ? TextButton.icon(
                    onPressed: () => ref.read(aiChatProvider.notifier).retry(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('إعادة المحاولة'),
                  )
                : canWatchAd
                    // إعلانات المكافآت: الباك إند جاهز (AdMob SSV). العرض الفعلي ينتظر
                    // حساب AdMob ومعرّفات الوحدات الإعلانية من الزبون، فالزر معطّل.
                    ? const TextButton(
                        onPressed: null,
                        child: Text('شاهد إعلاناً واحصل على 3 أسئلة (قريباً)'),
                      )
                    : null,
          ),
        ),
    };
  }

  Widget _assistantContent(String text, AiReply? reply, bool isLatest) {
    final followup = reply?.followup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AssistantTextBubble(text: text),
        if (reply != null && reply.products.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spaceM),
          _HorizontalStrip(
            height: 250,
            children: [
              for (final p in reply.products)
                AiProductCard(
                  product: p,
                  onTap: () => context.push(AppRoutes.productDetails(p.id)),
                ),
            ],
          ),
        ],
        if (reply != null && reply.cards.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spaceM),
          _HorizontalStrip(
            height: 196,
            children: [
              for (final c in reply.cards)
                AiActionCard(card: c, onPressed: () => _onCard(c, reply)),
            ],
          ),
        ],
        // أزرار الاقتراحات: لآخر رد فقط، والضغط يرسل نصّها كرسالة.
        if (isLatest && followup != null && followup.suggestions.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spaceM),
          if (!text.contains(followup.question) && followup.question.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
              child: Text(followup.question, style: AppTextStyles.bodySm),
            ),
          Wrap(
            spacing: AppDimensions.spaceS,
            runSpacing: AppDimensions.spaceS,
            children: [
              for (final s in followup.suggestions)
                ActionChip(
                  label: Text(s, style: AppTextStyles.labelBold),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.primaryContainer),
                  shape: const StadiumBorder(),
                  onPressed: () => _send(s),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AssistantRow extends StatelessWidget {
  final Widget child;
  const _AssistantRow({required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AssistantAvatar(),
        const SizedBox(width: AppDimensions.spaceS),
        Expanded(child: child),
      ],
    );
  }
}

class _HorizontalStrip extends StatelessWidget {
  final double height;
  final List<Widget> children;
  const _HorizontalStrip({required this.height, required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 4),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppDimensions.cardGap),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        ),
        child: const Text('اليوم', style: AppTextStyles.labelSm),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
        boxShadow: AppDimensions.bottomBarShadow,
      ),
      padding: const EdgeInsets.all(AppDimensions.spaceM),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                maxLength: aiMaxMessageLength,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك هنا...',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceM, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    borderSide: const BorderSide(color: AppColors.surfaceVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    borderSide: const BorderSide(color: AppColors.surfaceVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    borderSide:
                        const BorderSide(color: AppColors.primaryContainer),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceS),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? onSend : null,
                customBorder: const CircleBorder(),
                child: Ink(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: enabled
                        ? const LinearGradient(
                            colors: [Color(0xFF00B761), Color(0xFF009951)])
                        : null,
                    color: enabled ? null : AppColors.surfaceContainerHigh,
                  ),
                  child: const Icon(Icons.send, color: AppColors.onPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
