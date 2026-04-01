import 'dart:convert';

import 'storage/storage_stub.dart' show AppStorage;
import 'storage/storage.dart';

class Profile {
  final String id;
  final String displayName;
  final DateTime birthDateTime;
  final String birthPlaceName;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.displayName,
    required this.birthDateTime,
    required this.birthPlaceName,
    required this.createdAt,
  });
}

class JournalComment {
  final String text;
  final DateTime createdAt;

  const JournalComment({
    required this.text,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => {
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  static JournalComment? fromJson(Map<String, Object?> json) {
    final text = json['text'];
    final createdAt = json['createdAt'];
    if (text is! String || createdAt is! String) return null;
    return JournalComment(
      text: text,
      createdAt: DateTime.parse(createdAt),
    );
  }
}

class JournalEntry {
  final String id;
  final String profileId;
  final DateTime capturedAt;
  final String bodyText;
  final int? fortuneScore;
  final String? astroSnapshot;
  final DateTime createdAt;
  final List<JournalComment> comments;

  const JournalEntry({
    required this.id,
    required this.profileId,
    required this.capturedAt,
    required this.bodyText,
    this.fortuneScore,
    this.astroSnapshot,
    required this.createdAt,
    this.comments = const [],
  });

  JournalEntry copyWith({
    String? id,
    String? profileId,
    DateTime? capturedAt,
    String? bodyText,
    int? fortuneScore,
    String? astroSnapshot,
    DateTime? createdAt,
    List<JournalComment>? comments,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      capturedAt: capturedAt ?? this.capturedAt,
      bodyText: bodyText ?? this.bodyText,
      fortuneScore: fortuneScore ?? this.fortuneScore,
      astroSnapshot: astroSnapshot ?? this.astroSnapshot,
      createdAt: createdAt ?? this.createdAt,
      comments: comments ?? this.comments,
    );
  }
}

class AppDatabase {
  final AppStorage _storage;
  Profile? _profile;
  final List<JournalEntry> _entries = [];
  Future<void>? _loadTask;

  AppDatabase({AppStorage? storage}) : _storage = storage ?? createAppStorage();

  Future<void> _ensureLoaded() {
    _loadTask ??= _load();
    return _loadTask!;
  }

  Future<void> _load() async {
    final raw = await _storage.read();
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final map = decoded.cast<String, Object?>();

      final profileJson = map['profile'];
      if (profileJson is Map) {
        _profile = _profileFromJson(profileJson.cast<String, Object?>());
      }

      final entriesJson = map['entries'];
      if (entriesJson is List) {
        _entries.clear();
        for (final item in entriesJson) {
          if (item is! Map) continue;
          final entry = _entryFromJson(item.cast<String, Object?>());
          if (entry == null) continue;
          _entries.add(entry);
        }
      }
    } catch (_) {
      _profile = null;
      _entries.clear();
    }
  }

  Future<void> _persist() async {
    final data = <String, Object?>{
      'profile': _profile == null ? null : _profileToJson(_profile!),
      'entries': _entries.map(_entryToJson).toList(growable: false),
    };
    await _storage.write(jsonEncode(data));
  }

  Future<Profile?> getProfile() async {
    await _ensureLoaded();
    return _profile;
  }

  Future<void> saveProfile(Profile profile) async {
    await _ensureLoaded();
    _profile = profile;
    await _persist();
  }

  Future<List<JournalEntry>> getAllEntries() async {
    await _ensureLoaded();
    final copied = [..._entries];
    copied.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return copied;
  }

  Future<void> addEntry(JournalEntry entry) async {
    await _ensureLoaded();
    _entries.add(entry);
    await _persist();
  }

  Future<void> updateEntry(JournalEntry entry) async {
    await _ensureLoaded();
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _entries[index] = entry;
      await _persist();
    }
  }

  Future<void> close() async {}
}

Map<String, Object?> _profileToJson(Profile profile) {
  return <String, Object?>{
    'id': profile.id,
    'displayName': profile.displayName,
    'birthDateTime': profile.birthDateTime.toIso8601String(),
    'birthPlaceName': profile.birthPlaceName,
    'createdAt': profile.createdAt.toIso8601String(),
  };
}

Profile? _profileFromJson(Map<String, Object?> json) {
  final id = json['id'];
  final displayName = json['displayName'];
  final birthDateTime = json['birthDateTime'];
  final birthPlaceName = json['birthPlaceName'];
  final createdAt = json['createdAt'];

  if (id is! String ||
      displayName is! String ||
      birthDateTime is! String ||
      birthPlaceName is! String ||
      createdAt is! String) {
    return null;
  }

  return Profile(
    id: id,
    displayName: displayName,
    birthDateTime: DateTime.parse(birthDateTime),
    birthPlaceName: birthPlaceName,
    createdAt: DateTime.parse(createdAt),
  );
}

Map<String, Object?> _entryToJson(JournalEntry entry) {
  return <String, Object?>{
    'id': entry.id,
    'profileId': entry.profileId,
    'capturedAt': entry.capturedAt.toIso8601String(),
    'bodyText': entry.bodyText,
    'fortuneScore': entry.fortuneScore,
    'astroSnapshot': entry.astroSnapshot,
    'createdAt': entry.createdAt.toIso8601String(),
    'comments': entry.comments.map((c) => c.toJson()).toList(),
  };
}

JournalEntry? _entryFromJson(Map<String, Object?> json) {
  final id = json['id'];
  final profileId = json['profileId'];
  final capturedAt = json['capturedAt'];
  final bodyText = json['bodyText'];
  final fortuneScore = json['fortuneScore'];
  final astroSnapshot = json['astroSnapshot'];
  final createdAt = json['createdAt'];
  final commentsJson = json['comments'];

  if (id is! String ||
      profileId is! String ||
      capturedAt is! String ||
      bodyText is! String ||
      createdAt is! String) {
    return null;
  }

  List<JournalComment> comments = [];
  if (commentsJson is List) {
    for (final item in commentsJson) {
      if (item is Map<String, Object?>) {
        final comment = JournalComment.fromJson(item);
        if (comment != null) comments.add(comment);
      } else if (item is Map) {
        final comment = JournalComment.fromJson(item.cast<String, Object?>());
        if (comment != null) comments.add(comment);
      }
    }
  }

  return JournalEntry(
    id: id,
    profileId: profileId,
    capturedAt: DateTime.parse(capturedAt),
    bodyText: bodyText,
    fortuneScore: fortuneScore is int ? fortuneScore : null,
    astroSnapshot: astroSnapshot is String ? astroSnapshot : null,
    createdAt: DateTime.parse(createdAt),
    comments: comments,
  );
}
