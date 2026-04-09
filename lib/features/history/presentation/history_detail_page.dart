import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/database/database.dart';
import '../../../providers/journal_provider.dart';
import '../../../providers/profile_provider.dart';
import 'widgets/comments_section.dart';
import 'widgets/ai_chat_section.dart';

class HistoryDetailPage extends ConsumerStatefulWidget {
  final String entryId;

  const HistoryDetailPage({super.key, required this.entryId});

  @override
  ConsumerState<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends ConsumerState<HistoryDetailPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _aiChatController = TextEditingController();
  bool _isEditing = false;
  late TextEditingController _editController;
  late TabController _tabController;
  bool _aiInitialized = false;
  bool _aiLoading = false;
  final ScrollController _aiScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _aiChatController.dispose();
    _editController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _aiScrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 1) {
      _tryInitAIConversation();
    }
  }

  void _tryInitAIConversation() {
    if (_aiInitialized || _aiLoading) return;

    final journalState = ref.read(journalProvider);
    final entry = journalState.whenOrNull(
      data: (entries) =>
          entries.where((e) => e.id == widget.entryId).firstOrNull,
    );
    if (entry == null) return;

    if (entry.aiConversation.isNotEmpty) {
      _aiInitialized = true;
      return;
    }

    _sendAIMessage(null);
  }

  Future<void> _sendAIMessage(String? userMessage) async {
    final profileState = ref.read(profileProvider);
    final profile = profileState.whenOrNull(data: (p) => p);
    if (profile == null) return;

    setState(() => _aiLoading = true);

    try {
      await ref.read(journalProvider.notifier).sendAIMessage(
            widget.entryId,
            profile,
            userMessage: userMessage,
          );
      _aiInitialized = true;
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_aiScrollController.hasClients) {
        _aiScrollController.animateTo(
          _aiScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitAIChat() {
    final text = _aiChatController.text.trim();
    if (text.isEmpty || _aiLoading) return;
    _aiChatController.clear();
    FocusScope.of(context).unfocus();
    _sendAIMessage(text);
  }

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
        content:
            Text('确定要删除这条评论吗？', style: Theme.of(ctx).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确认', style: TextStyle(color: AppTheme.danger)),
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
                      icon:
                          const Icon(Icons.check, color: AppTheme.accentGold),
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
              // Diary content (scrollable)
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
                ),
              ),

              const Divider(height: 1),

              // TabBar
              Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.accentGold,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.accentGold,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: [
                    Tab(text: '我的评论 (${entry.comments.length})'),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('星灵对话'),
                          if (_aiLoading) ...[
                            const SizedBox(width: 6),
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppTheme.accentGold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                flex: 3,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    CommentsSection(
                      entry: entry,
                      commentController: _commentController,
                      onSubmit: _submitComment,
                      onDelete: _deleteComment,
                    ),
                    AIChatSection(
                      entry: entry,
                      chatController: _aiChatController,
                      scrollController: _aiScrollController,
                      isLoading: _aiLoading,
                      onSubmit: _submitAIChat,
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
