# 🗺️ Map Tracking

Kullanıcının konum bilgisini izleyen ve harita üzerinde gösteren Flutter uygulaması.

## ✨ Özellikler

- 📍 **Gerçek Zamanlı Konum Takibi** - Kullanıcının mevcut konumunu harita üzerinde gösterir
- 🗺️ **OpenStreetMap Entegrasyonu** - Ücretsiz ve açık kaynaklı harita
- 🔒 **Akıllı İzin Yönetimi** - iOS ve Android için konum izni isteme ve yönetme
- 🎯 **Konuma Gitme** - Tek tıkla mevcut konumunuza dönün
- 🔍 **Zoom Kontrolü** - Haritayı yakınlaştırma ve uzaklaştırma
- 🎬 **Animasyonlu Geçişler** - Pürüzsüz harita hareketleri

## 📦 Kullanılan Paketler

| Paket | Sürüm | Açıklama |
|-------|-------|----------|
| [flutter_map](https://pub.dev/packages/flutter_map) | ^8.2.2 | OpenStreetMap tabanlı harita widget'ı |
| [latlong2](https://pub.dev/packages/latlong2) | ^0.9.1 | Koordinat hesaplamaları |
| [geolocator](https://pub.dev/packages/geolocator) | ^14.0.2 | Konum servisleri ve izin yönetimi |
| [flutter_map_animations](https://pub.dev/packages/flutter_map_animations) | ^0.9.0 | Harita animasyonları |
| [url_launcher](https://pub.dev/packages/url_launcher) | ^6.3.2 | URL açma (atıf linkleri için) |

## 🚀 Kurulum

### 1. Projeyi Klonlayın

```bash
git clone https://github.com/kullanici_adi/maptracking.git
cd maptracking
```

### 2. Bağımlılıkları Yükleyin

```bash
flutter pub get
```

### 3. Platform Ayarları

#### iOS

`ios/Runner/Info.plist` dosyasına aşağıdaki izinleri ekleyin:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Uygulamanın haritada konumunuzu göstermek için konum bilgisine ihtiyacı var.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Uygulamanın arka planda konum takibi yapabilmesi için konum bilgisine ihtiyacı var.</string>
```

#### Android

`android/app/src/main/AndroidManifest.xml` dosyasına aşağıdaki izinleri ekleyin:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 4. Uygulamayı Çalıştırın

```bash
flutter run
```

## 📁 Proje Yapısı

```
lib/
├── main.dart                    # Uygulama giriş noktası
├── map/
│   └── map_view.dart            # Ana harita ekranı
└── permisson/
    ├── permission_service.dart  # Konum izni servisi
    └── permission_view.dart     # İzin isteme ekranı
```

## 🎮 Kullanım

1. **İlk Açılış**: Uygulama ilk açıldığında konum izni isteyecektir
2. **Harita Görüntüleme**: İzin verildikten sonra harita, mevcut konumunuz merkezli açılır
3. **Zoom**: Sağ alttaki `+` ve `-` butonları ile yakınlaştırma/uzaklaştırma
4. **Konuma Dön**: Haritayı kaydırdığınızda konum butonu görünür, tıklayarak konumunuza dönebilirsiniz

## 📸 Ekran Görüntüleri

*Ekran görüntüleri eklenecek*

## 🛠️ Geliştirme

### Gereksinimler

- Flutter SDK: ^3.10.7
- Dart SDK: ^3.0.0

### Çalıştırma

```bash
# Debug modunda
flutter run

# Release modunda
flutter run --release
```

### Test

```bash
flutter test
```

## 📄 Lisans

Bu proje MIT lisansı ile lisanslanmıştır.

## 🤝 Katkıda Bulunma

1. Projeyi fork edin
2. Feature branch oluşturun (`git checkout -b feature/yeni-ozellik`)
3. Değişikliklerinizi commit edin (`git commit -m 'Yeni özellik eklendi'`)
4. Branch'i push edin (`git push origin feature/yeni-ozellik`)
5. Pull Request açın

---

⭐ Bu projeyi beğendiyseniz star vermeyi unutmayın!
