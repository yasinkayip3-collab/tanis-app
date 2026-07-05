import 'package:flutter/material.dart';
import '../main.dart';
import '../services/supabase_service.dart';

// ─── Eşleşmeler listesi ────────────────────────────────────────
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<Map<String, dynamic>> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final matches = await SupabaseService.getMatches();
      setState(() {
        _matches = matches;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _otherName(Map<String, dynamic> match) {
    final uid = SupabaseService.currentUser!.id;
    final other = match['user1_id'] == uid ? match['user2'] : match['user1'];
    return other?['name'] ?? '';
  }

  String _otherAvatar(Map<String, dynamic> match) {
    final name = _otherName(match);
    return name.isNotEmpty ? name[0] : '?';
  }

  Map<String, dynamic> _otherUser(Map<String, dynamic> match) {
    final uid = SupabaseService.currentUser!.id;
    return (match['user1_id'] == uid ? match['user2'] : match['user1']) ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Eşleşmeler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _matches.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: kPrimary,
                  onRefresh: _loadMatches,
                  child: ListView.separated(
                    itemCount: _matches.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 0, indent: 70),
                    itemBuilder: (context, i) =>
                        _buildMatchTile(_matches[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kPrimaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_outline,
                size: 36, color: kPrimary),
          ),
          const SizedBox(height: 20),
          const Text('Henüz eşleşmen yok',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: kTextPrimary)),
          const SizedBox(height: 8),
          const Text('Keşfet sekmesinde beğenmeye başla!',
              style: TextStyle(color: kTextSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMatchTile(Map<String, dynamic> match) {
    final name = _otherName(match);
    final avatar = _otherAvatar(match);
    final other = _otherUser(match);
    final matchedAt = DateTime.tryParse(match['matched_at'] ?? '');
    final timeStr = matchedAt != null ? _formatTime(matchedAt) : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: kPrimaryLight,
            child: Text(avatar,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: kPrimary)),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: kSuccess,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
      title: Text(name,
          style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: kTextPrimary)),
      subtitle: Text(
        match['last_message'] ?? 'Merhaba demek için tıkla!',
        style: const TextStyle(fontSize: 13, color: kTextSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(timeStr,
              style:
                  const TextStyle(fontSize: 11, color: kTextSecondary)),
          if ((match['unread_count'] ?? 0) > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${match['unread_count']}',
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              matchId: match['id'],
              otherUser: other,
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Dün';
    } else if (diff.inDays < 7) {
      const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}.${dt.month}';
  }
}

// ─── Sohbet ekranı ─────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> otherUser;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _sending = false;

  String get _otherName => widget.otherUser['name'] ?? '';
  String get _otherAvatar =>
      _otherName.isNotEmpty ? _otherName[0] : '?';
  String get _myId => SupabaseService.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _listenMessages();
    SupabaseService.markAsRead(widget.matchId);
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _listenMessages() {
    SupabaseService.messagesStream(widget.matchId).listen((msgs) {
      setState(() => _messages = msgs);
      _scrollToBottom();
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _sending) return;
    _msgController.clear();
    setState(() => _sending = true);
    try {
      await SupabaseService.sendMessage(widget.matchId, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesaj gönderilemedi')),
        );
      }
    }
    setState(() => _sending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: kPrimaryLight,
                  child: Text(_otherAvatar,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: kPrimary)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: kSuccess,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_otherName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: kTextPrimary)),
                const Text('Çevrimiçi',
                    style: TextStyle(fontSize: 11, color: kSuccess)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_outlined),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: kPrimaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.waving_hand_outlined,
                  color: kPrimary, size: 28),
            ),
            const SizedBox(height: 14),
            Text('$_otherName ile eşleştin!',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kTextPrimary)),
            const SizedBox(height: 6),
            const Text('İlk mesajı sen gönder',
                style: TextStyle(color: kTextSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final msg = _messages[i];
        final isMe = msg['sender_id'] == _myId;
        final showDate = i == 0 ||
            _isDifferentDay(
                _messages[i - 1]['sent_at'], msg['sent_at']);

        return Column(
          children: [
            if (showDate) _buildDateDivider(msg['sent_at']),
            _buildBubble(msg, isMe),
          ],
        );
      },
    );
  }

  Widget _buildDateDivider(String? dateStr) {
    final dt = DateTime.tryParse(dateStr ?? '');
    if (dt == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final diff = now.difference(dt);
    String label;
    if (diff.inDays == 0) label = 'Bugün';
    else if (diff.inDays == 1) label = 'Dün';
    else label = '${dt.day}.${dt.month}.${dt.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: kTextSecondary)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe) {
    final sentAt = DateTime.tryParse(msg['sent_at'] ?? '');
    final timeStr = sentAt != null
        ? '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: kPrimaryLight,
              child: Text(_otherAvatar,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: kPrimary)),
            ),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? kPrimary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  border: isMe
                      ? null
                      : Border.all(color: kBorder, width: 0.5),
                ),
                child: Text(
                  msg['content'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isMe ? Colors.white : kTextPrimary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeStr,
                      style: const TextStyle(
                          fontSize: 10, color: kTextSecondary)),
                  if (isMe) ...[
                    const SizedBox(width: 3),
                    Icon(
                      msg['is_read'] == true
                          ? Icons.done_all
                          : Icons.done,
                      size: 12,
                      color: msg['is_read'] == true
                          ? kPrimary
                          : kTextSecondary,
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder, width: 0.5)),
      ),
      child: Row(
        children: [
          // Emoji butonu
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.emoji_emotions_outlined,
                color: kTextSecondary, size: 24),
          ),
          const SizedBox(width: 8),

          // Mesaj alanı
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: kBackground,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kBorder, width: 0.5),
              ),
              child: TextField(
                controller: _msgController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14, color: kTextPrimary),
                decoration: const InputDecoration(
                  hintText: 'Mesaj yaz...',
                  hintStyle: TextStyle(color: kTextSecondary),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Gönder butonu
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _sending ? kPrimaryLight : kPrimary,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                          color: kPrimary, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: kBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: kTextPrimary),
              title: Text('$_otherName\'ın profilini gör',
                  style: const TextStyle(fontSize: 15)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined, color: Colors.orange),
              title: const Text('Engelle', style: TextStyle(fontSize: 15)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.red),
              title: const Text('Şikayet et',
                  style: TextStyle(fontSize: 15, color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDifferentDay(String? a, String? b) {
    final da = DateTime.tryParse(a ?? '');
    final db = DateTime.tryParse(b ?? '');
    if (da == null || db == null) return false;
    return da.day != db.day ||
        da.month != db.month ||
        da.year != db.year;
  }
}
