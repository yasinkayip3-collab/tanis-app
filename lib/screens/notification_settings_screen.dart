import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _matchNotifs = true;
  bool _messageNotifs = true;
  bool _likeNotifs = false;
  bool _permissionGranted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _matchNotifs = prefs.getBool('notif_match') ?? true;
      _messageNotifs = prefs.getBool('notif_message') ?? true;
      _likeNotifs = prefs.getBool('notif_like') ?? false;
      _loading = false;
    });
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.requestPermission();
    setState(() => _permissionGranted = granted);
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(title: const Text('Bildirim ayarları')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_permissionGranted) _buildPermissionBanner(),
                  _buildSection(
                    title: 'Bildirim türleri',
                    children: [
                      _buildToggle(
                        icon: Icons.favorite_outline,
                        iconColor: kPrimary,
                        iconBg: kPrimaryLight,
                        title: 'Eşleşme bildirimleri',
                        subtitle: 'Yeni eşleşmende bildir',
                        value: _matchNotifs,
                        onChanged: (v) {
                          setState(() => _matchNotifs = v);
                          _savePref('notif_match', v);
                        },
                      ),
                      _buildToggle(
                        icon: Icons.message_outlined,
                        iconColor: kSuccess,
                        iconBg: kSuccessLight,
                        title: 'Mesaj bildirimleri',
                        subtitle: 'Yeni mesaj geldiğinde bildir',
                        value: _messageNotifs,
                        onChanged: (v) {
                          setState(() => _messageNotifs = v);
                          _savePref('notif_message', v);
                        },
                      ),
                      _buildToggle(
                        icon: Icons.star_outline,
                        iconColor: const Color(0xFFD4537E),
                        iconBg: const Color(0xFFFBEAF0),
                        title: 'Beğeni bildirimleri',
                        subtitle: 'Birisi profili beğenince bildir',
                        value: _likeNotifs,
                        onChanged: (v) {
                          setState(() => _likeNotifs = v);
                          _savePref('notif_like', v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSection(
                    title: 'Test',
                    children: [
                      _buildActionRow(
                        icon: Icons.notifications_outlined,
                        title: 'Test bildirimi gönder',
                        onTap: _sendTestNotification,
                      ),
                      _buildActionRow(
                        icon: Icons.clear_all_outlined,
                        title: 'Tüm bildirimleri temizle',
                        onTap: () async {
                          await NotificationService.clearAll();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bildirimler temizlendi')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF9F27).withOpacity(0.4), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined,
              color: Color(0xFF854F0B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bildirim izni gerekli',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF633806))),
                const SizedBox(height: 2),
                const Text('Eşleşme ve mesaj bildirimlerini almak için izin ver.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF854F0B))),
              ],
            ),
          ),
          TextButton(
            onPressed: _checkPermission,
            child: const Text('İzin ver',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF633806),
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: kTextSecondary,
                  letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorder, width: 0.5),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        secondary: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 17, color: iconColor),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 14, color: kTextPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12, color: kTextSecondary)),
        value: value,
        onChanged: onChanged,
        activeColor: kPrimary,
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: kTextSecondary),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 14, color: kTextPrimary)),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 18, color: kBorder),
        ]),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    if (_matchNotifs) {
      await NotificationService.showMatchNotification(
        matchedUserName: 'Ayşe',
        matchId: 'test-match-id',
      );
    }
    if (_messageNotifs) {
      await Future.delayed(const Duration(seconds: 1));
      await NotificationService.showMessageNotification(
        senderName: 'Merve',
        message: 'Merhaba! Bu bir test mesajıdır.',
        matchId: 'test-match-id',
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test bildirimi gönderildi'),
          backgroundColor: kSuccess,
        ),
      );
    }
  }
}
