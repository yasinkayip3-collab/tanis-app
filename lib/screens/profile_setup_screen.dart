import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  final _nameCtrl = TextEditingController();
  final _bioCtrl  = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'Erkek';
  String _city   = 'Samsun';
  String _purpose = 'Arkadaşlık';
  String _seeking = 'Fark etmez';
  double _ageMin = 18, _ageMax = 35;
  final Set<String> _interests = {};
  bool _saving = false;

  final _cities = ['Samsun','İstanbul','Ankara','İzmir','Bursa','Antalya','Trabzon','Konya'];
  final _allInterests = ['Müzik','Spor','Seyahat','Sinema','Oyun','Yemek','Sanat','Teknoloji','Kitap','Dans','Doğa','Fotoğrafçılık'];

  @override
  void dispose() { _pageCtrl.dispose(); _nameCtrl.dispose(); _bioCtrl.dispose(); super.dispose(); }

  void _next() {
    if (_step < 3) { _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); setState(() => _step++); }
    else _save();
  }

  void _prev() {
    if (_step > 0) { _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); setState(() => _step--); }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _birthDate == null) { _snack('Ad ve doğum tarihi zorunlu'); return; }
    setState(() => _saving = true);
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser!.id;
      await client.from('users').upsert({
        'id': uid, 'name': _nameCtrl.text.trim(),
        'birthdate': _birthDate!.toIso8601String().split('T')[0],
        'gender': _gender, 'city': _city, 'bio': _bioCtrl.text.trim(),
      });
      await client.from('preferences').upsert({
        'user_id': uid, 'seeking_gender': _seeking,
        'age_min': _ageMin.toInt(), 'age_max': _ageMax.toInt(), 'purpose': _purpose,
      });
      if (_interests.isNotEmpty) {
        await client.from('user_interests').delete().eq('user_id', uid);
        await client.from('user_interests').insert(_interests.map((i) => {'user_id': uid, 'interest': i}).toList());
      }
      // AppRouter otomatik HomeScreen'e yönlendirir
    } catch (e) { _snack('Hata: $e'); }
    if (mounted) setState(() => _saving = false);
  }

  void _snack(String msg) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  int get _age {
    if (_birthDate == null) return 0;
    final now = DateTime.now();
    int a = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month || (now.month == _birthDate!.month && now.day < _birthDate!.day)) a--;
    return a;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBackground,
    body: SafeArea(child: Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20,16,20,0), child: Column(children: [
        Row(children: [
          if (_step > 0) GestureDetector(onTap: _prev, child: Container(width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder, width: 0.5)),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: kTextSecondary)))
          else const SizedBox(width: 36),
          Expanded(child: Center(child: const Text('tanış', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: kPrimary)))),
          Text('${_step+1}/4', style: const TextStyle(fontSize: 13, color: kTextSecondary)),
        ]),
        const SizedBox(height: 12),
        Row(children: List.generate(4, (i) => Expanded(child: Container(
          height: 3, margin: EdgeInsets.only(right: i<3?5:0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
            color: i < _step ? kSuccess : i == _step ? kPrimary : kBorder))))),
      ])),
      Expanded(child: PageView(controller: _pageCtrl, physics: const NeverScrollableScrollPhysics(), children: [
        _buildStep1(), _buildStep2(), _buildStep3(), _buildStep4(),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(20,8,20,20), child: SizedBox(width: double.infinity, height: 50,
        child: ElevatedButton(onPressed: _saving ? null : _next,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(_step < 3 ? 'Devam et' : 'Profili tamamla')))),
    ])),
  );

  Widget _buildStep1() => SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Temel bilgiler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextPrimary)),
    const SizedBox(height: 20),
    _label('Ad soyad'),
    TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Adın ne?')),
    const SizedBox(height: 14),
    _label('Doğum tarihi'),
    GestureDetector(onTap: () async {
      final d = await showDatePicker(context: context, initialDate: DateTime(2000),
        firstDate: DateTime(1940), lastDate: DateTime.now().subtract(const Duration(days: 365*18)));
      if (d != null) setState(() => _birthDate = d);
    }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder, width: 0.5)),
      child: Row(children: [
        Icon(Icons.calendar_today_outlined, size: 16, color: _birthDate != null ? kPrimary : kTextSecondary),
        const SizedBox(width: 8),
        Text(_birthDate != null ? '${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}  •  $_age yaş' : 'Tarihi seç',
          style: TextStyle(color: _birthDate != null ? kTextPrimary : kTextSecondary, fontSize: 14))]))),
    const SizedBox(height: 14),
    _label('Cinsiyet'),
    _seg(['Erkek','Kadın','Diğer'], _gender, (v) => setState(() => _gender = v)),
  ]));

  Widget _buildStep2() => SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Profil bilgileri', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextPrimary)),
    const SizedBox(height: 20),
    _label('Şehir'),
    DropdownButtonFormField<String>(value: _city, decoration: InputDecoration(filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder, width: 0.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder, width: 0.5))),
      items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) => setState(() => _city = v!)),
    const SizedBox(height: 14),
    _label('Hakkında'),
    TextField(controller: _bioCtrl, maxLines: 3, maxLength: 150,
      decoration: const InputDecoration(hintText: 'Kendini kısaca tanıt...')),
  ]));

  Widget _buildStep3() => SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('İlgi alanları', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextPrimary)),
    const SizedBox(height: 4),
    Text('${_interests.length} seçildi', style: const TextStyle(color: kPrimary, fontSize: 13)),
    const SizedBox(height: 16),
    Wrap(spacing: 8, runSpacing: 8, children: _allInterests.map((tag) {
      final sel = _interests.contains(tag);
      return GestureDetector(onTap: () => setState(() => sel ? _interests.remove(tag) : _interests.add(tag)),
        child: AnimatedContainer(duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: sel ? kPrimaryLight : Colors.white, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? kPrimary : kBorder, width: sel ? 1.5 : 0.5)),
          child: Text(tag, style: TextStyle(fontSize: 13, color: sel ? kPrimaryDark : kTextSecondary, fontWeight: sel ? FontWeight.w500 : FontWeight.w400))));
    }).toList()),
  ]));

  Widget _buildStep4() => SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Tercihler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextPrimary)),
    const SizedBox(height: 20),
    _label('Arıyorum'),
    _seg(['Kadın','Erkek','Fark etmez'], _seeking, (v) => setState(() => _seeking = v)),
    const SizedBox(height: 16),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      _label('Yaş aralığı'), Text('${_ageMin.toInt()} – ${_ageMax.toInt()}', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w500)),
    ]),
    RangeSlider(values: RangeValues(_ageMin, _ageMax), min: 18, max: 60, divisions: 42,
      activeColor: kPrimary, inactiveColor: kPrimaryLight,
      onChanged: (v) => setState(() { _ageMin = v.start; _ageMax = v.end; })),
    const SizedBox(height: 8),
    _label('Amaç'),
    _seg(['Arkadaşlık','İlişki','Gezmek'], _purpose, (v) => setState(() => _purpose = v)),
  ]));

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextSecondary)));

  Widget _seg(List<String> opts, String sel, ValueChanged<String> onChange) => Container(
    decoration: BoxDecoration(color: kBackground, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorder, width: 0.5)),
    child: Row(children: opts.map((o) { final a = o == sel; return Expanded(child: GestureDetector(onTap: () => onChange(o),
      child: AnimatedContainer(duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.all(3), padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(color: a ? kPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Text(o, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: a ? Colors.white : kTextSecondary, fontWeight: a ? FontWeight.w500 : FontWeight.w400))))); }).toList()));
}
