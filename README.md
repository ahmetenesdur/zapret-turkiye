# Zapret Türkiye

Türkiye'deki Discord erişim engelini **tek tıkla** aşmak için otomatik kurulum aracı.

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows)](https://www.microsoft.com/windows)
[![Based on](https://img.shields.io/badge/based%20on-zapret--discord--youtube-blue)](https://github.com/Flowseal/zapret-discord-youtube)

---

## Ne yapıyor?

Aşağıdaki 7 adımı **otomatik olarak** gerçekleştirir:

| #   | Adım                  | Açıklama                                                     |
| --- | --------------------- | ------------------------------------------------------------ |
| 1   | **DNS yapılandırma**  | Cloudflare `1.1.1.1` + DoH şifreleme (Win11 otomatik)        |
| 2   | **Son sürümü indir**  | GitHub'dan en güncel sürümü çeker                            |
| 3   | **Dosyaları çıkar**   | ZIP açma, güvenlik engelini kaldırma, klasör düzenleme       |
| 4   | **Defender dışlama**  | `C:\zapret` klasörünü antivirüsten dışlar                    |
| 5   | **Çakışma temizleme** | Eski bypass araçlarını (GoodbyeDPI vb.) tespit edip kaldırır |
| 6   | **Strateji testi**    | Tüm stratejileri sırayla dener, çalışanı otomatik bulur      |
| 7   | **Servis kurulumu**   | PC her açıldığında otomatik çalışacak şekilde kurar          |

---

## Kullanım

### 1. İndir

[**Releases**](https://github.com/ahmetenesdur/zapret-turkiye/releases/latest) sayfasından `zapret-kur.bat` dosyasını indir.

### 2. Çalıştır

İndirdiğin `zapret-kur.bat` dosyasına **çift tıkla**. Yönetici izni isterse **Evet** de.

### 3. Kur

Menüden **1** (Kur) seç ve bekle. Her şey otomatik.

```
=============================================
  ZAPRET TURKIYE KURULUM ARACI  v1.1
=============================================
  [ DURUM: KALKAN AKTIF ]
  Strateji: general

  1. Kur          (otomatik kurulum)
  2. Kaldir       (tamamen temizle)
  3. Guncelle     (yeni surum indir)
  4. Sorun Gider  (otomatik kontrol)
  0. Cikis

=============================================
```

> Otomatik araç yerine adım adım kendin kurmak istiyorsan: **[Manuel Kurulum Rehberi](zapret-rehberi.md)**

---

## SmartScreen Uyarısı

İnternetten indirilen `.bat` dosyalarında Windows güvenlik uyarısı çıkabilir. Bu normaldir:

> **"Windows bilgisayarınızı korudu"** mesajı çıkarsa:
>
> 1. **Ek bilgiler** bağlantısına tıkla
> 2. **Yine de çalıştır** butonuna tıkla

Dosyanın dijital imzası olmadığı için bu uyarı çıkar. Script tamamen açık kaynaklıdır — tüm kodu bu sayfada inceleyebilirsin.

---

## Menü Açıklamaları

### Kur (menü 1)

7 adımı otomatik çalıştırır. İnternet bağlantısı gereklidir (indirme öncesi otomatik kontrol edilir).

Strateji testi sırasında tüm stratejiler sırayla denenir — ilerleme `[3/19]`, geçen süre ve sonuç özeti gösterilir. İlk başarılı strateji seçilir, servis olarak kurulur ve Discord erişimi doğrulanır. Bu adım ISP bağlantısına göre **2–5 dakika** sürebilir.

Kurulum sonucu `C:\zapret\install.log` dosyasına kaydedilir.

### Kaldır (menü 2)

Zapret'i tamamen kaldırır:

- Servisleri durdurur ve siler
- WinDivert driver kalıntılarını temizler
- `C:\zapret` klasörünü siler
- Defender dışlamasını kaldırır
- İstersen DNS ayarını da sıfırlar

### Güncelle (menü 3)

Mevcut strateji, kurulu sürüm ve son sürümü yan yana gösterir. Onaylarsan eski kurulumu temizleyip yeni sürümü kurar. DNS ayarına dokunmaz.

### Sorun Gider (menü 4)

Sistemini otomatik tarar ve olası sorunları raporlar:

| Kontrol              | Ne bakıyor?                                      |
| -------------------- | ------------------------------------------------ |
| BFE                  | Base Filtering Engine çalışıyor mu?              |
| Zapret servisi       | Kurulu ve çalışıyor mu?                          |
| Proxy                | Sistem proxy aktif mi? (Çakışma riski)           |
| TCP Timestamps       | Aktif mi? (Pasifse otomatik düzeltir)            |
| VPN                  | Aktif VPN var mı? (Zapret ile çakışır)           |
| Adguard              | Reklam engelleyici Discord'u bozabiliyor         |
| Killer               | Killer Network servisleri çakışır                |
| Intel Connectivity   | Intel Connectivity Network Service çakışır       |
| Check Point          | Check Point güvenlik servisleri çakışır          |
| SmartByte            | Dell SmartByte çakışır                           |
| Çakışan araçlar      | GoodbyeDPI, SplitWire gibi diğer bypass araçları |
| DNS                  | Uygun DNS (1.1.1.1 veya 8.8.8.8) ayarlı mı?     |
| winws.exe            | Binary mevcut mu?                                |
| WinDivert driver     | Driver dosyası mevcut mu?                        |
| Discord API          | Gateway bağlantı testi                           |
| Discord CDN          | İçerik dağıtım ağı testi                         |
| Discord Media        | Ses/görüntü sunucusu testi                       |

Tarama sonrasında istersen strateji testini yeniden çalıştırabilirsin.

---

## Sık Sorulan Sorular

### Zapret çalışıyor ama Discord voice "Connecting" de takılıyor

Metin kanalları açılıyor ama sesli kanala bağlanamıyorsan, bazı Discord ses sunucuları IP seviyesinde engelli olabilir.

Bu durum `zapret-kur.bat` tarafından otomatik çözülmez — upstream aracın kendi `service.bat` menüsünden yapılır:

1. `C:\zapret\service.bat` → sağ tık → **Yönetici olarak çalıştır**
2. **8** seç → Enter
3. Script güncel hosts listesini kontrol eder
4. Güncelleme gerekiyorsa **Not Defteri** açılır → `Ctrl+A` → `Ctrl+C` ile kopyala
5. Aynı anda açılan **Dosya Gezgini**'nde `hosts` dosyasını Not Defteri ile aç
6. En alta yapıştır → `Ctrl+S` ile kaydet
7. Discord'u tamamen kapatıp yeniden aç

> "Hosts file is up to date" mesajı çıkarsa zaten günceldir, bir şey yapma.

---

### Dün çalışıyordu bugün çalışmıyor

ISP'ler filtreleme yöntemlerini zaman zaman değiştirebilir:

1. `zapret-kur.bat` → **4** (Sorun Gider) ile diagnostik çalıştır
2. Sorun tespit edilemezse strateji testini tekrar yap (araç soracaktır)
3. Hâlâ çalışmıyorsa **3** (Güncelle) ile son sürümü kur — yeni stratejiler eklenmiş olabilir

---

### winws.exe antivirüs tarafından siliniyor

`winws.exe`, [WinDivert](https://github.com/basil00/WinDivert) tabanlı meşru bir paket filtreleme aracıdır. Antivirüsler bunu yanlış pozitif (false positive) olarak işaretleyebilir — virüs **değildir**.

Araç kurulum sırasında Windows Defender dışlamasını otomatik ekler. Başka antivirüs (Kaspersky, ESET, Avast vb.) kullanıyorsan `C:\zapret` klasörünü o programın ayarlarından elle dışla.

---

### Bir oyun veya uygulama düzgün çalışmıyor

Zapret normalde sadece engelli sitelerin trafiğini etkiler, ama nadir durumlarda başka uygulamaları etkileyebilir:

1. `C:\zapret\service.bat` → sağ tık → **Yönetici olarak çalıştır**
2. **Game Filter** ayarını `disabled` yap
3. **IPSet Filter** ayarını `none` yap

---

### Hiçbir strateji çalışmıyor

1. **VPN kapalı** olduğundan emin ol — VPN ve Zapret birlikte çalışmaz
2. `zapret-kur.bat` → **4** (Sorun Gider) ile diagnostik çalıştır
3. Adguard veya benzeri reklam engelleyici varsa geçici olarak kapat
4. DNS'i `8.8.8.8` olarak değiştirmeyi dene
5. Farklı bir ağda test et (örn. telefondan hotspot) — sorun ağa özel mi anla

---

## Teknik Detaylar

<details>
<summary><b>Zapret nasıl çalışıyor?</b></summary>

Zapret, DPI (Deep Packet Inspection) engellerini aşmak için TCP/UDP paketlerini modifiye eden bir araçtır.

```
Bilgisayarın → [Zapret: paket modifikasyonu] → ISP (DPI) → Discord
```

- **WinDivert** driver'ı ile ağ paketlerini yakalar
- TTL, window size, fake packet gibi tekniklerle DPI'ı atlatır
- Sadece belirli domainlere uygulanır, genel internet trafiğini etkilemez
- Windows servisi olarak arka planda sessizce çalışır

</details>

<details>
<summary><b>zapret-kur.bat ne yapıyor? (geliştiriciler için)</b></summary>

BAT/PowerShell hybrid script — karmaşık adımları temp `.ps1` dosyaları ile çalıştırır:

1. **Admin yükseltme** — UAC ile `RunAs`
2. **DNS** — `Set-DnsClientServerAddress` + Win11'de `Add-DnsClientDohServerAddress`
3. **İnternet kontrolü** — İndirme öncesi `api.github.com` erişim testi
4. **İndirme** — GitHub Releases API → `Invoke-WebRequest` + sürüm kaydetme
5. **Çıkarma** — `Expand-Archive` + `Unblock-File` + nested folder düzeltme
6. **Defender** — `Add-MpPreference -ExclusionPath`
7. **Çakışma** — 8 bilinen servis için `Get-Service` → `sc.exe delete`
8. **Strateji testi** — Her strateji BAT'ını `Start-Process -WindowStyle Hidden` ile çalıştırır, `discord.com/api/v10/gateway` endpoint'ine GET isteği ile test eder. Süre ve ilerleme gösterilir
9. **Servis** — BAT dosyasından `winws.exe` argümanlarını parse eder → `New-Service` ile Windows servisi oluşturur → upstream sürümünü Registry'ye kaydeder
10. **Doğrulama** — Servis kurulunca Discord erişim testi yapılır
11. **Loglama** — Sonuçlar `C:\zapret\install.log` dosyasına yazılır

</details>

---

## Bağlantılar

|                     |                                                                                       |
| ------------------- | ------------------------------------------------------------------------------------- |
| **Zapret Bundle**   | [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube) |
| **Son sürüm**       | [releases/latest](https://github.com/Flowseal/zapret-discord-youtube/releases/latest) |
| **Sorun bildir**    | [issues](https://github.com/ahmetenesdur/zapret-turkiye/issues)                       |
| **Orijinal Zapret** | [bol-van/zapret](https://github.com/bol-van/zapret)                                   |

---

## Yasal Uyarı

Bu yazılım **eğitim ve araştırma amaçlı** olup ağ paketlerinin işlenme biçimini ve DPI sistemlerinin çalışma mantığını göstermek için tasarlanmıştır. Herhangi bir yasa dışı faaliyeti teşvik veya destek amacı taşımaz.

- Bu yazılım **"olduğu gibi" (as-is)** sunulur; yazarlar hiçbir garanti vermez ve kullanımdan doğabilecek **hiçbir zarardan sorumlu tutulamaz**.
- Yazılımı indiren, kuran veya çalıştıran her kullanıcı **kendi ülkesinin yürürlükteki yasalarına uymakla yükümlüdür**. Türkiye'de internet erişimine ilişkin düzenlemeler 5651 sayılı Kanun kapsamındadır. **Kullanımdan doğan tüm sorumluluk kullanıcıya aittir.**
- Yazarlar bu aracın herhangi bir ülkede yasal olduğunu taahhüt etmez; kullanım öncesinde hukuki danışmanlık almanız önerilir.

[MIT Lisansı](LICENSE) altında lisanslanmıştır.
