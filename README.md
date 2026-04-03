# Last Enlarged Files Scanner

> A portable, dependency-free Windows batch/PowerShell hybrid that scans a directory tree for recently created or modified files, sorts them by size, and delivers an instant, color-coded terminal report.

---

## Table of Contents

- [What It Does](#what-it-does)
- [Unique Features](#unique-features)
- [How to Use](#how-to-use)
- [Output & Report](#output--report)
- [Security Notes](#security-notes)
- [System Requirements & Compatibility](#system-requirements--compatibility)

---

## What It Does

Last Enlarged Files Scanner helps you answer a very practical question:

> **"What files appeared or grew on my disk in the last N hours — and which ones are taking up the most space?"**

You drop the `.bat` file into any folder, run it, specify a lookback window (e.g. `5s` for 5 hours, `3g` for 3 days), and within seconds you have a full list of every new, changed, or mid-scan-deleted file in that directory tree — sorted from smallest to largest so the most impactful files land right above the summary report.

Common use cases:

- Tracking which application is silently writing large files to disk
- Auditing a project folder after an install, build, or sync operation
- Quickly finding files created or modified during a specific session
- Monitoring download or cache directories for unexpected growth

---

## Unique Features

### Two-pass streaming scan with real-time feedback

The scanner runs in two distinct phases. In the first pass, every file in the tree is visited and immediately checked against the time limit — no buffering, no waiting. The status line updates live:

```
Gecen: (00:00:12) | Taranan: 26,400 | Eslesen: 47
```

If zero matches are found after the full pass, the tool exits immediately without running phase two. On large drives with no recent activity this makes the tool feel near-instant.

### Timed interactive prompt

At launch, a 10-second countdown prompt accepts a time window in a compact format. If the countdown expires without input, the tool starts automatically with a 5-hour default — no keypress required, safe for scripted or unattended use.

```
Lutfen sure girin (-8s): 3g
```

Supported units: `s` (hours), `g` (days), `h` (weeks), `a` (months), `y` (years).

### Mid-scan deletion detection

Files that were present at the start of phase one but disappear before phase two completes are caught and reported as `[DELETED/RENAMED]`. On busy directories with active write traffic, this surfaces ephemeral files that would otherwise go unnoticed.

### Ascending size sort — largest file lands last

Results are sorted smallest-to-largest so that the most disk-significant file appears directly above the summary report, without any scrolling. This is intentional: the primary use case is spotting the file that consumed the most space, and it should be the last thing you read before the totals.

### Folder concentration report

The summary section identifies which directories contain the highest density of matching files, counting each file toward all of its ancestor directories. If 50 out of 75 results share a common parent, that parent surfaces at the top of the list:

```
En yogun klasorler:
  C:\Users\...\AppData\Local\Temp  -  38 dosya
  C:\Users\...\AppData             -  41 dosya
```

A folder must contain at least 2 matching files to appear. The scan root itself is excluded.

### Reparse point safety

Junction points and symbolic links are skipped via `-Attributes !ReparsePoint`, preventing infinite recursion on directories that loop back into themselves.

### Self-maximizing window

On launch the tool calls `FindWindow("ConsoleWindowClass", ...)` via `user32.dll` to locate the actual console host handle and maximize it — independent of the PowerShell process ID, which does not own a visible window.

### No dependencies

The tool is a single `.bat` file. It requires nothing beyond what ships with Windows. No PowerShell modules, no third-party executables, no installation.

---

## How to Use

1. Copy `dosya_takip.bat` into the folder you want to scan (or any parent of it).
2. Double-click the file, or run it from an existing terminal.
3. When prompted, type a time window and press Enter — or wait 10 seconds to use the 5-hour default.
4. Review the live status line during scanning, then read the report.

**Time format examples:**

| Input | Meaning        |
|-------|---------------|
| `1s`  | Last 1 hour    |
| `5s`  | Last 5 hours   |
| `3g`  | Last 3 days    |
| `2h`  | Last 2 weeks   |
| `1a`  | Last 1 month   |
| `1y`  | Last 1 year    |

Invalid input or no input → 5-hour default.

---

## Output & Report

Each result line follows this format:

```
[STATUS] C:\full\path\to\file.ext
   Boyut: 1.23 GB | Tarih: 04/03/2026 14:22:01
```

Status labels and their colors:

| Label              | Color   | Meaning                                              |
|--------------------|---------|------------------------------------------------------|
| `NEW`              | Cyan    | Created within the time window, not modified since   |
| `NEW+CHANGED`      | Cyan    | Created and subsequently modified within the window  |
| `NEW (COPIED?)`    | Cyan    | Creation time is recent but write time predates it   |
| `CHANGED`          | Magenta | Pre-existing file modified within the window         |
| `DELETED/RENAMED`  | Red     | Present at scan start, gone before analysis finished |

The summary report at the bottom includes:

- Lookback window and total elapsed time
- Total files scanned
- Count breakdown by status
- Combined size of all matched files
- Top 5 most active directories (minimum 2 files each)

---

## Security Notes

**This tool calls a Windows API function (`ShowWindow` from `user32.dll`) via inline C# compiled at runtime through PowerShell's `Add-Type`.**

- No network calls are made at any point.
- No files are written, moved, or deleted. The tool is strictly read-only with respect to the files it scans.
- The compiled C# type exists only for the duration of the PowerShell session and is discarded when the window closes.
- `ExecutionPolicy Bypass` is used only for the scope of this single invocation. It does not change the system-wide execution policy.
- The script runs with the privileges of the user who launched it. It does not request elevation. Scanning directories that require elevated access will silently skip those paths via `-ErrorAction SilentlyContinue`.

**Review the source before running any `.bat` file from an untrusted source.** This file's PowerShell code begins after the `#>` marker and is fully human-readable in any text editor.

---

## System Requirements & Compatibility

| Requirement         | Details                                              |
|---------------------|------------------------------------------------------|
| **OS**              | Windows 10 or Windows 11                            |
| **PowerShell**      | 5.1 (built-in on Win 10/11) — no upgrade needed     |
| **Terminal host**   | Windows Console Host (`conhost.exe`) — classic CMD window or Run dialog. Windows Terminal (`wt.exe`) is supported with automatic fallback for window maximization. |
| **Permissions**     | Standard user. No elevation required.               |
| **Dependencies**    | None. Single `.bat` file, no install.               |
| **Encoding**        | UTF-8 console output. File paths with any characters (including `[`, `]`, `(`, `)`) are handled correctly via `-LiteralPath`. |

**Not supported:**

- Windows 7 / 8 / 8.1 (PowerShell 5.1 not available)
- PowerShell Core / PowerShell 7+ (not tested; may work but unsupported)
- Running inside VS Code's integrated terminal or other hosted consoles (window maximize may not function; scanning works normally)
- Network drives with very high latency (scanning will work but may be slow)

---

---
---

# Last Enlarged Files Scanner — Turkce Dokumantasyon

> Bir klasor agacini belirtilen zaman araliginda tarayip, olusturulan veya degistirilen dosyalari boyuta gore siralayarak renk kodlu terminal raporu sunan; bagimsiz, kurulum gerektirmeyen bir Windows bat/PowerShell aracı.

---

## Icerik

- [Ne Ise Yarar](#ne-ise-yarar)
- [One Cikan Ozellikler](#one-cikan-ozellikler)
- [Nasil Kullanilir](#nasil-kullanilir)
- [Cikti ve Rapor](#cikti-ve-rapor)
- [Guvenlik Notlari](#guvenlik-notlari)
- [Sistem Gereksinimleri ve Uyumluluk](#sistem-gereksinimleri-ve-uyumluluk)

---

## Ne Ise Yarar

Last Enlarged Files Scanner son derece pratik bir soruyu yanıtlamak icin tasarlanmistir:

> **"Son N saat icinde diskimde hangi dosyalar olusturuldu ya da buyudu — ve en cok yer kaplayan hangisi?"**

`.bat` dosyasini taramak istediginiz klasore kopyalayip calistiriyor, bir zaman araligı giriyorsunuz (ornegin `5s` = 5 saat, `3g` = 3 gun). Birkaç saniye icinde o klasor agacındaki yeni, degismis veya tarama sirasinda silinen tum dosyalarin listesi hazir — kucukten buyuge sirali sekilde, en buyuk dosya ozet raporun hemen ustunde.

Yaygin kullanim senaryolari:

- Diske sessizce buyuk dosyalar yazan uygulamayi tespit etmek
- Kurulum, derleme veya senkronizasyon sonrasinda proje klasorunu denetlemek
- Belirli bir oturum sirasinda olusturulan veya degistirilen dosyalari bulmak
- Indirme veya onbellek klasorlerini beklenmedik buyume icin izlemek

---

## One Cikan Ozellikler

### Gercek zamanli akis ile iki kademe tarama

Tarayici iki asamali calisir. Birinci geciste agactaki her dosya aninda zaman limitiyle karsilastirilir — tamponlama veya bekleme yoktur. Durum satiri canli olarak guncellenir:

```
Gecen: (00:00:12) | Taranan: 26.400 | Eslesen: 47
```

Birinci gecis sifir eslesmesiyle biterse ikinci asama hic baslamaz. Buyuk disklerde son zamanlarda hic degisiklik yoksa arac neredeyse aninda kapanır.

### Zamanli giris istemi

Ac ilista 10 saniyelik geri sayimli bir istem, kompakt formatta bir zaman penceresi kabul eder. Sure dolmadan giris yapilmazsa arac otomatik olarak 5 saat varsayilaniyla baslar — herhangi bir tus gerektirmez.

```
Lutfen sure girin (-8s): 3g
```

Desteklenen birimler: `s` (saat), `g` (gun), `h` (hafta), `a` (ay), `y` (yil).

### Tarama sirasinda silinen dosyalarin tespiti

Birinci asama basinda mevcut olup ikinci asama tamamlanmadan kaybolan dosyalar `[DELETED/RENAMED]` olarak raporlanir. Yogun yazma trafiginizin oldugu klasorlerde, baska turlu fark edilemeyecek gecici dosyalarin izini surmenizi saglar.

### Artan boyut siralamasi — en buyuk dosya en altta

Sonuclar kucukten buyuge siralanır; en cok disk alanı kaplayan dosya ozet raporun hemen ustunde yer alir, asagi kaydrma gerekmez. Bu bilinclı bir tasarim tercihi: en buyuk dosyayi bulmak birincil kullanim senaryosudur ve toplam rakamlari okumadan once son gordugunuz sey o olmalidir.

### Klasor yogunlugu raporu

Ozet bolumu, eslesen dosyalarin en yogun oldugu klasorleri belirler. Her dosya tum ata-dizinlerine +1 olarak sayilir. 75 sonuctan 50'si ortak bir ust-klasorde toplaniyorsa o klasor listenin basinda gorünur:

```
En yogun klasorler:
  C:\Users\...\AppData\Local\Temp  -  38 dosya
  C:\Users\...\AppData             -  41 dosya
```

Bir klasorun listede gozukebilmesi icin en az 2 eslesen dosya icermesi gerekir. Tarama kök dizini daima hariç tutulur.

### Yeniden ayristirma noktasi guvenligi

Birlestirme noktalar (junction) ve sembolik baglantilar `-Attributes !ReparsePoint` ile atlanir; kendi icine donen dizinlerde sonsuz donguden korunur.

### Otomatik pencere buyutme

Arac acildiginda, PowerShell proses ID'si uzerinden degil, doğrudan `user32.dll` uzerinden `FindWindow("ConsoleWindowClass", ...)` cagirarak gercek konsol pencere tanıtıcısini bulur ve pencereyi tam ekrana alir.

### Bagimlilik yok

Tek bir `.bat` dosyasidir. Windows ile birlikte gelen bilesenler disinda hicbir sey gerektirmez. Ek PowerShell modulu, ücüncü taraf program veya kurulum yoktur.

---

## Nasil Kullanilir

1. `dosya_takip.bat` dosyasini taramak istediginiz klasore (ya da bir ust klasore) kopyalayin.
2. Dosyaya cift tiklayin veya mevcut bir terminalden calistirin.
3. Istem gorundugunde bir zaman penceresi yazin ve Enter'a basin — ya da 10 saniye bekleyerek 5 saat varsayilaniyla baslatin.
4. Tarama sirasinda canli durum satirini takip edin, ardından raporu okuyun.

**Zaman formati ornekleri:**

| Giris | Anlam           |
|-------|-----------------|
| `1s`  | Son 1 saat      |
| `5s`  | Son 5 saat      |
| `3g`  | Son 3 gun       |
| `2h`  | Son 2 hafta     |
| `1a`  | Son 1 ay        |
| `1y`  | Son 1 yil       |

Gecersiz veya bos giris → 5 saat varsayilani.

---

## Cikti ve Rapor

Her sonuc satiri su formattadir:

```
[DURUM] C:\tam\yol\dosya.ext
   Boyut: 1.23 GB | Tarih: 03/04/2026 14:22:01
```

Durum etiketleri ve renkleri:

| Etiket               | Renk    | Anlam                                                     |
|----------------------|---------|-----------------------------------------------------------|
| `NEW`                | Cyan    | Zaman penceresi icinde olusturuldu, sonra degismedi       |
| `NEW+CHANGED`        | Cyan    | Zaman penceresi icinde olusturuldu ve daha sonra degisti  |
| `NEW (COPIED?)`      | Cyan    | Olusturma zamani yeni ama yazma zamani oncesine ait       |
| `CHANGED`            | Magenta | Onceden var olan dosya zaman penceresi icinde degisti     |
| `DELETED/RENAMED`    | Red     | Tarama basinda mevcut, analiz bitmeden kayboldu           |

Alt ozet raporu sunlari icerir:

- Tarama suresi ve toplam gecen sure
- Taranan toplam dosya sayisi
- Duruma gore sayim dagilimi
- Eslesen tum dosyalarin toplam boyutu
- En aktif 5 klasor (her birinde en az 2 dosya olmak uzere)

---

## Guvenlik Notlari

**Bu arac, PowerShell'in `Add-Type` mekanizmasi uzerinden calisma zamaninda derlenen satirici C# kodu araciligiyla `user32.dll` icerisindeki `ShowWindow` Windows API fonksiyonunu cagirmaktadir.**

- Hicbir ag cagrisi yapilmaz.
- Taranan dosyalara yazilmaz, tasinmaz veya silinmez. Arac, inceledigi dosyalar acisindan tamamen salt-okunur modda calisir.
- Derlenen C# tipi yalnizca PowerShell oturumu boyunca var olur; pencere kapaninca silinir.
- `ExecutionPolicy Bypass` yalnizca bu tek cagri kapsaminda gecerlidir; sistem genelindeki yurutme politikasini degistirmez.
- Komut dosyasi, calistiran kullanicinin ayrıcaliklariyla calisir; yukseltme istemez. Erisim gerektiren klasorler `-ErrorAction SilentlyContinue` ile sessizce atlanir.

**Guvenilmeyen bir kaynaktan alinan herhangi bir `.bat` dosyasini calistirmadan once kaynagini inceleyin.** Bu dosyanin PowerShell kodu `#>` isaretinden sonra baslar ve herhangi bir metin duzenleyicisiyle tamamen okunabilir durumdadir.

---

## Sistem Gereksinimleri ve Uyumluluk

| Gereksinim            | Detaylar                                                                                                                                                                        |
|-----------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Isletim sistemi**   | Windows 10 veya Windows 11                                                                                                                                                      |
| **PowerShell**        | 5.1 (Win 10/11 ile birlikte gelir — guncelleme gerekmez)                                                                                                                        |
| **Terminal sunucusu** | Windows Console Host (`conhost.exe`) — klasik CMD penceresi veya Calistir istemi. Windows Terminal (`wt.exe`) de desteklenir; pencere buyutme icin otomatik geri donus mevcuttur. |
| **Izinler**           | Standart kullanici. Yukseltme gerekmez.                                                                                                                                         |
| **Bagimliliklar**     | Yok. Tek `.bat` dosyasi, kurulum yok.                                                                                                                                           |
| **Kodlama**           | UTF-8 konsol ciktisi. `[`, `]`, `(`, `)` dahil ozel karakter iceren dosya yollari `-LiteralPath` sayesinde dogru sekilde islenir.                                               |

**Desteklenmeyen ortamlar:**

- Windows 7 / 8 / 8.1 (PowerShell 5.1 mevcut degil)
- PowerShell Core / PowerShell 7+ (test edilmedi; calisabilir fakat desteklenmez)
- VS Code entegre terminali veya diger barindirilan konsollar (pencere buyutme calismayabilir; tarama normal sekilde isler)
- Cok yuksek gecikme sureli ag suruculeri (tarama calisir ancak yavash olabilir)
