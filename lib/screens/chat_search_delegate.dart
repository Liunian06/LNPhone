import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/chat_model.dart';
import '../core/models/contact_model.dart';
import '../core/providers/chat_provider.dart';
import '../core/providers/contact_provider.dart';
import '../core/theme/app_theme.dart';
import 'dart:io';

class ChatSearchResult {
  final String chatId;
  final String messageId;

  ChatSearchResult({required this.chatId, required this.messageId});
}

class ChatSearchDelegate extends SearchDelegate<ChatSearchResult?> {
  @override
  String get searchFieldLabel => '搜索聊天记录';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: context.appBarBackground,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: context.secondaryTextColor),
        border: InputBorder.none,
      ),
      textTheme: theme.textTheme.copyWith(
        titleLarge: TextStyle(color: context.primaryTextColor),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return Container(
        color: context.chatBackground,
        child: Center(
          child: Text(
            '输入关键词搜索',
            style: TextStyle(color: context.secondaryTextColor),
          ),
        ),
      );
    }

    final chatProvider = context.read<ChatProvider>();
    final contactProvider = context.read<ContactProvider>();

    // 多关键词搜索逻辑
    final keywords = query.trim().toLowerCase().split(RegExp(r'\s+'));

    final List<_SearchResultItem> results = [];

    for (final chat in chatProvider.chats) {
      final role = contactProvider.roles.firstWhere(
        (r) => r.id == chat.roleId,
        orElse: () => ContactRole(id: '', name: '未知', description: ''),
      );
      final me = contactProvider.meList.firstWhere(
        (m) => m.id == chat.meId,
        orElse: () => ContactMe(id: '', name: '我', info: ''),
      );

      for (final msg in chat.messages) {
        // 只搜索文本类型的消息
        if (msg.type != MessageType.words &&
            msg.type != MessageType.action &&
            msg.type != MessageType.thought) {
          continue;
        }

        final content = msg.content.toLowerCase();
        // 必须包含所有关键词
        if (keywords.every((kw) => content.contains(kw))) {
          results.add(_SearchResultItem(
            chatId: chat.id,
            message: msg,
            role: role,
            me: me,
          ));
        }
      }
    }

    // 按时间倒序排列
    results.sort((a, b) => b.message.timestamp.compareTo(a.message.timestamp));

    if (results.isEmpty) {
      return Container(
        color: context.chatBackground,
        child: Center(
          child: Text(
            '未找到相关聊天记录',
            style: TextStyle(color: context.secondaryTextColor),
          ),
        ),
      );
    }

    return Container(
      color: context.chatBackground,
      child: ListView.separated(
        itemCount: results.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 70,
          color: context.dividerColor,
        ),
        itemBuilder: (context, index) {
          final item = results[index];
          final msg = item.message;
          final senderName = msg.isMe ? item.me.name : item.role.name;
          final avatarPath =
              msg.isMe ? item.me.avatarPath : item.role.avatarPath;

          return ListTile(
            leading: _buildAvatar(avatarPath, msg.isMe),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$senderName (${item.me.name}和${item.role.name}的聊天)',
                    style: TextStyle(
                      color: context.primaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatTimestamp(msg.timestamp),
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _buildHighlightedText(msg.content, keywords, context),
            ),
            onTap: () {
              close(context,
                  ChatSearchResult(chatId: item.chatId, messageId: msg.id));
            },
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String? path, bool isMe) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isMe ? Colors.orange[100] : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: path != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.person,
                    color: isMe ? Colors.orange : Colors.grey),
              ),
            )
          : Icon(Icons.person, color: isMe ? Colors.orange : Colors.grey),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildHighlightedText(
      String text, List<String> keywords, BuildContext context) {
    if (keywords.isEmpty) return Text(text);

    List<TextSpan> spans = [];
    String lowerText = text.toLowerCase();
    int start = 0;

    List<_MatchRange> matches = [];
    for (var kw in keywords) {
      if (kw.isEmpty) continue;
      int index = lowerText.indexOf(kw);
      while (index != -1) {
        matches.add(_MatchRange(index, index + kw.length));
        index = lowerText.indexOf(kw, index + kw.length);
      }
    }

    if (matches.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.secondaryTextColor, fontSize: 14),
      );
    }

    matches.sort((a, b) => a.start.compareTo(b.start));
    List<_MatchRange> mergedMatches = [];
    if (matches.isNotEmpty) {
      _MatchRange current = matches[0];
      for (int i = 1; i < matches.length; i++) {
        if (matches[i].start <= current.end) {
          if (matches[i].end > current.end) {
            current = _MatchRange(current.start, matches[i].end);
          }
        } else {
          mergedMatches.add(current);
          current = matches[i];
        }
      }
      mergedMatches.add(current);
    }

    for (var match in mergedMatches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: const TextStyle(
            color: Color(0xFF07C160), fontWeight: FontWeight.bold),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return Text.rich(
      TextSpan(
        children: spans,
        style: TextStyle(color: context.secondaryTextColor, fontSize: 14),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SearchResultItem {
  final String chatId;
  final ChatMessage message;
  final ContactRole role;
  final ContactMe me;

  _SearchResultItem({
    required this.chatId,
    required this.message,
    required this.role,
    required this.me,
  });
}

class _MatchRange {
  final int start;
  final int end;
  _MatchRange(this.start, this.end);
}
