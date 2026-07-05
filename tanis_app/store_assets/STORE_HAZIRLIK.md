# 🚀 Tanış — App Store & Google Play Hazırlık Rehberi

---

## 📋 GENEL CHECKLIST

### ✅ Teknik hazırlık
- [ ] Flutter sürümü güncelle: `flutter upgrade`
- [ ] Tüm paketler güncelle: `flutter pub upgrade`
- [ ] Release modunda test: `flutter build apk --release`
- [ ] Hata yok kontrolü: `flutter analyze`

---

## 🍎 iOS — App Store

### 1. Apple Developer Hesabı
- https://developer.apple.com adresine git
- **$99/yıl** ödeme yap
- App Store Connect'e giriş yap: https://appstoreconnect.apple.com

### 2. Xcode Ayarları
`ios/Runner.xcworkspace` dosyasını Xcode'da aç:

| Ayar | Değer |
|------|-------|
| Bundle ID | `com.SENIN_ADIN.tanis` |
| Version | `1.0.0` |
| Build | `1` |
| Deployment Target | iOS 13.0+ |
| Display Name | `Tanış` |

### 3. Info.plist İzinleri
`ios/Runner/Info.plist` dosyasına ekle:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Profil fotoğrafı seçmek için galeri erişimi gerekiyor</string>

<key>NSCameraUsageDescription</key>
<string>Profil fotoğrafı çekmek için kamera erişimi gerekiyor</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Yakınındaki kişileri göstermek için konum bilgisi gerekiyor</string>
```

### 4. Build & Upload
```bash
# IPA oluştur
flutter build ipa --release

# Transporter veya Xcode Organizer ile yükle
open build/ios/archive/Runner.xcarchive
```

### 5. App Store Connect Bilgileri
- **Kategori:** Social Networking
- **Yaş sınırı:** 17+ (dating içeriği)
- **Gizlilik politikası URL'i:** Zorunlu!
- **Destek URL'i:** Zorunlu!

---

## 🤖 Android — Google Play

### 1. Google Play Developer Hesabı
- https://play.google.com/console adresine git
- **$25 tek seferlik** ödeme yap

### 2. android/app/build.gradle Ayarları
```gradle
defaultConfig {
    applicationId "com.SENIN_ADIN.tanis"
    minSdkVersion 21
    targetSdkVersion 34
    versionCode 1
    versionName "1.0.0"
}
```

### 3. İmzalama (Keystore)
```bash
# Keystore oluştur (BİR KERE yap, sakla!)
keytool -genkey -v \
  -keystore ~/tanis-key.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias tanis

# android/key.properties dosyası oluştur:
storePassword=SIFREN
keyPassword=SIFREN
keyAlias=tanis
storeFile=/Users/KULLANICI/tanis-key.jks
```

### 4. Build
```bash
# AAB oluştur (Play Store için zorunlu)
flutter build appbundle --release

# Çıktı: build/app/outputs/bundle/release/app-release.aab
```

### 5. AndroidManifest.xml İzinleri
`android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

---

## 🎨 GÖRSEL VARLIKLAR

### Uygulama ikonu
| Platform | Boyut | Dosya |
|----------|-------|-------|
| iOS | 1024×1024 px | `ios_icon.png` |
| Android | 512×512 px | `android_icon.png` |
| Her ikisi | Şeffaf arka plan YOK | PNG formatı |

**flutter_launcher_icons** paketi ile otomatik üret:
```yaml
# pubspec.yaml'a ekle:
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/app_icon.png"
  adaptive_icon_background: "#7F77DD"
  adaptive_icon_foreground: "assets/app_icon_fg.png"
```
```bash
flutter pub run flutter_launcher_icons
```

### Splash screen boyutları
| Platform | Boyut |
|----------|-------|
| iOS | 2732×2732 px |
| Android | 1080×1920 px |

### Ekran görüntüleri (Screenshot)
**App Store:**
- 6.7" iPhone: 1290×2796 px (en az 3, max 10)
- 6.5" iPhone: 1242×2688 px
- 12.9" iPad: 2048×2732 px (iPad desteği varsa)

**Google Play:**
- Telefon: 1080×1920 px veya 1080×2340 px
- En az 2, max 8 ekran görüntüsü
- Feature graphic: 1024×500 px (zorunlu)

---

## 📝 MAĞAZA AÇIKLAMASI

### Başlık
```
Tanış — Arkadaşlık & Tanışma
```

### Kısa açıklama (80 karakter)
```
Yakınındaki insanlarla tanış, gerçek bağlantılar kur.
```

### Tam açıklama
```
Tanış, seni gerçek insanlarla buluşturan samimi bir 
arkadaşlık ve tanışma uygulaması.

🤝 NASIL ÇALIŞIR?
• Profil oluştur, fotoğraf ekle
• İlgi alanlarını seç
• Yakınındaki kişileri keşfet
• Beğen veya geç — eşleşince sohbet başlasın!

✨ ÖZELLİKLER
• Kolay SMS doğrulama ile kayıt
• Akıllı eşleşme algoritması
• Gerçek zamanlı mesajlaşma
• Güvenli ve gizli

🔒 GÜVENLİK
• 18 yaş doğrulaması
• Şikayet & engelleme sistemi
• Veriler şifreli saklanır

Türkiye'nin her şehrinden insanlarla tanışmaya hazır mısın?
```

### Anahtar kelimeler (App Store, virgülle ayır)
```
arkadaşlık,tanışma,sohbet,flört,match,eşleşme,yeni insanlar,dating,chat,sosyal
```

---

## 🔒 YASAL ZORUNLULUKLAR

### 1. Gizlilik Politikası (ZORUNLU)
Her iki mağaza da gizlilik politikası URL'i ister.
Şunları içermeli:
- Hangi verileri topluyorsunuz (telefon, konum, fotoğraf)
- Verileri nasıl kullanıyorsunuz
- Üçüncü taraflarla paylaşım (Supabase)
- Kullanıcı hakları (veri silme talebi)
- İletişim bilgileri

**Ücretsiz oluştur:** https://www.privacypolicygenerator.info

### 2. Kullanım Koşulları
- 18 yaş sınırı
- Uygunsuz içerik yasağı
- Hesap askıya alma kuralları

### 3. KVKK (Türkiye)
- Kullanıcı verilerini Türkiye'de işliyorsanız KVKK'ya uyum zorunlu
- Supabase'in sunucu konumunu kontrol et (EU veya US seçeneği var)

---

## 📊 YAYINLAMA SÜRECİ

### App Store
| Adım | Süre |
|------|------|
| İnceleme süreci | 1–3 iş günü |
| Reddedilirse revizyon | +1–2 gün |
| Yayına giriş | Onaydan sonra anlık |

### Google Play
| Adım | Süre |
|------|------|
| İlk uygulama incelemesi | 3–7 gün |
| Sonraki güncellemeler | Birkaç saat |

---

## ⚡ HIZLI BAŞLANGIÇ SIRASI

1. `flutter analyze` — hata yok
2. Uygulama ikonunu hazırla (1024×1024 PNG)
3. `flutter_launcher_icons` çalıştır
4. Bundle ID / applicationId belirle
5. iOS: Keystore imzala, IPA oluştur
6. Android: Keystore oluştur, AAB oluştur
7. Gizlilik politikası URL'i hazırla
8. Ekran görüntüleri çek (en az 3)
9. Mağaza açıklamalarını hazırla
10. Her iki mağazaya yükle
