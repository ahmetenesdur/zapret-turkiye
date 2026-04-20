@echo off
:: =====================================================
:: ZAPRET TURKIYE KURULUM ARACI
:: Tek tikla Discord erisim sorununu coz
:: https://github.com/ahmetenesdur/zapret-turkiye
:: =====================================================
setlocal EnableDelayedExpansion
set "VERSION=1.1"
set "ZAPRET_PATH=C:\zapret"
set "LOG=%ZAPRET_PATH%\install.log"

:: UTF-8 karakter destegi
chcp 65001 >nul 2>&1

:: Pencere basligi
title Zapret Turkiye v%VERSION%

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
set "Z_STATUS="
set "Z_STRATEGY="
set "STATUS_COLOR=DarkGray"
sc query zapret >nul 2>&1
if !errorlevel! equ 0 (
    set "Z_STATUS=KALKAN AKTIF"
    set "STATUS_COLOR=Green"
    for /f "tokens=2*" %%A in ('reg query "HKLM\System\CurrentControlSet\Services\zapret" /v "zapret-discord-youtube" 2^>nul ^| findstr "REG_SZ"') do set "Z_STRATEGY=%%B"
) else if exist "%ZAPRET_PATH%\bin\winws.exe" (
    set "Z_STATUS=KURULU (Servis Durmus)"
    set "STATUS_COLOR=Yellow"
) else (
    set "Z_STATUS=KURULU DEGIL"
    set "STATUS_COLOR=DarkGray"
)

cls
powershell -NoProfile -Command ^
 "Write-Host '';" ^
 "Write-Host '   =============================================' -ForegroundColor DarkCyan;" ^
 "Write-Host '     ZAPRET TURKIYE KURULUM ARACI  v%VERSION%' -ForegroundColor Cyan;" ^
 "Write-Host '   =============================================' -ForegroundColor DarkCyan;" ^
 "Write-Host '     ' -NoNewline; Write-Host '%Z_STATUS%' -ForegroundColor %STATUS_COLOR%"

if defined Z_STRATEGY (
    powershell -NoProfile -Command "Write-Host '     Strateji: !Z_STRATEGY!' -ForegroundColor Gray"
)
echo.
echo     1. Kur          (otomatik kurulum)
echo     2. Kaldir       (tamamen temizle)
echo     3. Guncelle     (yeni surum indir)
echo     4. Sorun Gider  (otomatik kontrol)
echo     0. Cikis
echo.
powershell -NoProfile -Command "Write-Host '   =============================================' -ForegroundColor DarkCyan"
echo.

choice /C 12340 /N /M "   Secenek (0-4): "
if errorlevel 5 exit /b
if errorlevel 4 goto troubleshoot
if errorlevel 3 goto update
if errorlevel 2 goto uninstall
if errorlevel 1 goto install
goto menu


:: =====================================================
:: KUR - OTOMATIK KURULUM
:: =====================================================
:install
set "PROCESS=install"
cls
echo.
call :PrintStep "Asagidaki islemler otomatik yapilacak:"
echo.
echo     [1/7] DNS yapilandirma (Cloudflare + DoH)
echo     [2/7] Son surumu indirme (GitHub)
echo     [3/7] Dosyalari cikarma (C:\zapret)
echo     [4/7] Defender dislamasi
echo     [5/7] Cakisma temizleme
echo     [6/7] Strateji testi (2-5 dk)
echo     [7/7] Servis kurulumu
echo.

choice /C EH /N /M "   Kuruluma baslamak ister misin? (E/H): "
if errorlevel 2 goto menu

cls
echo.

:: ----- ADIM 1: DNS -----
call :PrintStepN "1" "7" "DNS ayarlaniyor..."

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
if errorlevel 1 (cmd /c "exit /b 0")

:: ----- ADIM 2: INDIR -----
:install_step2
call :PrintStepN "2" "7" "Son surum indiriliyor..."

:: Internet baglanti kontrolu
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ProgressPreference='SilentlyContinue';" ^
 "try{Invoke-WebRequest 'https://api.github.com' -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop|Out-Null;" ^
 "Write-Host '  Internet baglantisi kontrol edildi' -ForegroundColor Gray" ^
 "}catch{Write-Host '  Internet baglantisi yok!' -ForegroundColor Red;exit 1}"

if errorlevel 1 (
    call :PrintRed "  Once internete baglandigindan emin ol."
    echo.
    call :Bekle
    goto menu
)

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
>>"%S2%" echo     Set-Content -Path "$env:TEMP\zapret_ver.txt" -Value $ver -NoNewline
>>"%S2%" echo     $ProgressPreference = 'SilentlyContinue'
>>"%S2%" echo     Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
>>"%S2%" echo     Set-Content -Path "$env:TEMP\zapret_zip.txt" -Value $zip -NoNewline
>>"%S2%" echo     Write-Host '  Indirme tamamlandi' -ForegroundColor Green
>>"%S2%" echo } catch {
>>"%S2%" echo     Write-Host "  Indirme basarisiz: $_" -ForegroundColor Red
>>"%S2%" echo     Write-Host '  Internet baglantini kontrol et' -ForegroundColor Yellow
>>"%S2%" echo     exit 1
>>"%S2%" echo }

powershell -NoProfile -ExecutionPolicy Bypass -File "%S2%"
if errorlevel 1 (del "%S2%" 2>nul & call :Bekle & goto menu)
del "%S2%" 2>nul
echo.

:: ----- ADIM 3: CIKAR -----
call :PrintStepN "3" "7" "Dosyalar cikariliyor..."

set "S3=%TEMP%\zapret_s3.ps1"
del "%S3%" 2>nul
>"%S3%"  echo $ProgressPreference = 'SilentlyContinue'
>>"%S3%" echo $ErrorActionPreference = 'Stop'
>>"%S3%" echo $zip = Get-Content "$env:TEMP\zapret_zip.txt"
>>"%S3%" echo $target = 'C:\zapret'
>>"%S3%" echo try {
>>"%S3%" echo     if (Test-Path $target) {
>>"%S3%" echo         $svc = Get-Service -Name 'zapret' -ErrorAction SilentlyContinue
>>"%S3%" echo         if ($svc) { try { Stop-Service 'zapret' -Force -ErrorAction Stop } catch {}; sc.exe delete 'zapret' 2^>$null ^| Out-Null }
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
if errorlevel 1 (del "%S3%" 2>nul & call :Bekle & goto menu)
del "%S3%" 2>nul
echo.

:: ----- ADIM 4: DEFENDER DISLAMA -----
call :PrintStepN "4" "7" "Defender dislamasi ekleniyor..."

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "try{Add-MpPreference -ExclusionPath 'C:\zapret' -ErrorAction Stop;" ^
 "Write-Host '  Defender dislamasi eklendi' -ForegroundColor Green" ^
 "}catch{Write-Host '  Defender dislamasi eklenemedi - baska antivirus varsa elle disla' -ForegroundColor Yellow}"

echo.

:: ----- ADIM 5: CAKISMA TEMIZLEME -----
call :PrintStepN "5" "7" "Cakismalar kontrol ediliyor..."

call :StopConflicts
echo.

:: ----- ADIM 6: STRATEJI TESTI -----
:install_step6
call :PrintStepN "6" "7" "En iyi strateji araniyor..."
echo.
call :PrintYellow "  Bu adim ISP baglantisina gore 2-5 dakika surebilir."
echo.

set "S6=%TEMP%\zapret_s6.ps1"
del "%S6%" 2>nul
>"%S6%"  echo $ProgressPreference = 'SilentlyContinue'
>>"%S6%" echo $zapret = 'C:\zapret'
>>"%S6%" echo $strategies = Get-ChildItem "$zapret\*.bat" ^| Where-Object { $_.Name -notlike 'service*' } ^| Sort-Object Name
>>"%S6%" echo $total = $strategies.Count
>>"%S6%" echo Write-Host "  $total strateji bulundu, test basliyor..." -ForegroundColor Gray
>>"%S6%" echo Write-Host ''
>>"%S6%" echo $best = $null
>>"%S6%" echo $i = 0
>>"%S6%" echo $sw = [System.Diagnostics.Stopwatch]::StartNew()
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
>>"%S6%" echo $sw.Stop()
>>"%S6%" echo $elapsed = '{0:mm\:ss}' -f $sw.Elapsed
>>"%S6%" echo Write-Host ''
>>"%S6%" echo if ($best) {
>>"%S6%" echo     Set-Content -Path "$env:TEMP\zapret_best.txt" -Value $best -NoNewline
>>"%S6%" echo     Write-Host "  Sonuc: $i/$total strateji denendi, sure: $elapsed" -ForegroundColor Gray
>>"%S6%" echo     Write-Host "  En iyi strateji: $best" -ForegroundColor Green
>>"%S6%" echo } else {
>>"%S6%" echo     Write-Host "  Sonuc: $total/$total strateji denendi, sure: $elapsed" -ForegroundColor Gray
>>"%S6%" echo     Write-Host '  Hicbir strateji calismadi.' -ForegroundColor Red
>>"%S6%" echo     Write-Host '  Sorun Gider (menu 4) ile kontrol et.' -ForegroundColor Yellow
>>"%S6%" echo     exit 1
>>"%S6%" echo }

powershell -NoProfile -ExecutionPolicy Bypass -File "%S6%"
if errorlevel 1 (del "%S6%" 2>nul & call :Bekle & goto menu)
del "%S6%" 2>nul

set /p BEST_STRATEGY=<"%TEMP%\zapret_best.txt"
del "%TEMP%\zapret_best.txt" 2>nul
echo.

:: ----- ADIM 7: SERVIS KURULUMU -----
:install_step7
call :PrintStepN "7" "7" "Servis kuruluyor..."

set "S7=%TEMP%\zapret_s7.ps1"
del "%S7%" 2>nul
>"%S7%"  echo $ProgressPreference = 'SilentlyContinue'
>>"%S7%" echo $best = '%BEST_STRATEGY%'
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
>>"%S7%" echo $finalArgs = $finalArgs -replace '%%BIN%%', $binPath
>>"%S7%" echo $finalArgs = $finalArgs -replace '%%LISTS%%', $listsPath
>>"%S7%" echo # GameFilter: 12 = disabled (dummy port, hicbir trafigi yakalamaz)
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
>>"%S7%" echo     New-Service -Name 'zapret' -BinaryPathName $svcBin -DisplayName 'zapret' -StartupType Automatic -ErrorAction Stop ^| Out-Null
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
>>"%S7%" echo     $ver = ''; if (Test-Path "$env:TEMP\zapret_ver.txt") { $ver = Get-Content "$env:TEMP\zapret_ver.txt" -ErrorAction SilentlyContinue }
>>"%S7%" echo     if ($ver) { reg add 'HKLM\System\CurrentControlSet\Services\zapret' /v 'zapret-version' /t REG_SZ /d $ver /f 2^>$null ^| Out-Null }
>>"%S7%" echo     Write-Host '  Servis kuruldu ve calisiyor' -ForegroundColor Green
>>"%S7%" echo     Write-Host "  Strateji: $best" -ForegroundColor Gray
>>"%S7%" echo } else {
>>"%S7%" echo     Write-Host '  Servis baslatilamadi' -ForegroundColor Red
>>"%S7%" echo     Write-Host '  Sorun Gider (menu 4) ile kontrol et' -ForegroundColor Yellow
>>"%S7%" echo     exit 1
>>"%S7%" echo }

powershell -NoProfile -ExecutionPolicy Bypass -File "%S7%"
if errorlevel 1 (del "%S7%" 2>nul & call :Bekle & goto menu)
del "%S7%" 2>nul

:: Temp surum dosyasini temizle
del "%TEMP%\zapret_ver.txt" 2>nul
echo.

:: ----- DOGRULAMA -----
call :PrintStep "Discord erisimi dogrulaniyor..."

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ProgressPreference='SilentlyContinue';" ^
 "Start-Sleep -Seconds 2;" ^
 "try{$r=Invoke-WebRequest 'https://discord.com/api/v10/gateway' -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop;" ^
 "if($r.StatusCode -eq 200){Write-Host '  Discord erisimi basarili!' -ForegroundColor Green}" ^
 "}catch{Write-Host '  Discord erisimi dogrulanamadi - biraz bekleyip tekrar dene' -ForegroundColor Yellow}"

echo.

:: ----- LOG -----
if not exist "%ZAPRET_PATH%" mkdir "%ZAPRET_PATH%" 2>nul
call :Log "Kurulum tamamlandi. Strateji: %BEST_STRATEGY%, Islem: %PROCESS%"

:: ----- KURULUM TAMAMLANDI -----
:install_done
echo.
powershell -NoProfile -Command ^
 "$ProgressPreference='SilentlyContinue'; Write-Host '   =============================================' -ForegroundColor DarkCyan;" ^
 "if ('%PROCESS%' -eq 'update') { Write-Host '       GUNCELLEME TAMAMLANDI!' -ForegroundColor Green }" ^
 "elseif ('%PROCESS%' -eq 'troubleshoot') { Write-Host '     STRATEJI TESTI TAMAMLANDI!' -ForegroundColor Green }" ^
 "else { Write-Host '       KURULUM TAMAMLANDI!' -ForegroundColor Green };" ^
 "Write-Host '   =============================================' -ForegroundColor DarkCyan"
echo.
call :PrintGreen "   Discord artik erisilebilir olmali."
echo.
echo   Strateji : %BEST_STRATEGY%
echo   Konum    : %ZAPRET_PATH%
echo   Servis   : zapret (otomatik baslayacak)
echo.
if /i not "%PROCESS%"=="troubleshoot" call :PrintYellow "   Voice sorunu yasarsan: menu 4 (Sorun Gider)"
echo.
call :Bekle
goto menu


:: =====================================================
:: KALDIR
:: =====================================================
:uninstall
cls
echo.
call :PrintYellow "  UYARI: Zapret tamamen kaldirilacak!"
echo.
echo   Bu islem:
echo     - Tum servisleri silecek
echo     - WinDivert driver'larini temizleyecek
echo     - C:\zapret klasorunu silecek
echo     - Defender dislamasini kaldiracak
echo.

choice /C EH /N /M "  Emin misin? (E/H): "
if errorlevel 2 goto menu

echo.
call :PrintYellow "  Zapret kaldiriliyor..."
echo.

:: Servisleri durdur ve sil
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ProgressPreference='SilentlyContinue'; foreach($n in @('zapret','WinDivert','WinDivert14')){" ^
 "  $s=Get-Service -Name $n -EA SilentlyContinue;" ^
 "  if($s){try{Stop-Service $n -Force -EA Stop}catch{};sc.exe delete $n 2>$null|Out-Null;" ^
 "    Write-Host \"  Servis kaldirildi: $n\" -ForegroundColor Yellow}" ^
 "};" ^
 "Get-Process -Name 'winws' -EA SilentlyContinue|Stop-Process -Force;" ^
 "Start-Sleep 1"

:: WinDivert driver temizligi
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ProgressPreference='SilentlyContinue'; $drv=driverquery 2>$null|Select-String 'Divert';" ^
 "if($drv){foreach($d in $drv){$name=($d.Line -split '\s+')[0];" ^
 "  sc.exe stop $name 2>$null|Out-Null;sc.exe delete $name 2>$null|Out-Null;" ^
 "  Write-Host \"  Driver kaldirildi: $name\" -ForegroundColor Yellow}}"

:: Defender ve dosya temizligi
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ProgressPreference='SilentlyContinue'; try{Remove-MpPreference -ExclusionPath 'C:\zapret' -EA Stop;Write-Host '  Defender dislamasi kaldirildi' -ForegroundColor Green}catch{};" ^
 "if(Test-Path 'C:\zapret'){Remove-Item 'C:\zapret' -Recurse -Force;Write-Host '  Dosyalar silindi' -ForegroundColor Green}else{Write-Host '  C:\zapret bulunamadi (zaten temiz)' -ForegroundColor Gray}"

echo.
choice /C EH /N /M "  DNS ayarlarini sifirlamak ister misin? (E/H): "
if errorlevel 2 goto uninstall_done

powershell -NoProfile -Command ^
 "$ProgressPreference='SilentlyContinue'; Get-NetAdapter|Where-Object{$_.Status -eq 'Up'}|ForEach-Object{Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses};" ^
 "Write-Host '  DNS sifirlandi (DHCP)' -ForegroundColor Green"

:uninstall_done
echo.
call :PrintGreen "  Kaldirma tamamlandi."
echo.
call :Bekle
goto menu


:: =====================================================
:: GUNCELLE
:: =====================================================
:update
set "PROCESS=update"
cls
echo.
call :PrintYellow "  Guncellemeler kontrol ediliyor..."
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ProgressPreference='SilentlyContinue'; $cur='bilinmiyor';$ver='bilinmiyor';" ^
 "try{$r=reg query 'HKLM\System\CurrentControlSet\Services\zapret' /v 'zapret-discord-youtube' 2>$null;" ^
 "  if($r){$cur=($r|Select-String 'REG_SZ').ToString()-replace '.*REG_SZ\s+',''}}catch{};" ^
 "try{$rv=reg query 'HKLM\System\CurrentControlSet\Services\zapret' /v 'zapret-version' 2>$null;" ^
 "  if($rv){$ver=($rv|Select-String 'REG_SZ').ToString()-replace '.*REG_SZ\s+',''}}catch{};" ^
 "try{$rel=Invoke-RestMethod 'https://api.github.com/repos/Flowseal/zapret-discord-youtube/releases/latest' -TimeoutSec 10;" ^
 "  Write-Host \"  Mevcut strateji : $cur\" -ForegroundColor Gray;" ^
 "  Write-Host \"  Kurulu surum    : $ver\" -ForegroundColor Gray;" ^
 "  Write-Host \"  Son surum       : $($rel.tag_name)\" -ForegroundColor Gray" ^
 "}catch{Write-Host '  Surum bilgisi alinamadi' -ForegroundColor Yellow}"

echo.
choice /C EH /N /M "  Guncellemek ister misin? (E/H): "
if errorlevel 2 goto menu

echo.
call :PrintYellow "  Mevcut kurulum temizleniyor..."

:: Servisleri ve dosyalari temizle
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ProgressPreference='SilentlyContinue'; foreach($n in @('zapret','WinDivert','WinDivert14')){" ^
 "  $s=Get-Service -Name $n -EA SilentlyContinue;" ^
 "  if($s){try{Stop-Service $n -Force -EA Stop}catch{};sc.exe delete $n 2>$null|Out-Null}" ^
 "};" ^
 "Get-Process -Name 'winws' -EA SilentlyContinue|Stop-Process -Force;" ^
 "Start-Sleep 1;" ^
 "if(Test-Path 'C:\zapret'){Remove-Item 'C:\zapret' -Recurse -Force}"

echo.
if errorlevel 1 (cmd /c "exit /b 0")
:: DNS adimini atla, dogrudan indirmeye git
goto install_step2


:: =====================================================
:: SORUN GIDER
:: =====================================================
:troubleshoot
set "PROCESS=troubleshoot"
cls
echo.
call :PrintYellow "  Sorun giderme baslatiliyor..."
echo.

:: Zapret kurulu mu?
if not exist "%ZAPRET_PATH%\bin\winws.exe" (
    call :PrintRed "  Zapret kurulu degil. Once Kur secenegini kullan."
    echo.
    call :Bekle
    goto menu
)

:: Diagnostics
set "SD=%TEMP%\zapret_diag.ps1"
del "%SD%" 2>nul
>"%SD%"  echo $ProgressPreference = 'SilentlyContinue'
>>"%SD%" echo Write-Host '  DIAGNOSTIK SONUCLARI' -ForegroundColor Cyan
>>"%SD%" echo Write-Host '  --------------------' -ForegroundColor Cyan
>>"%SD%" echo Write-Host ''
>>"%SD%" echo # BFE kontrolu
>>"%SD%" echo $bfe = Get-Service -Name 'BFE' -ErrorAction SilentlyContinue
>>"%SD%" echo if ($bfe -and $bfe.Status -eq 'Running') { Write-Host '  [OK] Base Filtering Engine calisiyor' -ForegroundColor Green } else { Write-Host '  [X] Base Filtering Engine calismiyor - zapret icin gerekli' -ForegroundColor Red }
>>"%SD%" echo # Servis durumu
>>"%SD%" echo $zs = Get-Service -Name 'zapret' -ErrorAction SilentlyContinue
>>"%SD%" echo if ($zs) { if ($zs.Status -eq 'Running') { Write-Host '  [OK] Zapret servisi calisiyor' -ForegroundColor Green } else { Write-Host "  [X] Zapret servisi durmus (durum: $($zs.Status))" -ForegroundColor Red } } else { Write-Host '  [!] Zapret servisi kurulu degil' -ForegroundColor Yellow }
>>"%SD%" echo # Proxy kontrolu
>>"%SD%" echo $proxy = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue).ProxyEnable
>>"%SD%" echo if ($proxy -eq 1) { $ps = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings').ProxyServer; Write-Host "  [!] Sistem proxy aktif: $ps - zapret ile cakisabilir" -ForegroundColor Yellow } else { Write-Host '  [OK] Proxy bulunamadi' -ForegroundColor Green }
>>"%SD%" echo # TCP timestamps
>>"%SD%" echo $ts = netsh interface tcp show global 2^>$null ^| Select-String 'timestamps' ^| Select-String 'enabled'
>>"%SD%" echo if ($ts) { Write-Host '  [OK] TCP timestamps aktif' -ForegroundColor Green } else { Write-Host '  [!] TCP timestamps pasif - etkinlestiriliyor...' -ForegroundColor Yellow; netsh interface tcp set global timestamps=enabled 2^>$null ^| Out-Null }
>>"%SD%" echo # VPN kontrolu
>>"%SD%" echo $vpn = Get-Service ^| Where-Object { $_.Name -match 'VPN' -and $_.Status -eq 'Running' }
>>"%SD%" echo if ($vpn) { Write-Host "  [!] VPN servisleri aktif: $($vpn.Name -join ', ') - zapret ile cakisabilir" -ForegroundColor Yellow } else { Write-Host '  [OK] VPN servisi bulunamadi' -ForegroundColor Green }
>>"%SD%" echo # Adguard
>>"%SD%" echo $ag = Get-Process -Name 'AdguardSvc' -ErrorAction SilentlyContinue
>>"%SD%" echo if ($ag) { Write-Host '  [X] Adguard calisiyor - Discord ile sorun olusturabilir' -ForegroundColor Red } else { Write-Host '  [OK] Adguard bulunamadi' -ForegroundColor Green }
>>"%SD%" echo # Killer servisleri
>>"%SD%" echo $killer = Get-Service ^| Where-Object { $_.Name -match 'Killer' -and $_.Status -eq 'Running' }
>>"%SD%" echo if ($killer) { Write-Host '  [X] Killer servisleri bulundu - zapret ile cakisiyor' -ForegroundColor Red } else { Write-Host '  [OK] Killer servisi bulunamadi' -ForegroundColor Green }
>>"%SD%" echo # Intel Connectivity
>>"%SD%" echo $intel = Get-Service ^| Where-Object { $_.DisplayName -match 'Intel.*Connectivity.*Network' -and $_.Status -eq 'Running' }
>>"%SD%" echo if ($intel) { Write-Host '  [X] Intel Connectivity Network Service bulundu - zapret ile cakisiyor' -ForegroundColor Red } else { Write-Host '  [OK] Intel Connectivity bulunamadi' -ForegroundColor Green }
>>"%SD%" echo # Check Point
>>"%SD%" echo $cp1 = Get-Service -Name 'TracSrvWrapper' -ErrorAction SilentlyContinue
>>"%SD%" echo $cp2 = Get-Service -Name 'EPWD' -ErrorAction SilentlyContinue
>>"%SD%" echo if ($cp1 -or $cp2) { Write-Host '  [X] Check Point servisleri bulundu - zapret ile cakisiyor' -ForegroundColor Red } else { Write-Host '  [OK] Check Point bulunamadi' -ForegroundColor Green }
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
>>"%SD%" echo # WinDivert sys dosyasi
>>"%SD%" echo $sys = Get-ChildItem 'C:\zapret\bin\*.sys' -ErrorAction SilentlyContinue
>>"%SD%" echo if ($sys) { Write-Host '  [OK] WinDivert driver mevcut' -ForegroundColor Green } else { Write-Host '  [X] WinDivert driver bulunamadi - yeniden kur' -ForegroundColor Red }
>>"%SD%" echo # Discord erisim testleri
>>"%SD%" echo $ProgressPreference = 'SilentlyContinue'
>>"%SD%" echo Write-Host ''
>>"%SD%" echo Write-Host '  DISCORD ERISIM TESTLERI' -ForegroundColor Cyan
>>"%SD%" echo try {
>>"%SD%" echo     $r = Invoke-WebRequest 'https://discord.com/api/v10/gateway' -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
>>"%SD%" echo     if ($r.StatusCode -eq 200) { Write-Host '  [OK] Discord API erisilebilir' -ForegroundColor Green }
>>"%SD%" echo } catch { Write-Host '  [X] Discord API erisilemedi - strateji degisikligi gerekebilir' -ForegroundColor Red }
>>"%SD%" echo try {
>>"%SD%" echo     $null = Invoke-WebRequest 'https://cdn.discordapp.com' -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
>>"%SD%" echo     Write-Host '  [OK] Discord CDN erisilebilir' -ForegroundColor Green
>>"%SD%" echo } catch { if ($_.Exception.Response) { Write-Host '  [OK] Discord CDN erisilebilir' -ForegroundColor Green } else { Write-Host '  [X] Discord CDN erisilemedi' -ForegroundColor Red } }
>>"%SD%" echo try {
>>"%SD%" echo     $null = Invoke-WebRequest 'https://media.discordapp.net' -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
>>"%SD%" echo     Write-Host '  [OK] Discord Media erisilebilir' -ForegroundColor Green
>>"%SD%" echo } catch { if ($_.Exception.Response) { Write-Host '  [OK] Discord Media erisilebilir' -ForegroundColor Green } else { Write-Host '  [X] Discord Media erisilemedi - voice sorunu olabilir' -ForegroundColor Red } }

powershell -NoProfile -ExecutionPolicy Bypass -File "%SD%"
del "%SD%" 2>nul

echo.
echo   --------------------
echo.

choice /C EH /N /M "  Strateji testi yapmak ister misin? (E/H): "
if errorlevel 2 goto troubleshoot_done

echo.
:: Mevcut servisi durdur (test icin gerekli)
call :StopServices
timeout /t 2 >nul
goto install_step6

:troubleshoot_done
echo.
call :Bekle
goto menu


:: =====================================================
:: YARDIMCI FONKSIYONLAR
:: =====================================================

:: Servisleri durdur ve process'leri kapat
:StopServices
powershell -NoProfile -Command "foreach($n in @('zapret','WinDivert','WinDivert14')){$s=Get-Service -Name $n -EA SilentlyContinue;if($s){try{Stop-Service $n -Force -EA Stop}catch{};sc.exe delete $n 2>$null|Out-Null}};Get-Process -Name 'winws' -EA SilentlyContinue|Stop-Process -Force"
exit /b

:: Cakisan servisleri temizle
:StopConflicts
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$found=0;" ^
 "foreach($n in @('goodbyedpi','zapret','SplitWire','WinDivert','WinDivert14','discordfix_zapret','winws1','winws2')){" ^
 "  $s=Get-Service -Name $n -EA SilentlyContinue;" ^
 "  if($s){try{Stop-Service $n -Force -EA Stop}catch{};sc.exe delete $n 2>$null|Out-Null;$found++;Write-Host \"  Kaldirildi: $n\" -ForegroundColor Yellow}" ^
 "};" ^
 "Get-Process -Name 'winws' -EA SilentlyContinue|Stop-Process -Force;" ^
 "if($found -eq 0){Write-Host '  Cakisma bulunamadi' -ForegroundColor Green}else{Write-Host \"  $found cakisan servis kaldirildi\" -ForegroundColor Green}"
exit /b

:: Log dosyasina yaz
:Log
if not exist "%ZAPRET_PATH%" mkdir "%ZAPRET_PATH%" 2>nul
powershell -NoProfile -Command "Add-Content -Path '%LOG%' -Value \"[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] %~1\""
exit /b

:: Turkce bekle mesaji
:Bekle
echo   Devam etmek icin bir tusa bas...
pause >nul
exit /b

:PrintGreen
powershell -NoProfile -Command "Write-Host \"%~1\" -ForegroundColor Green"
exit /b

:PrintRed
powershell -NoProfile -Command "Write-Host \"%~1\" -ForegroundColor Red"
exit /b

:PrintYellow
powershell -NoProfile -Command "Write-Host \"%~1\" -ForegroundColor Yellow"
exit /b

:PrintStep
powershell -NoProfile -Command "Write-Host '  [' -ForegroundColor DarkGray -NoNewline; Write-Host '~' -ForegroundColor Cyan -NoNewline; Write-Host '] ' -ForegroundColor DarkGray -NoNewline; Write-Host \"%~1\" -ForegroundColor Cyan"
exit /b

:: Numarali adim yazici: %1=adim, %2=toplam, %3=mesaj
:PrintStepN
powershell -NoProfile -Command "Write-Host '  [' -ForegroundColor DarkGray -NoNewline; Write-Host '%~1/%~2' -ForegroundColor Cyan -NoNewline; Write-Host '] ' -ForegroundColor DarkGray -NoNewline; Write-Host \"%~3\" -ForegroundColor Cyan"
exit /b
