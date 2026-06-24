# zapret2-v1.0.1

Bu repo, `zapret2` v1.0.1 paketini ve Windows uzerinde Roblox icin hazirlanmis kolay kullanim scriptlerini birlikte sunar.

Amac, repo indirildikten sonra ek ayar aramadan arayuzlu uygulamayi acip temel baslatma, durdurma ve baglanti testi adimlarini dogrudan kullanabilmektir.

## Bu repoda ne var

- `zapret2` kaynak kodlari
- Hazir derlenmis binary dosyalari
- Orijinal dokumantasyonlar (`docs/`)
- Modern gorunumlu Windows kontrol merkezi
- Windows icin hazir Roblox DPI bypass scriptleri

## Hangi dosya ne ise yarar

- `zapret2_kontrol_merkezi.cmd`
  En kolay giris noktasi budur. Arayuzlu uygulamayi acar, gerekiyorsa Yonetici izni ister ve servis durumunu gosteren kontrol panelini baslatir.
- `zapret2-roblox-ui.ps1`
  Modern arayuzun kendisidir. Baslat, durdur, test et, log goruntule ve durum takibi yapar.
- `zapret2-roblox-common.ps1`
  Tum baslatma, durdurma, test ve durum denetimi mantigini ortak olarak tutar.
- `start_roblox_dpi_bypass.cmd`
  Windows tarafinda en kolay baslatma dosyasidir. Gerekirse Yonetici izni ister ve arka planda bypass'i baslatir.
- `stop_roblox_dpi_bypass.cmd`
  Calisan `winws2.exe` surecini kapatir.
- `test_roblox_reachability.cmd`
  Tek tikla Roblox erisim testini calistirir.
- `test_roblox_reachability.ps1`
  Roblox ile ilgili bazi HTTPS adreslerine erisim testi yapar.
- `roblox-bypass.conf`
  Kullanilan temel parametrelerin metin karsiligidir.
- `start_roblox_dpi_bypass.ps1`
  Asil baslatma mantigini icerir.

## Hizli kullanim

1. Repoyu indirin veya `git clone` ile cekin.
2. Klasoru acin.
3. `zapret2_kontrol_merkezi.cmd` dosyasina cift tiklayin.
4. Windows Yonetici izni isterse onay verin.
5. Acilan arayuzden `Bypass Baslat` dugmesine basin.
6. Isterseniz ayni ekrandan `Roblox Erisim Testi` calistirin.
7. Sonra Roblox baglantinizi deneyin.

Durdurmak icin:

1. Arayuzde `Bypass Durdur` dugmesine basin.
2. Isterseniz dogrudan `stop_roblox_dpi_bypass.cmd` dosyasini da calistirabilirsiniz.

Baglanti testi yapmak icin en kolay yol:

1. `test_roblox_reachability.cmd` dosyasini calistirin.

Alternatif olarak PowerShell'de:

```powershell
powershell -ExecutionPolicy Bypass -File .\test_roblox_reachability.ps1
```

## Teknik ozet

Bu kurulum Windows tarafinda `binaries/windows-x86_64/winws2.exe` kullanir.

Baslatma sirasinda:

- `lua/zapret-lib.lua`
- `lua/zapret-antidpi.lua`

yuklenir ve secili Roblox/CDN IP araliklari icin TLS `ClientHello` trafigine odakli dar kapsamli desync kurallari uygulanir.

## Arayuzde neler var

- Anlik acik-kapali durum rozeti
- Tek tusla baslatma ve durdurma
- Roblox erisim testi
- Son log satirlarini canli gosterme
- Log dosyasini ve proje klasorunu tek tusla acma
- Surecin PID ve son log guncelleme zamanini gosterme

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
