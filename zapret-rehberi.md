# Zapret Kurulum Rehberi

## 1. Secure DNS aç

Ayarlar → Ağ ve İnternet → Wi-Fi (veya Ethernet) → bağlı ağına tıkla → **DNS sunucusu ataması** yanında **Düzenle** → açılır menüyü **El ile** yap → IPv4'ü aç → Tercih edilen DNS: `1.1.1.1` → Tercih edilen DNS şifrelemesi: **Yalnızca şifrelenmiş (HTTPS üzerinden DNS)** → Kaydet

> `1.1.1.1` çalışmazsa `8.8.8.8` dene.

## 2. İndir

[github.com/Flowseal/zapret-discord-youtube/releases/latest](https://github.com/Flowseal/zapret-discord-youtube/releases/latest) → sayfanın altındaki **Assets** bölümünden `.zip` dosyasını indir.

## 3. Çıkar

İndirilen ZIP'e sağ tık → **Özellikler** → alt kısımda **"Engellemeyi kaldır"** kutucuğu varsa işaretle → **Uygula** → Tamam.

> 7-Zip veya PeaZip kullanıyorsan bu adımı atlayabilirsin.

`C:\zapret\` klasörü oluştur, ZIP'in içindekileri oraya çıkar. Türkçe karakter, boşluk veya özel karakter içeren yol kullanma.

## 4. Dışlama ekle

Başlat → Ayarlar → Gizlilik ve güvenlik → Windows Güvenliği → **Virüs ve tehdit koruması** → **Ayarları yönet** → **Dışlamalar** altında **Dışlamaları ekle veya kaldır** → **+ Dışlama ekle** → **Klasör** → `C:\zapret` seç.

> `winws.exe` antivirüsler tarafından yanlış pozitif olarak yakalanır. WinDivert meşru bir paket filtreleme aracıdır, virüs değildir.

## 5. Çakışmaları kapat

`Win+R` → `services.msc` → Şu servisler varsa durdur: `goodbyedpi`, `zapret`, `SplitWire`, `WinDivert`. Aynı anda iki bypass aracı çalışamaz.

## 6. Çalışan stratejiyi bul

Klasörde birden fazla strateji dosyası var. Hangisinin çalışacağı ISP'ye göre değişir.

### Manuel deneme

1. `general.bat`'e **çift tıkla** → UAC çıkarsa **Evet**
2. Görev çubuğunda minimize `winws.exe` penceresi görünmeli
3. Discord'u aç, voice kanalına gir, test et

Çalışıyorsa → Adım 7'ye geç. Çalışmıyorsa:

- Görev çubuğundaki `winws.exe`'yi **X** ile kapat
- Sırayla diğer stratejileri dene:
    - `general (ALT).bat` → `general (ALT2).bat` → … → `general (ALT11).bat`
    - `general (FAKE TLS AUTO).bat` ve varyantları
    - `general (SIMPLE FAKE).bat` ve varyantları

Her denemeden önce **mevcut winws'i mutlaka kapat**.

### Otomatik strateji testi (Run Tests)

Tek tek denemek yerine otomatik test kullanabilirsin:

1. `service.bat` → sağ tık → **Yönetici olarak çalıştır**
2. **11 (Run Tests)** → **1 (Standard tests)** → **1 (All configs)**
3. Tüm stratejiler sırayla test edilir, sonunda **en iyi strateji** gösterilir

> Zapret servis olarak kuruluysa önce **2 (Remove Services)** ile kaldır.

### Discord voice "Connecting" takılıyor

Discord ses sunucularının bir kısmı IP seviyesinde engelli olabilir. Çözüm:

1. `service.bat` → sağ tık → **Yönetici olarak çalıştır**
2. **8 (Update Hosts File)** → Enter
3. Script güncel hosts listesini GitHub'dan indirir ve kontrol eder
4. Güncelleme gerekiyorsa iki pencere açılır:
    - **Not Defteri** → kopyalanacak içerik (bu penceredeki metni `Ctrl+A` → `Ctrl+C` ile kopyala)
    - **Dosya Gezgini** → hosts dosyasının bulunduğu klasör
5. `hosts` dosyasına sağ tık → **Not Defteri ile aç** (yönetici yetki isterse kabul et) → en alta yapıştır → `Ctrl+S` ile kaydet
6. Discord'u tamamen kapat ve yeniden aç

> "Hosts file is up to date" mesajı çıkarsa zaten günceldir, bir şey yapmana gerek yok.

## 7. Otomatik başlatmaya kur

Çalışan stratejiyi bulduysan, PC her açıldığında otomatik başlasın:

1. `winws.exe` penceresini **X** ile kapat
2. `service.bat` → sağ tık → **Yönetici olarak çalıştır**
3. **1 (Install Service)** → çalışan stratejinin numarasını seç → Enter

**Kaldırmak:** `service.bat` (yönetici) → **2 (Remove Services)**
**Durum kontrol:** `service.bat` → **3 (Check Status)**

---

## service.bat menü referansı

```
  :: SERVICE
     1. Install Service         → Stratejiyi servise kur
     2. Remove Services         → Servisi kaldır
     3. Check Status            → Durum kontrol

  :: SETTINGS
     4. Game Filter  [disabled] → Oyun portlarını filtrele
     5. IPSet Filter [none]     → IP listesi filtreleme
     6. Auto-Update  [enabled]  → Otomatik güncelleme kontrolü

  :: UPDATES
     7. Update IPSet List       → IP listesini güncelle
     8. Update Hosts File       → Discord voice düzelt
     9. Check for Updates       → Yeni sürüm kontrol

  :: TOOLS
     10. Run Diagnostics        → Sorun giderme (otomatik kontrol)
     11. Run Tests              → Otomatik strateji testi
```

---

## Sık Sorulan Sorular

> **İlk adım:** `service.bat` (yönetici) → **10 (Run Diagnostics)** — VPN, Adguard, Killer, SmartByte gibi çakışmaları ve yapılandırma hatalarını otomatik tespit eder.

| Sorun                        | Çözüm                                                     |
| ---------------------------- | --------------------------------------------------------- |
| winws görünmedi              | "Engellemeyi kaldır" yapılmamış (Adım 3)                  |
| winws virüs olarak yakalandı | Dışlama eksik (Adım 4)                                    |
| Voice takılıyor              | Update Hosts File (Adım 6)                                |
| Dün çalıştı bugün çalışmıyor | Başka strateji dene veya `Run Tests` ile otomatik test et |
| Boot sonrası kapalı          | `Install Service` yapmadın (Adım 7)                       |
| Oyun/uygulama bozuldu        | `Game Filter` → disabled, `IPSet Filter` → none yap       |
| Hiçbir strateji çalışmıyor   | `Run Diagnostics` çalıştır, sonra `Run Tests` ile test et |

---

## Gelişmiş kullanım

### Özel domain/IP ekleme

`lists\` klasöründeki `*-user.txt` dosyalarını düzenle (ilk çalışmada otomatik oluşturulur):

| Dosya                    | Amaç                |
| ------------------------ | ------------------- |
| `list-general-user.txt`  | Ek domain ekle      |
| `list-exclude-user.txt`  | Domain hariç tut    |
| `ipset-exclude-user.txt` | IP/alt ağ hariç tut |

---

## Güncelleme

Strateji çalışmayı bıraktığında veya ayda bir:

1. `service.bat` (yönetici) → **2 (Remove Services)**
2. **10 (Run Diagnostics)** → hata varsa düzelt
3. `C:\zapret` içini sil → [yeni ZIP indir](https://github.com/Flowseal/zapret-discord-youtube/releases/latest) → Adım 3'ten başla

## Bağlantılar

- Bundle: [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube)
- Son sürüm: [releases/latest](https://github.com/Flowseal/zapret-discord-youtube/releases/latest)
- Sorunlar: [issues](https://github.com/Flowseal/zapret-discord-youtube/issues)
- Orijinal zapret: [bol-van/zapret](https://github.com/bol-van/zapret)
