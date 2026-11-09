# Vızır: Hız ve Macera Adası

6 yaşındaki çocuklar için araba yarışı ve macera oyunu. Oynarken hece birleştirmeyi, saymayı ve güzel ahlakı öğretir. İnternetsiz çalışır, reklam yoktur.

## Telefona kurma

1. Bu sayfada sağ taraftaki **Releases** bölümüne girin (ya da depo adresinin sonuna `/releases` ekleyin).
2. En üstteki sürümde `vizir-….apk` dosyasına dokunun ve indirin.
3. İndirilen dosyayı açın. Telefon "bilinmeyen kaynaklardan yükleme" izni isterse bu sefer için izin verin.
4. Yeni sürümler eskisinin üstüne kurulur, ilerleme kaybolmaz.

Her kod değişikliğinde GitHub APK'yı kendisi derler (Actions sekmesi). Derleme yaklaşık 5-8 dakika sürer.

## 1. aşamada neler var

- **İsim verme:** Çocuk kendi adını ve arabasının adını büyük harf klavyesiyle yazar; yazdıkça isim sesli okunur.
- **Garaj:** 3 gövde, 8 renk, 3 tekerlek. Kilitli parçalar yıldız, kalp ve kupayla açılır; açmak için hece tamiri yapılır.
- **Yarış:** 3 tur. Hece kapısında söylenen heceyi bulup oradan geçen araba turbo alır. Yol kenarındaki arızalı arabaya yardım eden iyilik kalbi kazanır.
- **Sonuç:** Toplanan jetonlar birlikte sayılır (en fazla 20).
- **Yakıt:** Günlük oyun süresi (varsayılan 30 dk). Bitince oyun kapanır. Gece kilidi 21:00 - 07:00.
- **Ebeveyn paneli:** Ana ekranın sol altındaki dişliye **uzun basın**. İlk açılışta 4 haneli şifre belirlenir. Süre, kitap/iyilik onayı (+10 dk), harf grubu, basamak, zorlanılan heceler ve isimler buradan yönetilir.

## Teknik

Flutter (Material 3), `flutter_tts` (Türkçe ses), `shared_preferences` (kayıt). Android klasörü derleme sırasında `flutter create` ile üretilir, ayarlar `tool/patch_android.py` ile yapılır. `tool/debug.keystore` güncellemelerin aynı imzayla kurulabilmesi içindir.
