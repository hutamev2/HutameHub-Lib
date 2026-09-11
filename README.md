<div align="center">

# ⚡ HutameHub UI Library

**Modern, Lightweight & High-Performance Roblox Luau UI Framework**

[![GitHub Stars](https://img.shields.io/github/stars/hutamev2/HutameHub-Lib?style=for-the-badge&color=00ff80&labelColor=0a0a0c)](https://github.com/hutamev2/HutameHub-Lib/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/hutamev2/HutameHub-Lib?style=for-the-badge&color=00ff80&labelColor=0a0a0c)](https://github.com/hutamev2/HutameHub-Lib/network)
[![License](https://img.shields.io/badge/License-MIT-00ff80?style=for-the-badge&labelColor=0a0a0c)](LICENSE)

**[📚 Dokümantasyon Sitesi](https://hutamev2.github.io/HutameHub-Lib)** • **[🐛 Issue Bildir](https://github.com/hutamev2/HutameHub-Lib/issues)** • **[⭐ Star Ver](https://github.com/hutamev2/HutameHub-Lib)**

</div>

---

Roblox Luau için sıfırdan geliştirilmiş; **Rayfield** ve **Kavo** gibi ağır kütüphanelerin aksine yalnızca yerleşik `Instance.new`, `TweenService` ve `UserInputService` kullanan, ultra hafif, **60+ FPS** odaklı modern UI kütüphanesi.

## v2.2 — Violet Studio

Koyu mor yüzeyler, lila vurgu, keskin köşeler, ince iç çerçeve, monospace yazı ve hafif gölgeli kontroller. Akiri Lib yalnızca görsel referans olarak incelendi; tasarım mevcut Roblox Instance koduyla bağımsız uygulandı. Public API korundu. Ana pencere kar efekti artık varsayılan kapalı; `SnowEffect = true` ile açılır. Loading ekranının karı ayrı çalışır.

[Tüm UI özelliklerini test et](docs/examples/ui-test.lua) · [Dokümantasyon örneği](https://hutamev2.github.io/HutameHub-Lib/#s-fullexample)

UI penceresini `RightControl` veya `Minus (-)` ile gizleyip gösterebilirsin. Minus, özel `ToggleKey` ayarlansa da çalışır; metin kutusuna yazarken kısayollar devreye girmez.

## ✨ Özellikler

- **Dropdown yerleşimi:** tekli/çoklu liste section içinde yer açar; alttaki düğmeleri aşağı iter. `MaxVisibleItems` (varsayılan 6, 1–20) sonrası iç kaydırma kullanılır. Section aç/kapat geçişi iptal edilebilir 0.2 saniyelik tween ile çalışır. Test örneğindeki **Layout** sekmesinden kontrol edebilirsin.

- **Config profilleri:** oluştur, yükle, yeniden adlandır, sil ve varsayılan seç. Yedi değer kontrolü `ConfigKey` ile kaydedilir.
- **Mobil düğme:** dokunmatik cihazlarda otomatik; `MobileToggle = true` ile masaüstünde de gösterilir. Taşı veya dokunarak UI'ı aç/kapat.
- **Sıfırlama:** `control:Reset()` ve `Hub:ResetValues()`.
- **Koşullar:** `VisibleWhen`, `EnabledWhen`, `Hub:SetCondition()`.
- **Tuş çakışması:** aynı tuşa atanan eylemleri bildiren uyarı.
- **Onay penceresi:** `Hub:Confirm({Title, Text, OnConfirm, OnCancel})`.

[API rehberi](docs/features.md) · Test örneğindeki **Profiles** sekmesi bütün yeni özellikleri denemek içindir. Profil işlemleri `readfile`/`writefile`, silme ve yeniden adlandırma ayrıca `delfile` gerektirir.

| Özellik | Detay |
|---------|-------|
| 🚀 **Ultra Hafif** | Sadece Roblox yerleşik API'leri, sıfır harici bağımlılık |
| 🎨 **Canlı Accent Rengi** | Çalışma anında `SetAccent()` ile anlık tema değişimi |
| 📱 **Mobil & PC** | Touch ve Mouse sürükleme desteği |
| ⚡ **60+ FPS** | TweenService optimizasyonlu pürüzsüz animasyonlar |
| 🏗️ **OOP Mimari** | `Window → Tab → Section → Element` hiyerarşisi |
| 🔒 **CoreGui Koruması** | Otomatik güvenli parent seçimi |

## 🚀 Hızlı Başlangıç

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua"))()

local Window = Library.new({
    Title    = "HutameHub",
    Version = "v2.2",
    Accent   = Color3.fromRGB(192, 139, 230),
    SnowEffect = false
})

local Tab     = Window:CreateTab("Combat")
local Section = Tab:CreateSection("Silent Aim Settings")

Section:CreateToggle({
    Title    = "Enable Silent Aim",
    Default  = false,
    Callback = function(state)
        print("Silent Aim:", state)
    end
})

Section:CreateSlider({
    Title    = "FOV Radius",
    Min      = 10,
    Max      = 500,
    Default  = 120,
    Decimals = 0,
    Callback = function(value)
        print("FOV:", value)
    end
})
```

## 📦 Bileşenler

| Bileşen | Method | Dönen Değer |
|---------|--------|-------------|
| Pencere | `Library.new(config)` | `Window` |
| Sekme | `Window:CreateTab(name)` | `Tab` |
| Bölüm | `Tab:CreateSection(title)` | `Section` |
| Toggle | `Section:CreateToggle(config)` | `{ State, Set() }` |
| Slider | `Section:CreateSlider(config)` | `{ Value, Set() }` |
| Dropdown | `Section:CreateDropdown(config)` | `{ Selected, Set(), Refresh() }` |
| Textbox | `Section:CreateTextbox(config)` | `{ Text, Set() }` |
| Keybind | `Section:CreateKeybind(config)` | `{ Key, Set() }` |
| ColorPicker | `Section:CreateColorPicker(config)` | `{ Color, Set() }` |
| Button | `Section:CreateButton(config)` | `TextButton` |

## 📚 Tam Dokümantasyon

Tüm API referansı, parametreler, canlı UI simülatörü ve örnekler için:

**👉 [hutamev2.github.io/HutameHub-Lib](https://hutamev2.github.io/HutameHub-Lib)**

## 🎮 Tam Kullanım Örneği

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/hutamev2/HutameHub-Lib/main/Source.lua"))()

local Window      = Library.new({ Title = "HutameHub", Version = "v2.2", Accent = Color3.fromRGB(192, 139, 230) })
local MainTab     = Window:CreateTab("Combat")
local SettingsTab = Window:CreateTab("Settings")
local AimSection  = MainTab:CreateSection("Silent Aim Settings")
local CfgSection  = SettingsTab:CreateSection("Preferences")

AimSection:CreateToggle({ Title = "Silent Aim",    Default = false, Callback = function(s) print(s) end })
AimSection:CreateSlider({ Title = "FOV Radius",    Min = 10, Max = 500, Default = 120, Callback = function(v) print(v) end })
AimSection:CreateDropdown({ Title = "Target",      Options = {"Head","Torso","HumanoidRootPart"}, Default = "Head", Callback = function(s) print(s) end })

CfgSection:CreateTextbox({ Title = "Webhook URL", Placeholder = "https://discord.com/api/webhooks/...", Callback = function(t) print(t) end })
CfgSection:CreateKeybind({ Title = "Toggle Key",  Default = Enum.KeyCode.RightControl, Callback = function(k) print(k.Name) end })
CfgSection:CreateColorPicker({ Title = "Accent",  Default = Color3.fromRGB(192, 139, 230), Callback = function(c) Window:SetAccent(c) end })
CfgSection:CreateButton({ Title = "Destroy UI",   Callback = function() Window:Destroy() end })
```

## 📄 Lisans

MIT License — özgürce kullanabilir, değiştirebilir ve dağıtabilirsin.

---

<div align="center">
Made with ❤️ by <a href="https://github.com/hutamev2">HutameV2</a>
</div>
