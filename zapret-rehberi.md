# Zapret Manuel Kurulum Rehberi

> Bu rehber, otomatik kurulum aracı (`zapret-kur.bat`) yerine **adım adım elle kurulum** yapmak isteyenler içindir. Otomatik kurulum aracı tüm bu adımları tek tıkla yapar — [README](README.md) dosyasına bak.

## 1. Secure DNS aç

Ayarlar → Ağ ve İnternet → Wi-Fi (veya Ethernet) → bağlı ağına tıkla → **DNS sunucusu ataması** yanında **Düzenle** → açılır menüyü **El ile** yap → IPv4'ü aç → Tercih edilen DNS: `1.1.1.1` → Tercih edilen DNS şifrelemesi: **Yalnızca şifrelenmiş (HTTPS üzerinden DNS)** → Kaydet

> `1.1.1.1` çalışmazsa `8.8.8.8` dene. DNS şifrelemesi (DoH) ISP'nin DNS sorgularını manipüle etmesini engeller.

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

`Win+R` → `services.msc` → Şu servisler varsa durdur: `goodbyedpi`, `zapret`, `SplitWire`, `WinDivert`. Aynı anda iki bypass aracı çalışamaz. VPN kullanıyorsan onu da kapat.

## 6. Çalışan stratejiyi bul

Türkiye'deki ISP'lerin DPI yapılandırmaları farklılık gösterdiği için **bundle'daki hazır stratejiler genellikle çalışmaz**. Aşağıdaki yöntemleri sırayla dene:

### Yöntem A: ISP presetini dene (önerilen — en hızlı)

Aşağıdaki presetler Türkiye'deki ISP'ler için topluluk tarafından test edilmiştir. Kendi ISP'ine uygun satırı bul ve `winws.exe`'yi bu parametrelerle çalıştır:

| ISP | Komut |
|-----|-------|
| **Türk Telekom** | `C:\zapret\bin\winws.exe --wf-tcp=80,443 --wf-udp=443,50000,50100 --dpi-desync=fake --dpi-desync-ttl=4` |
| **Türk Telekom (ALT)** | `C:\zapret\bin\winws.exe --wf-tcp=80,443 --wf-udp=443,50000,50100 --dpi-desync=fake --dpi-desync-ttl=3` |
| **Superonline** | `C:\zapret\bin\winws.exe --wf-tcp=80,443 --wf-udp=443,50000,50100 --dpi-desync=fake --dpi-desync-fooling=md5sig` |
| **Superonline (ALT)** | `C:\zapret\bin\winws.exe --wf-tcp=80,443 --wf-udp=443,50000-50099 --dpi-desync=fake --dpi-desync-fooling=md5sig --dpi-desync-ttl=3` |
| **Kablonet** | `C:\zapret\bin\winws.exe --wf-tcp=80,443 --wf-udp=443,50000,50100 --dpi-desync=fake --dpi-desync-ttl=4` |
| **Turkcell Hotspot** | `C:\zapret\bin\winws.exe --wf-tcp=80,443 --wf-udp=443,50000,50100 --dpi-desync=fake --dpi-desync-ttl=1 --dpi-desync-autottl=3` |
| **Vodafone Hotspot** | `C:\zapret\bin\winws.exe --wf-tcp=80,443 --wf-udp=443,50000,50100 --dpi-desync=multisplit --dpi-desync-split-pos=2` |

**Nasıl denerim?**

1. **Komut İstemi'ni yönetici olarak aç** (`Win+X` → Terminal (Yönetici))
2. ISP'ine uygun komutu kopyala yapıştır ve Enter
3. Discord'u aç, test et
4. Çalışıyorsa → Adım 7'ye geç
5. Çalışmıyorsa → komut penceresini kapat, alternatif preseti veya Yöntem B'yi dene

> ISP'ni bilmiyorsan: Ayarlar → Ağ ve İnternet → bağlı ağına tıkla → "Özellikler" kısmında görebilirsin. Veya [whatismyisp.com](https://www.whatismyisp.com) adresinden öğren.

### Yöntem B: blockcheck ile otomatik tespit (gelişmiş)

Presetler çalışmazsa, `zapret-win-bundle` içindeki `blockcheck` aracıyla ISP'ine özel parametreleri otomatik tespit edebilirsin. Bu araç, yüzlerce parametre kombinasyonunu sistematik olarak test eder.

#### Hazırlık

1. [github.com/bol-van/zapret-win-bundle](https://github.com/bol-van/zapret-win-bundle/releases) → en güncel sürümü indir ve bir klasöre çıkar
2. **Tüm bypass araçlarını kapat** (VPN, GoodbyeDPI, mevcut zapret servisi vb.)
3. Antivirüs WinDivert'i engelliyorsa `blockcheck` klasörünü dışlamaya ekle

#### Çalıştırma

1. `blockcheck` klasörüne gir
2. `blockcheck.cmd`'ye sağ tık → **Yönetici olarak çalıştır**
3. Program engelli bir domain soracak → `discord.com` yaz ve Enter
4. Protokol ve IP sürümü sorularını onayla
5. Analiz başlar — **10-30 dakika** sürebilir, sabırla bekle

#### Sonuçları kullanma

1. Analiz bittiğinde `blockcheck.log` dosyası oluşur
2. Log dosyasını aç ve **"WORKING"** veya **"SUCCESS"** yazan satırları bul
3. Bu satırlarda `winws.exe` için gerekli parametreler yer alır (örn. `--dpi-desync=fake --dpi-desync-ttl=4`)
4. Bu parametreleri Adım 7'de servis kurarken kullan

> **İpucu:** `blockcheck2.cmd` daha yeni motoru (winws2) kullanır. Standart blockcheck sonuç vermezse bunu da dene.

### Yöntem C: Bundle stratejilerini elle dene (son çare)

Yukarıdaki yöntemler çalışmazsa, bundle'daki hazır stratejileri sırayla deneyebilirsin:

1. `C:\zapret` klasöründeki strateji BAT dosyalarından birine **çift tıkla** (örn. `general.bat`)
2. Görev çubuğunda minimize `winws.exe` penceresi görünmeli
3. Discord'u aç, test et
4. Çalışıyorsa → Adım 7'ye geç. Çalışmıyorsa → `winws.exe`'yi kapat, sonraki BAT'ı dene

> Her denemeden önce **mevcut winws sürecini mutlaka kapat**.

### Discord voice "Connecting" takılıyor

Discord metin kanalları açılıyor ama sesli kanala bağlanamıyorsan, bazı ses sunucuları IP seviyesinde engelli olabilir:

1. `C:\zapret\service.bat` → sağ tık → **Yönetici olarak çalıştır**
2. **8 (Update Hosts File)** → Enter
3. Script güncel hosts listesini GitHub'dan indirir ve kontrol eder
4. Güncelleme gerekiyorsa iki pencere açılır:
    - **Not Defteri** → kopyalanacak içerik (`Ctrl+A` → `Ctrl+C`)
    - **Dosya Gezgini** → hosts dosyasının bulunduğu klasör
5. `hosts` dosyasına sağ tık → **Not Defteri ile aç** → en alta yapıştır → `Ctrl+S` ile kaydet
6. Discord'u tamamen kapat ve yeniden aç

> "Hosts file is up to date" mesajı çıkarsa zaten günceldir, bir şey yapmana gerek yok.

## 7. Otomatik başlatmaya kur

Çalışan stratejiyi bulduysan, PC her açıldığında otomatik başlasın.

### Preset veya blockcheck ile bulduysan

Çalışan parametreleri biliyorsan, doğrudan Windows servisi oluşturabilirsin:

1. **Komut İstemi'ni yönetici olarak aç**
2. Aşağıdaki komutu ISP'ine göre düzenle ve çalıştır:

```cmd
sc create zapret binPath= "C:\zapret\bin\winws.exe --wf-tcp=80,443 --wf-udp=443,50000,50100 --dpi-desync=fake --dpi-desync-ttl=4" start= auto DisplayName= "zapret"
sc start zapret
```

> `binPath=` kısmına kendi çalışan parametrelerini yaz. Eşittir işaretinden sonraki boşluk **zorunludur**.

**Kaldırmak:**

```cmd
sc stop zapret
sc delete zapret
```

### Bundle strateji BAT'ı ile bulduysan

1. `winws.exe` penceresini **X** ile kapat
2. `C:\zapret\service.bat` → sağ tık → **Yönetici olarak çalıştır**
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

| Sorun                        | Çözüm                                                        |
| ---------------------------- | ------------------------------------------------------------- |
| winws görünmedi              | "Engellemeyi kaldır" yapılmamış (Adım 3)                     |
| winws virüs olarak yakalandı | Dışlama eksik (Adım 4)                                       |
| Voice takılıyor              | Update Hosts File (Adım 6)                                   |
| Dün çalıştı bugün çalışmıyor | ISP'in DPI değişmiş olabilir — blockcheck ile yeniden test et |
| Boot sonrası kapalı          | Servis kurmadın (Adım 7)                                     |
| Oyun/uygulama bozuldu        | `Game Filter` → disabled, `IPSet Filter` → none yap          |
| Hiçbir strateji çalışmıyor   | ISP presetlerini dene, ardından blockcheck kullan (Adım 6)    |

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

1. Servisi kaldır: `sc stop zapret && sc delete zapret` (veya `service.bat` → **2**)
2. `C:\zapret` içini sil → [yeni ZIP indir](https://github.com/Flowseal/zapret-discord-youtube/releases/latest) → Adım 3'ten başla
3. Yeni sürümle birlikte blockcheck'i de yeniden çalıştırman gerekebilir — ISP'ler zaman zaman DPI yapılandırmalarını günceller

## Bağlantılar

- Bundle: [Flowseal/zapret-discord-youtube](https://github.com/Flowseal/zapret-discord-youtube)
- Son sürüm: [releases/latest](https://github.com/Flowseal/zapret-discord-youtube/releases/latest)
- Zapret Win Bundle (blockcheck dahil): [bol-van/zapret-win-bundle](https://github.com/bol-van/zapret-win-bundle)
- Orijinal zapret: [bol-van/zapret](https://github.com/bol-van/zapret)
- Sorunlar: [issues](https://github.com/ahmetenesdur/zapret-turkiye/issues)
