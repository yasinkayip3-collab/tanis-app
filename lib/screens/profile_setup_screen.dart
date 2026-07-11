import '../main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/supabase_service.dart';

// ─── Ana profil kurulum ekranı ─────────────────────────────────
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Adım 1 - Temel bilgiler
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'Erkek';

  // Adım 2 - Fotoğraf, şehir, bio
  final List<String?> _photos = [null, null, null, null];
  String _city = 'Samsun';
  final _bioController = TextEditingController();

  // Adım 3 - İlgi alanları
  final List<String> _allInterests = [
    'Müzik', 'Spor', 'Seyahat', 'Sinema', 'Oyun',
    'Yemek', 'Sanat', 'Teknoloji', 'Kitap', 'Dans',
    'Doğa', 'Fotoğrafçılık', 'Yoga', 'Bisiklet',
  ];
  final Set<String> _selectedInterests = {'Müzik', 'Seyahat'};

  // Adım 4 - Tercihler
  String _seekingGender = 'Kadın';
  double _ageMin = 18;
  double _ageMax = 35;
  String _purpose = 'Arkadaşlık';

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitProfile() async {
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğum tarihini gir')));
      return;
    }
    try {
      await SupabaseService.createProfile(
        name: _nameController.text.trim(),
        birthdate: _birthDate!,
        gender: _gender,
        city: _city,
        bio: _bioController.text.trim(),
      );
      await SupabaseService.savePreferences(
        seekingGender: _seekingGender,
        ageMin: _ageMin.toInt(),
        ageMax: _ageMax.toInt(),
        purpose: _purpose,
      );
      await SupabaseService.saveInterests(_selectedInterests.toList());

      if (_photos.any((p) => p != null) && mounted) {
        // Fotoğraflar varsa yükle (image_picker entegrasyonu gerekli)
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil oluşturuldu!'), backgroundColor: kSuccess));
        // AppRouter otomatik HomeScreen'e yönlendirir
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final minDate = DateTime(now.year - 100);
    final maxDate = DateTime(now.year - 18, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: maxDate,
      firstDate: minDate,
      lastDate: maxDate,
      helpText: '18 yaşından büyük olmalısın',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: kPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  int? get _age {
    if (_birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - _birthDate!.year;
    if (now.month < _birthDate!.month ||
        (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                GestureDetector(
                  onTap: _prevStep,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kBorder, width: 0.5),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 16, color: kTextSecondary),
                  ),
                )
              else
                const SizedBox(width: 36),
              Expanded(
                child: Center(
                  child: Text(
                    'tanış',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: kPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              Text(
                '${_currentStep + 1}/$_totalSteps',
                style: const TextStyle(fontSize: 13, color: kTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStepBar(),
        ],
      ),
    );
  }

  Widget _buildStepBar() {
    return Row(
      children: List.generate(_totalSteps, (i) {
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 5 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: i < _currentStep
                  ? kSuccess
                  : i == _currentStep
                      ? kPrimary
                      : kBorder,
            ),
          ),
        );
      }),
    );
  }

  // ─── Bottom bar ─────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final labels = ['Devam et', 'Devam et', 'Devam et', 'Profili tamamla'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            labels[_currentStep],
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // ─── Adım 1: Temel bilgiler ─────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hesap oluştur', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextPrimary)),
          const SizedBox(height: 4),
          const Text('Sana uygun kişileri bulalım', style: TextStyle(fontSize: 14, color: kTextSecondary)),
          const SizedBox(height: 24),

          _sectionLabel('Ad soyad'),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Adın ne?'),
          ),
          const SizedBox(height: 14),

          _sectionLabel('Doğum tarihi'),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _birthDate != null ? kPrimary : kBorder, width: _birthDate != null ? 1.5 : 0.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16,
                      color: _birthDate != null ? kPrimary : kTextSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _birthDate != null
                        ? '${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}  •  ${_age} yaş'
                        : 'Tarihi seç',
                    style: TextStyle(
                      color: _birthDate != null ? kTextPrimary : kTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          _sectionLabel('Cinsiyet'),
          _buildSegmentedControl(
            options: const ['Erkek', 'Kadın', 'Diğer'],
            selected: _gender,
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 14),

          _sectionLabel('Telefon numarası'),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: '05xx xxx xx xx',
              prefixText: '+90 ',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 14, color: kPrimaryDark),
                SizedBox(width: 6),
                Expanded(
                  child: Text('SMS ile doğrulama yapılacak', style: TextStyle(fontSize: 12, color: kPrimaryDark)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Adım 2: Fotoğraf, şehir, bio ──────────────────────────────
  Widget _buildStep2() {
    final cities = ['Samsun', 'İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya', 'Trabzon', 'Konya', 'Gaziantep'];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profil fotoğrafları', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextPrimary)),
          const SizedBox(height: 4),
          const Text('En az 1 fotoğraf ekle', style: TextStyle(fontSize: 14, color: kTextSecondary)),
          const SizedBox(height: 20),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: 4,
            itemBuilder: (context, i) => _buildPhotoSlot(i),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Şehir'),
          DropdownButtonFormField<String>(
            value: _city,
            decoration: const InputDecoration(),
            items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _city = v!),
          ),
          const SizedBox(height: 14),

          _sectionLabel('Hakkında'),
          TextField(
            controller: _bioController,
            maxLines: 3,
            maxLength: 150,
            decoration: const InputDecoration(
              hintText: 'Kendini kısaca tanıt...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot(int index) {
    final photoUrl = _photos[index];
    final hasPhoto = photoUrl != null;
    final isUploading = _uploading[index] ?? false;

    return GestureDetector(
      onTap: () => _pickAndUploadImage(index),
      child: Container(
        decoration: BoxDecoration(
          color: hasPhoto ? kSuccessLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasPhoto ? kSuccess : kBorder,
            width: 0.5,
          ),
          image: hasPhoto ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover) : null,
        ),
        child: isUploading 
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!hasPhoto) ...[
                    Icon(
                      index == 0 ? Icons.add_a_photo_outlined : Icons.add,
                      color: kTextSecondary,
                      size: 22,
                    ),
                    if (index == 0) ...[
                      const SizedBox(height: 4),
                      const Text('Ana', style: TextStyle(fontSize: 9, color: kTextSecondary)),
                    ],
                  ] else ...[
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: kSuccess, size: 14),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(int index) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() => _uploading[index] = true);
      try {
        final url = await SupabaseService.uploadPhoto(image.path, index);
        setState(() {
          _photos[index] = url;
          _uploading[index] = false;
        });
      } catch (e) {
        setState(() => _uploading[index] = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yükleme başarısız')));
      }
    }
  }

  // ─── Adım 3: İlgi alanları ──────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('İlgi alanları', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextPrimary)),
          const SizedBox(height: 4),
          const Text('Seç, benzer kişilerle eşleşelim', style: TextStyle(fontSize: 14, color: kTextSecondary)),
          const SizedBox(height: 8),
          Text(
            '${_selectedInterests.length} seçildi',
            style: const TextStyle(fontSize: 13, color: kPrimary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allInterests.map((interest) {
              final selected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () => setState(() {
                  selected
                      ? _selectedInterests.remove(interest)
                      : _selectedInterests.add(interest);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? kPrimaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? kPrimary : kBorder,
                      width: selected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? kPrimaryDark : kTextSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Adım 4: Tercihler ──────────────────────────────────────────
  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tercihler', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextPrimary)),
          const SizedBox(height: 4),
          const Text('Kiminle tanışmak istiyorsun?', style: TextStyle(fontSize: 14, color: kTextSecondary)),
          const SizedBox(height: 24),

          _sectionLabel('Arıyorum'),
          _buildSegmentedControl(
            options: const ['Kadın', 'Erkek', 'Fark etmez'],
            selected: _seekingGender,
            onChanged: (v) => setState(() => _seekingGender = v),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Yaş aralığı  •  ${_ageMin.toInt()} – ${_ageMax.toInt()}'),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(_ageMin, _ageMax),
            min: 18,
            max: 60,
            divisions: 42,
            activeColor: kPrimary,
            inactiveColor: kPrimaryLight,
            labels: RangeLabels(_ageMin.toInt().toString(), _ageMax.toInt().toString()),
            onChanged: (v) => setState(() {
              _ageMin = v.start;
              _ageMax = v.end;
            }),
          ),
          const SizedBox(height: 20),

          _sectionLabel('Amaç'),
          _buildSegmentedControl(
            options: const ['Arkadaşlık', 'İlişki', 'Gezmek'],
            selected: _purpose,
            onChanged: (v) => setState(() => _purpose = v),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kSuccessLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kSuccess.withOpacity(0.3), width: 0.5),
            ),
            child: Row(
              children: const [
                Icon(Icons.verified_outlined, color: kSuccess, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profilini oluşturduktan sonra eşleşmeye başlayabilirsin',
                    style: TextStyle(fontSize: 12, color: kSuccess, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Yardımcı widget'lar ────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextSecondary)),
    );
  }

  Widget _buildSegmentedControl({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Row(
        children: options.asMap().entries.map((e) {
          final i = e.key;
          final opt = e.value;
          final isSelected = opt == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.all(3),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  opt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : kTextSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
