import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import '../database/database.dart';

class AIService {
  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';
  static const int _maxHistoryRounds = 20;

  String get apiKey => AIConfig.apiKey;
  String get model => AIConfig.model;

  AIService();

  String _buildSystemPrompt(Profile profile) {
    return '你是"星灵"，一位温和而富有洞察力的占星顾问。'
        '用户名叫${profile.displayName}，'
        '出生于${profile.birthDateTime.year}年${profile.birthDateTime.month}月${profile.birthDateTime.day}日，'
        '出生地：${profile.birthPlaceName}。'
        '请基于用户的日记内容，用占星的语言给出温暖的回应和反思引导。'
        '回复控制在150字以内，风格像写给朋友的短信，温暖且有洞察力。'
        '不要使用markdown格式。';
  }

  List<Map<String, String>> _buildMessages({
    required Profile profile,
    required JournalEntry entry,
    required List<AIMessage> history,
    String? userMessage,
  }) {
    final messages = <Map<String, String>>[];

    // System prompt
    messages.add({'role': 'system', 'content': _buildSystemPrompt(profile)});

    // Inject diary content as first user context
    messages.add({
      'role': 'user',
      'content': '这是我的一篇日记，写于${entry.capturedAt.year}年'
          '${entry.capturedAt.month}月${entry.capturedAt.day}日：\n\n'
          '${entry.bodyText}',
    });

    // Conversation history (trim to max rounds)
    final trimmedHistory = history.length > _maxHistoryRounds * 2
        ? history.sublist(history.length - _maxHistoryRounds * 2)
        : history;

    for (final msg in trimmedHistory) {
      messages.add({'role': msg.role, 'content': msg.text});
    }

    // New user message (if any, for follow-up questions)
    if (userMessage != null) {
      messages.add({'role': 'user', 'content': userMessage});
    }

    return messages;
  }

  Future<String> chat({
    required Profile profile,
    required JournalEntry entry,
    required List<AIMessage> history,
    String? userMessage,
  }) async {
    final messages = _buildMessages(
      profile: profile,
      entry: entry,
      history: history,
      userMessage: userMessage,
    );

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      final errorMsg = body is Map ? (body['error']?['message'] ?? response.body) : response.body;
      throw Exception('AI请求失败: $errorMsg');
    }

    final body = jsonDecode(response.body);
    final content = body['choices']?[0]?['message']?['content'];
    if (content is! String || content.isEmpty) {
      throw Exception('AI返回内容为空');
    }
    return content;
  }
}
