@echo off
:: =====================================================
:: ZAPRET TURKIYE KURULUM ARACI
:: Tek tikla Discord erisim sorununu coz
:: https://github.com/ahmetenesdur/zapret-turkiye
:: =====================================================
setlocal EnableDelayedExpansion
set "VERSION=1.0"
set "ZAPRET_PATH=C:\zapret"

:: Turkce karakter (sadece menu icin, PS kendi halleder)
chcp 1254 >nul 2>&1

:: Admin kontrolu
if "%~1"=="admin" goto main

:: Admin degilse yukselt
powershell -NoProfile -Command "Start-Process 'cmd.exe' -ArgumentList '/c \"\"%~f0\" admin\"' -Verb RunAs" 2>nul
exit /b


:main
:: =====================================================
:: ANA MENU
:: =====================================================
:menu
cls
echo.
echo   =============================================
echo     ZAPRET TURKIYE KURULUM ARACI  v%VERSION%
echo   =============================================
echo.
echo     1. Kur          (otomatik kurulum)
echo     2. Kaldir       (tamamen temizle)
echo     3. Guncelle     (yeni surum indir)
echo     4. Sorun Gider  (otomatik kontrol)
echo     0. Cikis
echo.
echo   =============================================
echo.
set "choice="
set /p "choice=   Secenek (0-4): "

if "%choice%"=="1" goto install
if "%choice%"=="2" goto uninstall
if "%choice%"=="3" goto update
if "%choice%"=="4" goto troubleshoot
if "%choice%"=="0" exit /b
goto menu


:: =====================================================
:: KUR - OTOMATIK KURULUM
:: =====================================================
:install
cls
echo.

:: ----- ADIM 1: DNS -----
call :PrintStep "1" "7" "DNS ayarlaniyor..."

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ErrorActionPreference='SilentlyContinue';" ^
 "try {" ^
 "  $a=Get-NetAdapter|Where-Object{$_.Status -eq 'Up' -and $_.InterfaceDescription -notmatch 'VPN|TAP|Virtual|Hyper-V|Wintun|Loopback'};" ^
 "  if(-not $a){Write-Host '  Aktif ag adaptoru bulunamadi' -ForegroundColor Yellow}else{" ^
 "  foreach($i in $a){Set-DnsClientServerAddress -InterfaceIndex $i.ifIndex -ServerAddresses @('1.1.1.1','1.0.0.1')};" ^
 "  $b=[Environment]::OSVersion.Version.Build;" ^
 "  if($b -ge 22000){" ^
 "    try{Add-DnsClientDohServerAddress -ServerAddress '1.1.1.1' -DohTemplate 'https://cloudflare-dns.com/dns-query' -AllowFallbackToUdp $false -AutoUpgrade $true -ErrorAction SilentlyContinue}catch{};" ^
 "    try{Add-DnsClientDohServerAddress -ServerAddress '1.0.0.1' -DohTemplate 'https://cloudflare-dns.com/dns-query' -AllowFallbackToUdp $false -AutoUpgrade $true -ErrorAction SilentlyContinue}catch{};" ^
 "    Write-Host '  DNS ayarlandi (Cloudflare + DoH sifreleme)' -ForegroundColor Green" ^
 "  }else{Write-Host '  DNS ayarlandi (Cloudflare)' -ForegroundColor Green}" ^
 "  }" ^
 "} catch {Write-Host '  DNS ayarlanamadi - rehberden manuel ayarla' -ForegroundColor Yellow}"

echo.

:: ----- ADIM 2: INDIR -----
:install_step2
call :PrintStep "2" "7" "Son surum indiriliyor..."

set "S2=%TEMP%\zapret_s2.ps1"
del "%S2%" 2>nul
>"%S2%"  echo $ErrorActionPreference = 'Stop'
>>"%S2%" echo try {
>>"%S2%" echo     $release = Invoke-RestMethod 'https://api.github.com/repos/Flowseal/zapret-discord-youtube/releases/latest' -TimeoutSec 15
>>"%S2%" echo     $asset = $release.assets ^| Where-Object { $_.name -like '*.zip' } ^| Select-Object -First 1
>>"%S2%" echo     if (-not $asset) { throw 'ZIP bulunamadi' }
>>"%S2%" echo     $url = $asset.browser_download_url
>>"%S2%" echo     $ver = $release.tag_name
>>"%S2%" echo     $zip = "$env:TEMP\zapret_$ver.zip"
>>"%S2%" echo     Write-Host "  Surum: $ver" -ForegroundColor Gray
>>"%S2%" echo     $ProgressPreference = 'Continue'
>>"%S2%" echo     Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
>>"%S2%" echo     Set-Content -Path "$env:TEMP\zapret_zip.txt" -Value $zip -NoNewline
>>"%S2%" echo     Write-Host '  Indirme tamamlandi' -ForegroundColor Green
>>"%S2%" echo } catch {
>>"%S2%" echo     Write-Host "  Indirme basarisiz: $_" -ForegroundColor Red
>>"%S2%" echo     Write-Host '  Internet baglantini kontrol et' -ForegroundColor Yellow
>>"%S2%" echo     exit 1
>>"%S2%" echo }

powershell -NoProfile -ExecutionPolicy Bypass -File "%S2%"
if errorlevel 1 (del "%S2%" 2>nul & pause & goto menu)
del "%S2%" 2>nul
echo.

:: ----- ADIM 3: CIKAR -----
call :PrintStep "3" "7" "Dosyalar cikariliyor..."

set "S3=%TEMP%\zapret_s3.ps1"
del "%S3%" 2>nul
>"%S3%"  echo $ErrorActionPreference = 'Stop'
>>"%S3%" echo $zip = Get-Content "$env:TEMP\zapret_zip.txt"
>>"%S3%" echo $target = 'C:\zapret'
>>"%S3%" echo try {
>>"%S3%" echo     if (Test-Path $target) {
>>"%S3%" echo         $svc = Get-Service -Name 'zapret' -ErrorAction SilentlyContinue
>>"%S3%" echo         if ($svc) { Stop-Service 'zapret' -Force -ErrorAction SilentlyContinue; sc.exe delete 'zapret' 2^>$null ^| Out-Null }
>>"%S3%" echo         Get-Process -Name 'winws' -ErrorAction SilentlyContinue ^| Stop-Process -Force
>>"%S3%" echo         Start-Sleep -Seconds 1
>>"%S3%" echo         Remove-Item $target -Recurse -Force
>>"%S3%" echo     }
>>"%S3%" echo     Unblock-File -Path $zip
>>"%S3%" echo     Expand-Archive -Path $zip -DestinationPath $target -Force
>>"%S3%" echo     $inner = Get-ChildItem $target -Directory ^| Where-Object { Test-Path (Join-Path $_.FullName 'bin') } ^| Select-Object -First 1
>>"%S3%" echo     if ($inner) {
>>"%S3%" echo         Get-ChildItem $inner.FullName -Force ^| Move-Item -Destination $target -Force
>>"%S3%" echo         Remove-Item $inner.FullName -Recurse -Force
>>"%S3%" echo     }
>>"%S3%" echo     if (-not (Test-Path "$target\bin\winws.exe")) { throw 'winws.exe bulunamadi' }
>>"%S3%" echo     Remove-Item $zip -Force -ErrorAction SilentlyContinue
>>"%S3%" echo     Remove-Item "$env:TEMP\zapret_zip.txt" -Force -ErrorAction SilentlyContinue
>>"%S3%" echo     Write-Host '  Dosyalar cikarildi: C:\zapret' -ForegroundColor Green
>>"%S3%" echo } catch {
>>"%S3%" echo     Write-Host "  Cikarma hatasi: $_" -ForegroundColor Red
>>"%S3%" echo     exit 1
>>"%S3%" echo }

powershell -NoProfile -ExecutionPolicy Bypass -File "%S3%"
if errorlevel 1 (del "%S3%" 2>nul & pause & goto menu)
del "%S3%" 2>nul
echo.

:: ----- ADIM 4: DEFENDER DISLAMA -----
call :PrintStep "4" "7" "Defender dislamasi ekleniyor..."

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "try{Add-MpPreference -ExclusionPath 'C:\zapret' -ErrorAction Stop;" ^
 "Write-Host '  Defender dislamasi eklendi' -ForegroundColor Green" ^
 "}catch{Write-Host '  Defender dislamasi eklenemedi - baska antivirus varsa elle disla' -ForegroundColor Yellow}"

echo.

:: ----- ADIM 5: CAKISMA TEMIZLEME -----
call :PrintStep "5" "7" "Cakismalar kontrol ediliyor..."

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$found=0;" ^
 "foreach($n in @('goodbyedpi','zapret','SplitWire','WinDivert','WinDivert14','discordfix_zapret','winws1','winws2')){" ^
 "  $s=Get-Service -Name $n -EA SilentlyContinue;" ^
 "  if($s){Stop-Service $n -Force -EA SilentlyContinue;sc.exe delete $n 2>$null|Out-Null;$found++;Write-Host \"  Kaldirildi: $n\" -ForegroundColor Yellow}" ^
 "};" ^
 "Get-Process -Name 'winws' -EA SilentlyContinue|Stop-Process -Force;" ^
 "if($found -eq 0){Write-Host '  Cakisma bulunamadi' -ForegroundColor Green}else{Write-Host \"  $found cakisan servis kaldirildi\" -ForegroundColor Green}"

echo.

:: ----- ADIM 6: STRATEJI TESTI -----
:install_step6
call :PrintStep "6" "7" "En iyi strateji araniyor (bu adim birkac dakika surebilir)..."
echo.

set "S6=%TEMP%\zapret_s6.ps1"
del "%S6%" 2>nul
>"%S6%"  echo $zapret = 'C:\zapret'
>>"%S6%" echo $strategies = Get-ChildItem "$zapret\*.bat" ^| Where-Object { $_.Name -notlike 'service*' } ^| Sort-Object { [Regex]::Replace($_.Name, '(\d+)', { $args[0].Value.PadLeft(8,'0') }) }
>>"%S6%" echo $total = $strategies.Count
>>"%S6%" echo $best = $null
>>"%S6%" echo $i = 0
>>"%S6%" echo foreach ($bat in $strategies) {
>>"%S6%" echo     $i++
>>"%S6%" echo     Write-Host "  [$i/$total] $($bat.Name)..." -NoNewline
>>"%S6%" echo     try { $proc = Start-Process -FilePath $bat.FullName -PassThru -WindowStyle Hidden -ErrorAction Stop } catch { Write-Host ' ATLANDI' -ForegroundColor DarkGray; continue }
>>"%S6%" echo     Start-Sleep -Seconds 4
>>"%S6%" echo     $ok = $false
>>"%S6%" echo     try { $r = Invoke-WebRequest 'https://discord.com/api/v10/gateway' -TimeoutSec 8 -UseBasicParsing -ErrorAction Stop; if ($r.StatusCode -eq 200) { $ok = $true } } catch {}
>>"%S6%" echo     Get-Process -Name 'winws' -ErrorAction SilentlyContinue ^| Stop-Process -Force
>>"%S6%" echo     Start-Sleep -Seconds 1
>>"%S6%" echo     if ($ok) {
>>"%S6%" echo         Write-Host ' BASARILI' -ForegroundColor Green
>>"%S6%" echo         $best = $bat.Name
>>"%S6%" echo         break
>>"%S6%" echo     } else {
>>"%S6%" echo         Write-Host ' -' -ForegroundColor DarkGray
>>"%S6%" echo     }
>>"%S6%" echo }
>>"%S6%" echo if ($best) {
>>"%S6%" echo     Set-Content -Path "$env:TEMP\zapret_best.txt" -Value $best -NoNewline
>>"%S6%" echo     Write-Host ''
>>"%S6%" echo     Write-Host "  En iyi strateji: $best" -ForegroundColor Green
>>"%S6%" echo } else {
>>"%S6%" echo     Write-Host ''
>>"%S6%" echo     Write-Host '  Hicbir strateji calismadi.' -ForegroundColor Red
>>"%S6%" echo     Write-Host '  Sorun Gider (menu 4) ile kontrol et.' -ForegroundColor Yellow
>>"%S6%" echo     exit 1
>>"%S6%" echo }

powershell -NoProfile -ExecutionPolicy Bypass -File "%S6%"
if errorlevel 1 (del "%S6%" 2>nul & pause & goto menu)
del "%S6%" 2>nul

set /p BEST_STRATEGY=<"%TEMP%\zapret_best.txt"
del "%TEMP%\zapret_best.txt" 2>nul
echo.

:: ----- ADIM 7: SERVIS KURULUMU -----
:install_step7
call :PrintStep "7" "7" "Servis kuruluyor..."

set "S7=%TEMP%\zapret_s7.ps1"
del "%S7%" 2>nul
>"%S7%"  echo $best = '%BEST_STRATEGY%'
>>"%S7%" echo $zapret = 'C:\zapret'
>>"%S7%" echo $binPath = "$zapret\bin\"
>>"%S7%" echo $listsPath = "$zapret\lists\"
>>"%S7%" echo # BAT dosyasindan winws.exe argumanlari cikar
>>"%S7%" echo $lines = Get-Content "$zapret\$best"
>>"%S7%" echo $capture = $false
>>"%S7%" echo $parts = @()
>>"%S7%" echo foreach ($line in $lines) {
>>"%S7%" echo     if ($line -match 'winws\.exe') {
>>"%S7%" echo         $capture = $true
>>"%S7%" echo         $p = $line -replace '^.*winws\.exe[\"'']?\s*', ''
>>"%S7%" echo         $p = $p -replace '\s*\^\s*$', ''
>>"%S7%" echo         if ($p.Trim()) { $parts += $p.Trim() }
>>"%S7%" echo     } elseif ($capture) {
>>"%S7%" echo         $c = $line.Trim() -replace '\s*\^\s*$', ''
>>"%S7%" echo         if ($c) { $parts += $c }
>>"%S7%" echo         if ($line -notmatch '\^\s*$') { $capture = $false }
>>"%S7%" echo     }
>>"%S7%" echo }
>>"%S7%" echo $finalArgs = ($parts -join ' ')
>>"%S7%" echo # Path ve filtre degiskenlerini gercek degerlerle degistir
>>"%S7%" echo # BAT echo %% -> PS dosyasinda %% olur (BAT var expansion)
>>"%S7%" echo $finalArgs = $finalArgs -replace '%%BIN%%', $binPath
>>"%S7%" echo $finalArgs = $finalArgs -replace '%%LISTS%%', $listsPath
>>"%S7%" echo $finalArgs = $finalArgs -replace '%%GameFilter%%', '12'
>>"%S7%" echo $finalArgs = $finalArgs -replace '%%GameFilterTCP%%', '12'
>>"%S7%" echo $finalArgs = $finalArgs -replace '%%GameFilterUDP%%', '12'
>>"%S7%" echo # Servisi olustur
>>"%S7%" echo net stop zapret 2^>$null ^| Out-Null
>>"%S7%" echo sc.exe delete zapret 2^>$null ^| Out-Null
>>"%S7%" echo Start-Sleep -Seconds 1
>>"%S7%" echo netsh interface tcp set global timestamps=enabled 2^>$null ^| Out-Null
>>"%S7%" echo $svcBin = "`"$($binPath)winws.exe`" $finalArgs"
>>"%S7%" echo try {
>>"%S7%" echo     New-Service -Name 'zapret' -BinaryPathName $svcBin -DisplayName 'zapret' -StartupType Automatic -ErrorAction Stop
>>"%S7%" echo } catch {
>>"%S7%" echo     Write-Host "  Servis olusturulamadi: $_" -ForegroundColor Red
>>"%S7%" echo     exit 1
>>"%S7%" echo }
>>"%S7%" echo sc.exe description zapret 'Zapret DPI bypass - Discord' 2^>$null ^| Out-Null
>>"%S7%" echo Start-Service -Name 'zapret' -ErrorAction SilentlyContinue
>>"%S7%" echo Start-Sleep -Seconds 2
>>"%S7%" echo $svc = Get-Service -Name 'zapret' -ErrorAction SilentlyContinue
>>"%S7%" echo if ($svc -and $svc.Status -eq 'Running') {
>>"%S7%" echo     reg add 'HKLM\System\CurrentControlSet\Services\zapret' /v 'zapret-discord-youtube' /t REG_SZ /d $best /f 2^>$null ^| Out-Null
>>"%S7%" echo     Write-Host '  Servis kuruldu ve calisiyor' -ForegroundColor Green
>>"%S7%" echo     Write-Host "  Strateji: $best" -ForegroundColor Gray
>>"%S7%" echo } else {
>>"%S7%" echo     Write-Host '  Servis baslatilamadi' -ForegroundColor Red
>>"%S7%" echo     Write-Host '  Sorun Gider (menu 4) ile kontrol et' -ForegroundColor Yellow
>>"%S7%" echo     exit 1
>>"%S7%" echo }

powershell -NoProfile -ExecutionPolicy Bypass -File "%S7%"
if errorlevel 1 (del "%S7%" 2>nul & pause & goto menu)
del "%S7%" 2>nul
echo.

:: ----- KURULUM TAMAMLANDI -----
:install_done
echo.
echo   =============================================
call :PrintGreen "     KURULUM TAMAMLANDI!"
echo   =============================================
echo.
call :PrintGreen "   Discord'u acabilirsin."
echo.
call :PrintYellow "   Strateji: %BEST_STRATEGY%"
call :PrintYellow "   Zapret PC her acildiginda otomatik calisacak."
echo.
call :PrintYellow "   Voice sorunu yasarsan: menu 4 (Sorun Gider)"
echo.
pause
goto menu


:: =====================================================
:: KALDIR
:: =====================================================
:uninstall
cls
echo.
call :PrintYellow "  Zapret kaldiriliyor..."
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "foreach($n in @('zapret','WinDivert','WinDivert14')){" ^
 "  $s=Get-Service -Name $n -EA SilentlyContinue;" ^
 "  if($s){Stop-Service $n -Force -EA SilentlyContinue;sc.exe delete $n 2>$null|Out-Null;" ^
 "    Write-Host \"  Servis kaldirildi: $n\" -ForegroundColor Yellow}" ^
 "};" ^
 "Get-Process -Name 'winws' -EA SilentlyContinue|Stop-Process -Force;" ^
 "Start-Sleep 1;" ^
 "try{Remove-MpPreference -ExclusionPath 'C:\zapret' -EA Stop;Write-Host '  Defender dislamasi kaldirildi' -ForegroundColor Green}catch{};" ^
 "if(Test-Path 'C:\zapret'){Remove-Item 'C:\zapret' -Recurse -Force;Write-Host '  Dosyalar silindi' -ForegroundColor Green}else{Write-Host '  C:\zapret bulunamadi (zaten temiz)' -ForegroundColor Gray}"

echo.
set /p "dns_reset=  DNS ayarlarini sifirlamak ister misin? (E/H): "
if /i "%dns_reset%"=="E" (
    powershell -NoProfile -Command ^
     "Get-NetAdapter|Where-Object{$_.Status -eq 'Up'}|ForEach-Object{Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses};" ^
     "Write-Host '  DNS sifirlandi (DHCP)' -ForegroundColor Green"
)

echo.
call :PrintGreen "  Kaldirma tamamlandi."
echo.
pause
goto menu


:: =====================================================
:: GUNCELLE
:: =====================================================
:update
cls
echo.
call :PrintYellow "  Guncellemeler kontrol ediliyor..."
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$cur='bilinmiyor';" ^
 "try{$r=reg query 'HKLM\System\CurrentControlSet\Services\zapret' /v 'zapret-discord-youtube' 2>$null;" ^
 "  if($r){$cur=($r|Select-String 'REG_SZ').ToString()-replace '.*REG_SZ\s+',''}}catch{};" ^
 "try{$rel=Invoke-RestMethod 'https://api.github.com/repos/Flowseal/zapret-discord-youtube/releases/latest' -TimeoutSec 10;" ^
 "  Write-Host \"  Mevcut strateji: $cur\" -ForegroundColor Gray;" ^
 "  Write-Host \"  Son surum: $($rel.tag_name)\" -ForegroundColor Gray" ^
 "}catch{Write-Host '  Surum bilgisi alinamadi' -ForegroundColor Yellow}"

echo.
set /p "do_update=  Guncellemek ister misin? (E/H): "
if /i not "%do_update%"=="E" (goto menu)

echo.
call :PrintYellow "  Mevcut kurulum temizleniyor..."

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "foreach($n in @('zapret','WinDivert','WinDivert14')){" ^
 "  $s=Get-Service -Name $n -EA SilentlyContinue;" ^
 "  if($s){Stop-Service $n -Force -EA SilentlyContinue;sc.exe delete $n 2>$null|Out-Null}" ^
 "};" ^
 "Get-Process -Name 'winws' -EA SilentlyContinue|Stop-Process -Force;" ^
 "Start-Sleep 1;" ^
 "if(Test-Path 'C:\zapret'){Remove-Item 'C:\zapret' -Recurse -Force}"

echo.
:: DNS adimini atla, dogrudan indirmeye git
goto install_step2


:: =====================================================
:: SORUN GIDER
:: =====================================================
:troubleshoot
cls
echo.
call :PrintYellow "  Sorun giderme baslatiliyor..."
echo.

:: Zapret kurulu mu?
if not exist "%ZAPRET_PATH%\bin\winws.exe" (
    call :PrintRed "  Zapret kurulu degil. Once 'Kur' secenegini kullan."
    echo.
    pause
    goto menu
)

:: Diagnostics
set "SD=%TEMP%\zapret_diag.ps1"
del "%SD%" 2>nul
>"%SD%"  echo Write-Host '  DIAGNOSTIK SONUCLARI' -ForegroundColor Cyan
>>"%SD%" echo Write-Host '  --------------------' -ForegroundColor Cyan
>>"%SD%" echo Write-Host ''
>>"%SD%" echo # BFE kontrolu
>>"%SD%" echo $bfe = Get-Service -Name 'BFE' -ErrorAction SilentlyContinue
>>"%SD%" echo if ($bfe -and $bfe.Status -eq 'Running') { Write-Host '  [OK] Base Filtering Engine calisiyor' -ForegroundColor Green } else { Write-Host '  [X] Base Filtering Engine calismiyor - zapret icin gerekli' -ForegroundColor Red }
>>"%SD%" echo # Servis durumu
>>"%SD%" echo $zs = Get-Service -Name 'zapret' -ErrorAction SilentlyContinue
>>"%SD%" echo if ($zs) { if ($zs.Status -eq 'Running') { Write-Host '  [OK] Zapret servisi calisiyor' -ForegroundColor Green } else { Write-Host "  [X] Zapret servisi durmus (durum: $($zs.Status))" -ForegroundColor Red } } else { Write-Host '  [!] Zapret servisi kurulu degil' -ForegroundColor Yellow }
>>"%SD%" echo # VPN kontrolu
>>"%SD%" echo $vpn = Get-Service ^| Where-Object { $_.Name -match 'VPN' -and $_.Status -eq 'Running' }
>>"%SD%" echo if ($vpn) { Write-Host "  [!] VPN servisleri aktif: $($vpn.Name -join ', ') - zapret ile cakisabilir" -ForegroundColor Yellow } else { Write-Host '  [OK] VPN servisi bulunamadi' -ForegroundColor Green }
>>"%SD%" echo # Adguard
>>"%SD%" echo $ag = Get-Process -Name 'AdguardSvc' -ErrorAction SilentlyContinue
>>"%SD%" echo if ($ag) { Write-Host '  [X] Adguard calisiyor - Discord ile sorun olusturabilir' -ForegroundColor Red } else { Write-Host '  [OK] Adguard bulunamadi' -ForegroundColor Green }
>>"%SD%" echo # Killer servisleri
>>"%SD%" echo $killer = Get-Service ^| Where-Object { $_.Name -match 'Killer' -and $_.Status -eq 'Running' }
>>"%SD%" echo if ($killer) { Write-Host '  [X] Killer servisleri bulundu - zapret ile cakisiyor' -ForegroundColor Red } else { Write-Host '  [OK] Killer servisi bulunamadi' -ForegroundColor Green }
>>"%SD%" echo # SmartByte
>>"%SD%" echo $sb = Get-Service ^| Where-Object { $_.Name -match 'SmartByte' -and $_.Status -eq 'Running' }
>>"%SD%" echo if ($sb) { Write-Host '  [X] SmartByte bulundu - zapret ile cakisiyor' -ForegroundColor Red } else { Write-Host '  [OK] SmartByte bulunamadi' -ForegroundColor Green }
>>"%SD%" echo # Cakisan bypass servisleri
>>"%SD%" echo $conflicts = @('goodbyedpi','discordfix_zapret','winws1','winws2','SplitWire')
>>"%SD%" echo $cf = $conflicts ^| Where-Object { Get-Service -Name $_ -EA SilentlyContinue }
>>"%SD%" echo if ($cf) { Write-Host "  [X] Cakisan bypass servisleri: $($cf -join ', ')" -ForegroundColor Red } else { Write-Host '  [OK] Cakisan bypass bulunamadi' -ForegroundColor Green }
>>"%SD%" echo # DNS kontrolu
>>"%SD%" echo $dns = (Get-DnsClientServerAddress -AddressFamily IPv4 ^| Where-Object { $_.ServerAddresses -and $_.InterfaceAlias -notmatch 'Loopback' } ^| Select-Object -First 1).ServerAddresses
>>"%SD%" echo if ($dns -contains '1.1.1.1' -or $dns -contains '8.8.8.8') { Write-Host "  [OK] DNS: $($dns -join ', ')" -ForegroundColor Green } else { Write-Host "  [!] DNS: $($dns -join ', ') - 1.1.1.1 veya 8.8.8.8 onerilir" -ForegroundColor Yellow }
>>"%SD%" echo # winws.exe dosyasi
>>"%SD%" echo if (Test-Path 'C:\zapret\bin\winws.exe') { Write-Host '  [OK] winws.exe mevcut' -ForegroundColor Green } else { Write-Host '  [X] winws.exe bulunamadi - yeniden kur' -ForegroundColor Red }
>>"%SD%" echo # WinDivert syz dosyasi
>>"%SD%" echo $sys = Get-ChildItem 'C:\zapret\bin\*.sys' -ErrorAction SilentlyContinue
>>"%SD%" echo if ($sys) { Write-Host '  [OK] WinDivert driver mevcut' -ForegroundColor Green } else { Write-Host '  [X] WinDivert driver bulunamadi - yeniden kur' -ForegroundColor Red }
>>"%SD%" echo # Discord erisim testi
>>"%SD%" echo Write-Host ''
>>"%SD%" echo Write-Host '  DISCORD ERISIM TESTI' -ForegroundColor Cyan
>>"%SD%" echo try {
>>"%SD%" echo     $r = Invoke-WebRequest 'https://discord.com/api/v10/gateway' -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
>>"%SD%" echo     if ($r.StatusCode -eq 200) { Write-Host '  [OK] Discord erisilebilir' -ForegroundColor Green }
>>"%SD%" echo } catch { Write-Host '  [X] Discord erisilemedi - strateji degisikligi gerekebilir' -ForegroundColor Red }

powershell -NoProfile -ExecutionPolicy Bypass -File "%SD%"
del "%SD%" 2>nul

echo.
echo   --------------------
echo.
set /p "run_test=  Strateji testi yapmak ister misin? (E/H): "
if /i "%run_test%"=="E" (
    echo.
    :: Mevcut servisi durdur (test icin gerekli)
    powershell -NoProfile -Command "foreach($n in @('zapret','WinDivert','WinDivert14')){$s=Get-Service -Name $n -EA SilentlyContinue;if($s){Stop-Service $n -Force -EA SilentlyContinue;sc.exe delete $n 2>$null|Out-Null}};Get-Process -Name 'winws' -EA SilentlyContinue|Stop-Process -Force"
    timeout /t 2 >nul
    goto install_step6
)

echo.
pause
goto menu


:: =====================================================
:: YARDIMCI FONKSIYONLAR
:: =====================================================
:PrintGreen
powershell -NoProfile -Command "Write-Host '%~1' -ForegroundColor Green"
exit /b

:PrintRed
powershell -NoProfile -Command "Write-Host '%~1' -ForegroundColor Red"
exit /b

:PrintYellow
powershell -NoProfile -Command "Write-Host '%~1' -ForegroundColor Yellow"
exit /b

:PrintStep
powershell -NoProfile -Command "Write-Host '  [%~1/%~2]' -ForegroundColor White -NoNewline; Write-Host ' %~3' -ForegroundColor Cyan"
exit /b
