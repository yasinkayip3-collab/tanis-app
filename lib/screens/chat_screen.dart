import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final Map<String,dynamic> otherUser;
  const ChatScreen({super.key, required this.matchId, required this.otherUser});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String,dynamic>> _msgs = [];
  final _client = Supabase.instance.client;

  String get _myId => _client.auth.currentUser?.id ?? '';
  String get _otherName => widget.otherUser['name']?.toString() ?? '';

  @override
  void initState() { super.initState(); _listen(); }
  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _listen() {
    _client.from('messages').stream(primaryKey: ['id'])
        .eq('match_id', widget.matchId)
        .order('sent_at')
        .listen((msgs) { setState(() => _msgs = msgs); _scrollDown(); });
  }

  Future<void> _send() async {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty) return;
    _msgCtrl.clear();
    try {
      await _client.from('messages').insert({'match_id': widget.matchId, 'sender_id': _myId, 'content': txt, 'type': 'text'});
    } catch (_) {}
  }

  void _scrollDown() { WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBackground,
    appBar: AppBar(
      titleSpacing: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
      title: Row(children: [
        CircleAvatar(radius: 18, backgroundColor: kPrimaryLight,
          child: Text(_otherName.isNotEmpty ? _otherName[0] : '?', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kPrimary))),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_otherName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: kTextPrimary)),
          const Text('Çevrimiçi', style: TextStyle(fontSize: 11, color: kSuccess)),
        ]),
      ]),
    ),
    body: Column(children: [
      Expanded(child: _msgs.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 64, height: 64, decoration: const BoxDecoration(color: kPrimaryLight, shape: BoxShape.circle),
                child: const Icon(Icons.waving_hand_outlined, color: kPrimary, size: 28)),
              const SizedBox(height: 14),
              Text('$_otherName ile eşleştin!', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              const Text('İlk mesajı sen gönder', style: TextStyle(color: kTextSecondary, fontSize: 13)),
            ]))
          : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              itemCount: _msgs.length,
              itemBuilder: (_, i) {
                final msg = _msgs[i];
                final isMe = msg['sender_id'] == _myId;
                final time = DateTime.tryParse(msg['sent_at'] ?? '');
                final timeStr = time != null ? '${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}' : '';
                return Padding(padding: const EdgeInsets.only(bottom: 4), child: Column(children: [
                  Row(mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end, children: [
                      if (!isMe) ...[
                        CircleAvatar(radius: 14, backgroundColor: kPrimaryLight,
                          child: Text(_otherName.isNotEmpty ? _otherName[0] : '?', style: const TextStyle(fontSize: 11, color: kPrimary))),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? kPrimary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16)),
                          border: isMe ? null : Border.all(color: kBorder, width: 0.5)),
                        child: Text(msg['content'] ?? '', style: TextStyle(fontSize: 14, color: isMe ? Colors.white : kTextPrimary, height: 1.4))),
                    ]),
                  Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(padding: const EdgeInsets.only(top: 3, left: 36, right: 4),
                      child: Text(timeStr, style: const TextStyle(fontSize: 10, color: kTextSecondary)))),
                ]));
              })),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: kBorder, width: 0.5))),
        child: Row(children: [
          Expanded(child: Container(
            decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(22), border: Border.all(color: kBorder, width: 0.5)),
            child: TextField(controller: _msgCtrl, maxLines: null,
              decoration: const InputDecoration(hintText: 'Mesaj yaz...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              onSubmitted: (_) => _send()))),
          const SizedBox(width: 8),
          GestureDetector(onTap: _send, child: Container(width: 42, height: 42,
            decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20))),
        ]),
      ),
    ]),
  );
}
