import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // ─── Auth ──────────────────────────────────────────────────────


  // ─── E-posta Auth ──────────────────────────────────────────────

  /// E-posta + şifre ile giriş
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  /// E-posta + şifre ile kayıt
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(email: email, password: password);
  }

  /// Şifre sıfırlama e-postası gönder
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// SMS ile telefon doğrulama gönder
  static Future<void> sendOtp(String phone) async {
    await client.auth.signInWithOtp(phone: '+90$phone');
  }

  /// OTP kodunu doğrula
  static Future<AuthResponse> verifyOtp(String phone, String token) async {
    return await client.auth.verifyOTP(
      phone: '+90$phone',
      token: token,
      type: OtpType.sms,
    );
  }

  /// Çıkış yap
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Mevcut kullanıcı
  static User? get currentUser => client.auth.currentUser;

  // ─── Profil ────────────────────────────────────────────────────

  /// Profil oluştur
  static Future<void> createProfile({
    required String name,
    required DateTime birthdate,
    required String gender,
    required String city,
    required String bio,
  }) async {
    final userId = currentUser!.id;
    await client.from('users').upsert({
      'id': userId,
      'name': name,
      'birthdate': birthdate.toIso8601String().split('T')[0],
      'gender': gender,
      'city': city,
      'bio': bio,
    });
  }

  /// Tercihleri kaydet
  static Future<void> savePreferences({
    required String seekingGender,
    required int ageMin,
    required int ageMax,
    required String purpose,
  }) async {
    final userId = currentUser!.id;
    await client.from('preferences').upsert({
      'user_id': userId,
      'seeking_gender': seekingGender,
      'age_min': ageMin,
      'age_max': ageMax,
      'purpose': purpose,
    });
  }

  /// İlgi alanlarını kaydet
  static Future<void> saveInterests(List<String> interests) async {
    final userId = currentUser!.id;
    // Önce eskileri sil
    await client.from('user_interests').delete().eq('user_id', userId);
    // Yenileri ekle
    if (interests.isNotEmpty) {
      await client.from('user_interests').insert(
        interests.map((i) => {'user_id': userId, 'interest': i}).toList(),
      );
    }
  }

  /// Profil fotoğrafı yükle
  static Future<String> uploadPhoto(String filePath, int order) async {
    final userId = currentUser!.id;
    final fileName = '$userId/photo_$order.jpg';
    final file = File(filePath);

    await client.storage.from('photos').upload(
      fileName,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    final url = client.storage.from('photos').getPublicUrl(fileName);

    await client.from('photos').upsert({
      'user_id': userId,
      'url': url,
      'order': order,
      'is_profile': order == 0,
    });

    return url;
  }

  /// Profili getir
  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    final res = await client
        .from('users')
        .select('*, photos(*), user_interests(*), preferences(*)')
        .eq('id', userId)
        .single();
    return res;
  }

  // ─── Swipe & Match ─────────────────────────────────────────────

  /// Swipe at (like/dislike)
  static Future<void> swipe(String toUserId, String action) async {
    await client.from('swipes').insert({
      'from_user': currentUser!.id,
      'to_user': toUserId,
      'action': action,
    });
  }

  /// Match'leri getir
  static Future<List<Map<String, dynamic>>> getMatches() async {
    final userId = currentUser!.id;
    final res = await client
        .from('matches')
        .select('*, user1:user1_id(id, name, photos(*)), user2:user2_id(id, name, photos(*))')
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .eq('is_active', true)
        .order('matched_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  // ─── Mesajlaşma ────────────────────────────────────────────────

  /// Mesajları getir (realtime için stream kullan)
  static Stream<List<Map<String, dynamic>>> messagesStream(String matchId) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .order('sent_at');
  }

  /// Mesaj gönder
  static Future<void> sendMessage(String matchId, String content) async {
    await client.from('messages').insert({
      'match_id': matchId,
      'sender_id': currentUser!.id,
      'content': content,
      'type': 'text',
    });
  }

  /// Mesajları okundu işaretle
  static Future<void> markAsRead(String matchId) async {
    await client
        .from('messages')
        .update({'is_read': true})
        .eq('match_id', matchId)
        .neq('sender_id', currentUser!.id);
  }

  // ─── Keşfet profilleri ─────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getDiscoverProfiles() async {
    final userId = currentUser!.id;

    // Daha önce swipe edilenleri al
    final swipes = await client
        .from('swipes')
        .select('to_user')
        .eq('from_user', userId);
    final swipedIds = swipes.map((s) => s['to_user'] as String).toList();
    swipedIds.add(userId); // Kendini de hariç tut

    // Tercihleri al
    final prefs = await client
        .from('preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    // Profilleri getir
    final seekingGender = prefs?['seeking_gender'];
    final shouldFilterGender = seekingGender != null && seekingGender != 'Fark etmez';

    // SQL formatı için UUID'leri tırnak içine al
    final idFilter = swipedIds.map((id) => "'$id'").join(',');

    final result = await client
        .from('users')
        .select('*, photos(*), user_interests(*)')
        .not('id', 'in', '($idFilter)')
        .eq('is_active', true)
        .limit(20);

    // Cinsiyet filtresi dart tarafında uygula
    final filtered = shouldFilterGender
        ? result.where((u) => u['gender'] == seekingGender).toList()
        : result;

    return List<Map<String, dynamic>>.from(filtered);
  }

  // ─── Şikayet ──────────────────────────────────────────────────
  static Future<void> reportUser(String reportedId, String reason) async {
    await client.from('reports').insert({
      'reporter_id': currentUser!.id,
      'reported_id': reportedId,
      'reason': reason,
    });
  }
}
