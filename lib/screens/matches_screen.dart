import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'chat_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});
  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<Map<String,dynamic>> _matches = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
      final res = await Supabase.instance.client.from('matches')
          .select('*, user1:user1_id(id,name,city,birthdate,photos(*)), user2:user2_id(id,name,city,birthdate,photos(*))')
          .or('user1_id.eq.$uid,user2_id.eq.$uid')
          .eq('is_active', true)
          .order('matched_at', ascending: false);
      setState(() { _matches = List<Map<String,dynamic>>.from(res); _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Map<String,dynamic> _other(Map<String,dynamic> m) {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    return (m['user1_id'] == uid ? m['user2'] : m['user1']) as Map<String,dynamic>? ?? {};
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBackground,
    appBar: AppBar(title: const Text('Eşleşmeler')),
    body: _loading ? const Center(child: CircularProgressIndicator(color: kPrimary))
        : _matches.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.favorite_border, size: 64, color: kBorder),
            const SizedBox(height: 16),
            const Text('Henüz eşleşme yok', style: TextStyle(fontSize: 18, color: kTextSecondary)),
            const SizedBox(height: 8),
            const Text('Keşfet sekmesinden beğenmeye başla!', style: TextStyle(color: kTextSecondary)),
          ]))
        : RefreshIndicator(color: kPrimary, onRefresh: _load,
            child: ListView.separated(
              itemCount: _matches.length,
              separatorBuilder: (_, __) => const Divider(height: 0, indent: 70),
              itemBuilder: (_, i) {
                final other = _other(_matches[i]);
                final name = other['name']?.toString() ?? '?';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(radius: 26, backgroundColor: kPrimaryLight,
                    child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: kPrimary))),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  subtitle: Text(other['city']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                  trailing: const Icon(Icons.chevron_right, color: kBorder),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(matchId: _matches[i]['id'], otherUser: other))),
                );
              })));
}
