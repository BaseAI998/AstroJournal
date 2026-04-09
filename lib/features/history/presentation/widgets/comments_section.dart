import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/database.dart';

class CommentsSection extends StatelessWidget {
  final JournalEntry entry;
  final TextEditingController commentController;
  final VoidCallback onSubmit;
  final void Function(int index) onDelete;

  const CommentsSection({
    super.key,
    required this.entry,
    required this.commentController,
    required this.onSubmit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildCommentsView(context)),
        _buildCommentInput(context),
      ],
    );
  }

  Widget _buildCommentsView(BuildContext context) {
    if (entry.comments.isEmpty) {
      return Center(
        child: Text(
          '暂无评论，快来添加第一条吧！',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entry.comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final comment = entry.comments[index];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.withOpacity(0.2),
              child: const Icon(Icons.person, size: 20, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '我',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('MM-dd HH:mm').format(comment.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              onPressed: () => onDelete(index),
              color: Colors.grey.shade400,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentInput(BuildContext context) {
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
              controller: commentController,
              decoration: InputDecoration(
                hintText: '写下你的评论...',
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
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}
