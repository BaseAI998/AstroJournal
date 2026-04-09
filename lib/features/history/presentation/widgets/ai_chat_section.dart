import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/database.dart';

class AIChatSection extends StatelessWidget {
  final JournalEntry entry;
  final TextEditingController chatController;
  final ScrollController scrollController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const AIChatSection({
    super.key,
    required this.entry,
    required this.chatController,
    required this.scrollController,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildChatView(context)),
        _buildChatInput(context),
      ],
    );
  }

  Widget _buildChatView(BuildContext context) {
    final messages = entry.aiConversation;

    if (messages.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome,
                size: 48,
                color: AppTheme.accentGold.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              '切换到此页面后，星灵会自动为你解读这篇日记',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildTypingIndicator();
        }

        final msg = messages[index];
        final isUser = msg.role == 'user';
        return _buildChatBubble(context, msg, isUser);
      },
    );
  }

  Widget _buildChatBubble(BuildContext context, AIMessage msg, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentGold.withOpacity(0.15),
              child: const Icon(Icons.auto_awesome,
                  size: 16, color: AppTheme.accentGold),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.accentGold.withOpacity(0.12)
                    : AppTheme.panel,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? AppTheme.accentGold.withOpacity(0.2)
                      : AppTheme.border,
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: AppTheme.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(msg.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.withOpacity(0.15),
              child: const Icon(Icons.person, size: 16, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.accentGold.withOpacity(0.15),
            child: const Icon(Icons.auto_awesome,
                size: 16, color: AppTheme.accentGold),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppTheme.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.accentGold,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: chatController,
              decoration: InputDecoration(
                hintText: '和星灵聊聊...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              enabled: !isLoading,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentGold,
                    ),
                  )
                : const Icon(Icons.send),
            color: AppTheme.accentGold,
            onPressed: isLoading ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}
