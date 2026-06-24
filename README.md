# zapret2-v1.0.1

Bu repo, `zapret2` v1.0.1 paketini ve Windows uzerinde Roblox icin hazirlanmis kolay kullanim scriptlerini birlikte sunar.

Amac, repo indirildikten sonra ek ayar aramadan temel baslatma, durdurma ve baglanti testi adimlarinin dogrudan calistirilabilmesidir.

## Bu repoda ne var

- `zapret2` kaynak kodlari
- Hazir derlenmis binary dosyalari
- Orijinal dokumantasyonlar (`docs/`)
- Windows icin hazir Roblox DPI bypass scriptleri

## Hangi dosya ne ise yarar

- `start_roblox_dpi_bypass.cmd`
  Windows tarafinda en kolay baslatma dosyasidir. Gerekirse Yonetici izni ister ve arka planda bypass'i baslatir.
- `stop_roblox_dpi_bypass.cmd`
  Calisan `winws2.exe` surecini kapatir.
- `test_roblox_reachability.ps1`
  Roblox ile ilgili bazi HTTPS adreslerine erisim testi yapar.
- `roblox-bypass.conf`
  Kullanilan temel parametrelerin metin karsiligidir.
- `start_roblox_dpi_bypass.ps1`
  Asil baslatma mantigini icerir.

## Hizli kullanim

1. Repoyu indirin veya `git clone` ile cekin.
2. Klasoru acin.
3. `start_roblox_dpi_bypass.cmd` dosyasina cift tiklayin.
4. Windows Yonetici izni isterse onay verin.
5. Baslatma sonrasi Roblox baglantinizi deneyin.

Durdurmak icin:

1. `stop_roblox_dpi_bypass.cmd` dosyasini calistirin.

Baglanti testi yapmak icin PowerShell'de:

```powershell
powershell -ExecutionPolicy Bypass -File .\test_roblox_reachability.ps1
```

## Teknik ozet

Bu kurulum Windows tarafinda `binaries/windows-x86_64/winws2.exe` kullanir.

Baslatma sirasinda:

- `lua/zapret-lib.lua`
- `lua/zapret-antidpi.lua`

yuklenir ve secili Roblox/CDN IP araliklari icin TLS `ClientHello` trafigine odakli dar kapsamli desync kurallari uygulanir.

## Kimler icin uygun

Bu repo en cok su kullanim icin uygundur:

- Windows kullananlar
- Hazir script ile hizli deneme yapmak isteyenler
- `zapret2` ic yapisini sonra ayrica incelemek isteyenler

Eger amaciniz tum servisler icin genel bir DPI araci kullanmaksa, `docs/` altindaki orijinal dokumantasyona da bakmaniz gerekir.

## Notlar

- Log dosyalari ve yedek `.bak` dosyalari bilincli olarak Git disinda tutulur.
- Orijinal upstream dokumantasyonu korunmustur.
- Bu repo, genel amacli bir kurulum sihirbazi degil; Windows + Roblox odakli hazir bir baslangic noktasi sunar.
