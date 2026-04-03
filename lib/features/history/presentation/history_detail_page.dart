import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/database/database.dart';
import '../../../providers/journal_provider.dart';

class HistoryDetailPage extends ConsumerStatefulWidget {
  final String entryId;

  const HistoryDetailPage({super.key, required this.entryId});

  @override
  ConsumerState<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends ConsumerState<HistoryDetailPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _editController.dispose();
    super.dispose();
  }

  /// 判断是否还能编辑：当前时间不能超过日记创建日期当天（即同一天内可编辑）
  bool _canEdit(JournalEntry entry) {
    final now = DateTime.now();
    final created = entry.capturedAt;
    return now.year == created.year &&
        now.month == created.month &&
        now.day == created.day;
  }

  void _startEdit(JournalEntry entry) {
    if (!_canEdit(entry)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('只能在日记创建当天编辑'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _isEditing = true;
      _editController.text = entry.bodyText;
    });
  }

  void _saveEdit(JournalEntry entry) {
    final newText = _editController.text.trim();
    if (newText.isEmpty || newText == entry.bodyText) {
      setState(() => _isEditing = false);
      return;
    }
    final updated = entry.copyWith(bodyText: newText);
    ref.read(journalProvider.notifier).updateEntry(updated);
    setState(() => _isEditing = false);
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    ref.read(journalProvider.notifier).addComment(widget.entryId, text);
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  void _deleteComment(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('删除评论', style: Theme.of(ctx).textTheme.displayMedium),
        content: Text('确定要删除这条评论吗？',
            style: Theme.of(ctx).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('确认', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(journalProvider.notifier).deleteComment(widget.entryId, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journalState = ref.watch(journalProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isEditing) {
              setState(() => _isEditing = false);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _isEditing ? '编辑' : '详情',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          journalState.whenOrNull(
                data: (entries) {
                  final entry =
                      entries.where((e) => e.id == widget.entryId).firstOrNull;
                  if (entry == null) return const SizedBox.shrink();

                  if (_isEditing) {
                    return IconButton(
                      icon: const Icon(Icons.check,
                          color: AppTheme.accentGold),
                      onPressed: () => _saveEdit(entry),
                    );
                  } else {
                    return IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: _canEdit(entry)
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => _startEdit(entry),
                    );
                  }
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: journalState.when(
        data: (entries) {
          final entry =
              entries.where((e) => e.id == widget.entryId).firstOrNull;
          if (entry == null) {
            return const Center(child: Text('记录不存在'));
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 日期 + 运势
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('yyyy-MM-dd HH:mm')
                                .format(entry.capturedAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (entry.fortuneScore != null)
                            Text(
                              '运势: ${entry.fortuneScore}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 正文：编辑模式 or 阅读模式
                      if (_isEditing)
                        TextField(
                          controller: _editController,
                          maxLines: null,
                          autofocus: true,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(height: 1.6),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '写下你的想法...',
                          ),
                        )
                      else
                        Text(
                          entry.bodyText,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(height: 1.6),
                        ),

                      const SizedBox(height: 40),
                      const Divider(),
                      const SizedBox(height: 16),

                      // 评论区
                      Text(
                        '评论 (${entry.comments.length})',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      if (entry.comments.isEmpty)
                        Text(
                          '暂无评论，快来添加第一条吧！',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: entry.comments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final comment = entry.comments[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      Colors.grey.withOpacity(0.2),
                                  child: const Icon(Icons.person,
                                      size: 20, color: Colors.grey),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '我',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
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
                                        DateFormat('MM-dd HH:mm')
                                            .format(comment.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16),
                                  onPressed: () => _deleteComment(index),
                                  color: Colors.grey.shade400,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // 底部评论输入
              Container(
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
                        controller: _commentController,
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
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: Theme.of(context).primaryColor,
                      onPressed: _submitComment,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
