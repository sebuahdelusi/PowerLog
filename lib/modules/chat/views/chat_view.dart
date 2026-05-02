import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/models/chat_message_model.dart';
import '../controllers/chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.black, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Energy Consultant AI',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text('Powered by Gemini',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _MessageList()),
          _TypingIndicator(),
          _InputBar(),
        ],
      ),
    );
  }
}

// ── Message list ──────────────────────────────────────────────────────────────

class _MessageList extends GetView<ChatController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => ListView.builder(
          controller: controller.scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: controller.messages.length,
          itemBuilder: (ctx, i) => _Bubble(msg: controller.messages[i]),
        ));
  }
}

// ── Chat bubble ───────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.black, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: AppColors.surfaceLight,
                          ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.black : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('HH:mm').format(msg.timestamp),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceLight,
              ),
              child: const Icon(Icons.person,
                  color: AppColors.textSecondary, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Typing indicator (three animated dots) ────────────────────────────────────

class _TypingIndicator extends GetView<ChatController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() => controller.isTyping.value
        ? Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.black, size: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: const _DotLoader(),
                ),
              ],
            ),
          )
        : const SizedBox.shrink());
  }
}

class _DotLoader extends StatefulWidget {
  const _DotLoader();
  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final progress = (_ctrl.value + i * 0.25) % 1.0;
            final opacity = (progress < 0.5 ? progress * 2 : (1 - progress) * 2)
                .clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: opacity),
              ),
            );
          },
        );
      }),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends GetView<ChatController> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
            top: BorderSide(
                color: AppColors.surfaceLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.inputCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => controller.sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask about energy saving…',
                hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 14),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Obx(() => GestureDetector(
                onTap: controller.sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: controller.isTyping.value
                        ? const LinearGradient(
                            colors: [AppColors.surfaceLight, AppColors.surfaceLight])
                        : AppColors.primaryGradient,
                  ),
                  child: Icon(
                    controller.isTyping.value
                        ? Icons.hourglass_empty
                        : Icons.send_rounded,
                    color: controller.isTyping.value
                        ? AppColors.textSecondary
                        : Colors.black,
                    size: 20,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
