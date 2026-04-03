<# :
@echo off
title Dosya Takip Sistemi
set "params=%*"

:: Ana Scripti Baslat - Sadece bir hata (stderr) olusursa pause eder
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { iex ((Get-Content '%~f0') -join \"`n\") } catch { Write-Host '!!! KRITIK HATA OLUSTU !!!' -ForegroundColor Red; Write-Host $_; pause }"
exit /b
#>

# --- SAF POWERSHELL KODU ---

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- PENCERE MAXIMIZE ---
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class W32 {
    [DllImport("user32.dll")] public static extern IntPtr FindWindow(string c, string t);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
}
'@ -Language CSharp

$hwnd = [W32]::FindWindow("ConsoleWindowClass", "Dosya Takip Sistemi")
if ($hwnd -eq [IntPtr]::Zero) { $hwnd = [W32]::FindWindow($null, "Dosya Takip Sistemi") }
if ($hwnd -ne [IntPtr]::Zero) { [W32]::ShowWindow($hwnd, 3) | Out-Null }

Clear-Host

# --- TERMINAL GENISLIGI ---
$w = 120
try { $w = [Math]::Max(40, $Host.UI.RawUI.WindowSize.Width - 1) } catch {}

# --- YARDIMCI FONKSIYONLAR ---
function Get-ElapsedStr($start) {
    $e = [datetime]::Now - $start
    "{0:D2}:{1:D2}:{2:D2}" -f [int]$e.TotalHours, $e.Minutes, $e.Seconds
}

function Get-FriendlySize($bytes) {
    if ($bytes -lt 1KB) { return "$bytes B" }
    if ($bytes -lt 1MB) { return "{0:N2} KB" -f ($bytes / 1KB) }
    if ($bytes -lt 1GB) { return "{0:N2} MB" -f ($bytes / 1MB) }
    return "{0:N2} GB" -f ($bytes / 1GB)
}

# --- [1/4] BASLIK ---
Write-Host ("=" * $w) -ForegroundColor DarkGray
Write-Host "  Last Enlarged Files Scanner v3.0" -ForegroundColor White
Write-Host ("=" * $w) -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Calistirildigi klasorde belirtilen sure icinde olusturulmus ya da degistirilmis" -ForegroundColor Gray
Write-Host "  dosyalari bulup boyuta gore siralayarak listeler. 4 adimdan olusur:" -ForegroundColor Gray
Write-Host ""
Write-Host "  [1/4] " -NoNewline -ForegroundColor DarkCyan
Write-Host "Kolay inceleme icin otomatik tam ekran." -ForegroundColor Gray
Write-Host "  [2/4] " -NoNewline -ForegroundColor DarkCyan
Write-Host "Calistirma dizinindeki dosyalarin tamaminin sayimi ve sure araligina gore filtrelenmesi." -ForegroundColor Gray
Write-Host "  [3/4] " -NoNewline -ForegroundColor DarkCyan
Write-Host "Boyut taramasi, tam yol ve dosya ismi kullanilarak liste olusturma." -ForegroundColor Gray
Write-Host "  [4/4] " -NoNewline -ForegroundColor DarkCyan
Write-Host "Listeleme ve son rapor." -ForegroundColor Gray
Write-Host ""
Write-Host ("=" * $w) -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Kullanmak icin sure araligini harf eki ile girin:" -ForegroundColor Cyan
Write-Host "  1s = 1 saat  |  3g = 3 gun  |  2h = 2 hafta  |  9a = 9 ay  |  5y = 5 yil" -ForegroundColor Gray
Write-Host "  Bos birakilir, gecersiz format girilir ya da 10 saniye tercih belirtilmezse" -ForegroundColor Gray
Write-Host "  varsayilan 5 saat ile baslatilir." -ForegroundColor Gray
Write-Host ""

# --- ZAMANLI GIRIS (10s countdown) ---
$inputDeadline = [datetime]::Now.AddSeconds(10)
$inputChars    = [System.Text.StringBuilder]::new()
$inputDone     = $false

while (-not $inputDone) {
    $kalan = [Math]::Max(0, [int]($inputDeadline - [datetime]::Now).TotalSeconds)
    Write-Host "`r  Lutfen sure girin (-${kalan}s): $($inputChars.ToString())  " -NoNewline -ForegroundColor White
    if ([datetime]::Now -ge $inputDeadline) { break }
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Enter) {
            $inputDone = $true; break
        }
        elseif ($key.Key -eq [ConsoleKey]::Backspace) {
            if ($inputChars.Length -gt 0) { $inputChars.Remove($inputChars.Length - 1, 1) | Out-Null }
        }
        else {
            if ($key.KeyChar -ne "`0") { $inputChars.Append($key.KeyChar) | Out-Null }
        }
    }
    Start-Sleep -Milliseconds 100
}
Write-Host ""
$girdi = $inputChars.ToString().Trim()

# --- SURE PARSE ---
$limitZaman  = $null
$limitGoster = "5 saat (varsayilan)"

if ($girdi -match '^(\d+)([sghay])$') {
    $sayi     = [int]$Matches[1]
    $birim    = $Matches[2].ToLowerInvariant()
    $birimAdi = switch ($birim) {
        's' { 'saat'  }
        'g' { 'gun'   }
        'h' { 'hafta' }
        'a' { 'ay'    }
        'y' { 'yil'   }
    }
    $limitGoster = "$sayi $birimAdi"
    switch ($birim) {
        's' { $limitZaman = (Get-Date).AddHours(  -$sayi)        }
        'g' { $limitZaman = (Get-Date).AddDays(   -$sayi)        }
        'h' { $limitZaman = (Get-Date).AddDays(   -($sayi * 7))  }
        'a' { $limitZaman = (Get-Date).AddMonths( -$sayi)        }
        'y' { $limitZaman = (Get-Date).AddYears(  -$sayi)        }
    }
}

if ($null -eq $limitZaman) {
    if ($girdi.Length -gt 0) {
        Write-Host "  Gecersiz format, varsayilan 5 saat kullaniliyor." -ForegroundColor Yellow
    }
    $limitZaman = (Get-Date).AddHours(-5)
}

$currentDir  = Get-Location
$rootPath    = $currentDir.Path.TrimEnd([System.IO.Path]::DirectorySeparatorChar)

# --- [2/4] FILTRELEYEREK SAYIM (pipeline - streaming) ---
Write-Host ""
Write-Host "  [2/4] Son $limitGoster icin taraniyor..." -ForegroundColor Cyan
Write-Host ""

$snapshot        = [System.Collections.Generic.List[System.Object]]::new()
$sayacToplam     = 0
$sayacEslesen    = 0
$sonGuncelleme   = [datetime]::MinValue
$taramaBaslangic = [datetime]::Now

Get-ChildItem -Path $currentDir -Recurse -ErrorAction SilentlyContinue `
    -Attributes !Directory,!ReparsePoint | ForEach-Object {

    $sayacToplam++
    if ($_.LastWriteTime -gt $limitZaman -or $_.CreationTime -gt $limitZaman) {
        $snapshot.Add($_)
        $sayacEslesen++
    }
    $simdi = [datetime]::Now
    if (($simdi - $sonGuncelleme).TotalMilliseconds -gt 100) {
        $gecen = Get-ElapsedStr $taramaBaslangic
        Write-Host "`r  Gecen: ($gecen) | Taranan: $sayacToplam | Eslesen: $sayacEslesen  " -NoNewline -ForegroundColor Yellow
        $sonGuncelleme = $simdi
    }
}

$gecen = Get-ElapsedStr $taramaBaslangic
Write-Host "`r  Gecen: ($gecen) | Taranan: $sayacToplam | Eslesen: $sayacEslesen  " -ForegroundColor Yellow
Write-Host ""

if ($snapshot.Count -eq 0) {
    Write-Host "  Son $limitGoster icinde herhangi bir degisiklik bulunamadi." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Kapatmak icin bir tusa basin..." -ForegroundColor Gray
    $null = [Console]::ReadKey()
    exit
}

# --- [3/4] ANALIZ ---
$toplam           = $snapshot.Count
$sonuclar         = [System.Collections.Generic.List[System.Object]]::new()
$sayacAnaliz      = 0
$sonProgressZaman = [datetime]::MinValue

Write-Host "  [3/4] $toplam eslesen dosya analiz ediliyor..." -ForegroundColor Green
Write-Host ""

foreach ($dosyaItem in $snapshot) {
    $sayacAnaliz++

    if ($toplam -gt 20) {
        $simdi = [datetime]::Now
        if (($simdi - $sonProgressZaman).TotalMilliseconds -gt 150 -or $sayacAnaliz -eq $toplam) {
            $gecen = Get-ElapsedStr $taramaBaslangic
            Write-Progress -Activity "[3/4] Analiz Ediliyor  |  Gecen: $gecen" `
                           -Status "$sayacAnaliz / $toplam" `
                           -PercentComplete (($sayacAnaliz / $toplam) * 100)
            $sonProgressZaman = $simdi
        }
    }

    $tamYol = $dosyaItem.FullName

    if (-not (Test-Path -LiteralPath $tamYol)) {
        # Tarama sirasinda silinen veya yeniden adlandirilan dosya
        $sonuclar.Add([PSCustomObject]@{
            "Durum" = "DELETED/RENAMED"
            "Yol"   = $tamYol
            "Boyut" = "---"
            "Tarih" = $dosyaItem.LastWriteTime
            "Raw"   = 0
        })
    }
    else {
        $f          = Get-Item -LiteralPath $tamYol -ErrorAction SilentlyContinue
        if ($null -eq $f) { continue }
        $yeniMi     = $f.CreationTime  -gt $limitZaman
        $degismisMi = $f.LastWriteTime -gt $limitZaman
        $durum = if ($yeniMi -and $degismisMi) {
                     if ($f.LastWriteTime -gt $f.CreationTime.AddSeconds(5)) { "NEW+CHANGED" } else { "NEW" }
                 } elseif ($degismisMi) { "CHANGED" } else { "NEW (COPIED?)" }

        $sonuclar.Add([PSCustomObject]@{
            "Durum" = $durum
            "Yol"   = $f.FullName
            "Boyut" = Get-FriendlySize $f.Length
            "Tarih" = $f.LastWriteTime
            "Raw"   = $f.Length
        })
    }
}

if ($toplam -gt 20) { Write-Progress -Activity "Analiz Ediliyor" -Completed }

# --- [4/4] CIKTI ---
Write-Host "  [4/4] Listeleniyor..." -ForegroundColor Cyan
Write-Host ""
Write-Host ("=" * $w) -ForegroundColor Gray

# Artan siralama: en kucuk uste, en buyuk rapor hemen ustunde
$sonuclar | Sort-Object Raw | ForEach-Object {
    $color = "White"
    if ($_.Durum -like "*NEW*")         { $color = "Cyan"    }
    if ($_.Durum -eq "CHANGED")         { $color = "Magenta" }
    if ($_.Durum -eq "DELETED/RENAMED") { $color = "Red"     }

    Write-Host "[$($_.Durum)] " -NoNewline -ForegroundColor $color
    Write-Host "$($_.Yol)" -ForegroundColor White
    Write-Host "   Boyut: $($_.Boyut) | Tarih: $($_.Tarih)" -ForegroundColor Gray
    Write-Host ("-" * $w) -ForegroundColor Gray
}

# --- RAPOR ---
$sayYeni      = ($sonuclar | Where-Object { $_.Durum -like "*NEW*"         }).Count
$sayDegisti   = ($sonuclar | Where-Object { $_.Durum -eq  "CHANGED"        }).Count
$saySilindi   = ($sonuclar | Where-Object { $_.Durum -eq  "DELETED/RENAMED"}).Count
$toplamBytes  = ($sonuclar | Measure-Object -Property Raw -Sum).Sum
$toplamBoyut  = Get-FriendlySize $toplamBytes
$toplamSure   = Get-ElapsedStr $taramaBaslangic

# -- En yogun klasorler --
$folderCounts = @{}
foreach ($item in $sonuclar) {
    $dir = [System.IO.Path]::GetDirectoryName($item.Yol)
    while ($null -ne $dir) {
        $dirTrimmed = $dir.TrimEnd([System.IO.Path]::DirectorySeparatorChar)
        if ($dirTrimmed.Length -le $rootPath.Length) { break }
        if (-not $folderCounts.ContainsKey($dir)) { $folderCounts[$dir] = 0 }
        $folderCounts[$dir]++
        $parent = [System.IO.Path]::GetDirectoryName($dir)
        if ($null -eq $parent -or $parent -eq $dir) { break }
        $dir = $parent
    }
}
$topFolderlar = @($folderCounts.GetEnumerator() |
    Where-Object { $_.Value -ge 2 } |
    Sort-Object Value -Descending |
    Select-Object -First 5)

Write-Host ("=" * $w) -ForegroundColor Gray
Write-Host ""
Write-Host "  SON RAPOR" -ForegroundColor White
Write-Host ("  " + "-" * ([Math]::Max(10, $w - 2))) -ForegroundColor DarkGray
Write-Host "  Tarama suresi : $limitGoster" -ForegroundColor Gray
Write-Host "  Toplam sure   : ($toplamSure)" -ForegroundColor Gray
Write-Host "  Taranan dosya : $sayacToplam" -ForegroundColor Gray
Write-Host ""
Write-Host "  Sonuclar      : $($sonuclar.Count) hareket  |  " -NoNewline -ForegroundColor Green
Write-Host "$sayYeni yeni " -NoNewline -ForegroundColor Cyan
Write-Host "| " -NoNewline -ForegroundColor Gray
Write-Host "$sayDegisti degismis " -NoNewline -ForegroundColor Magenta
Write-Host "| " -NoNewline -ForegroundColor Gray
Write-Host "$saySilindi silindi/yeniden adlandirildi" -ForegroundColor Red
Write-Host "  Toplam boyut  : $toplamBoyut" -ForegroundColor Yellow
Write-Host ""

if ($topFolderlar.Count -gt 0) {
    Write-Host "  En yogun klasorler:" -ForegroundColor Cyan
    foreach ($kl in $topFolderlar) {
        Write-Host "    $($kl.Name)" -NoNewline -ForegroundColor White
        Write-Host "  -  $($kl.Value) dosya" -ForegroundColor DarkCyan
    }
    Write-Host ""
}

Write-Host ("=" * $w) -ForegroundColor Gray
Write-Host ""
Write-Host "  Islem tamamlandi. Kapatmak icin bir tusa basin..." -ForegroundColor Gray
$null = [Console]::ReadKey()
