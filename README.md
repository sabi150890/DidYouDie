# DidYouDie 💀

> *Bleib liegen du Pfosten.*

A World of Warcraft addon that punishes every death with a giant red flashing message bouncing across your screen — DVD screensaver style. A random snarky comment makes sure the message really hits home. And just to twist the knife, the **Release Spirit** button stays locked until you hold your configured modifier key.

Because dying should hurt a little extra.

---

## Features

- 🔴 **Bouncing death message** — giant red text ricochets off all four screen edges like a deranged DVD logo
- 💬 **Random taunts** — a snarky white comment appears below the red text on every death (50+ WoW-themed lines)
- 🔒 **Release Spirit lock** — the "Release Spirit" button is disabled until you hold your chosen modifier key
- ⚙️ **Configurable unlock key** — choose between Shift, Ctrl, Alt, or None in the addon settings
- 📊 **Persistent death counter** — tracks your total deaths across sessions, visible in the settings panel
- 🔁 **Reset button** — wipe your death count when the shame becomes too much

---

## Installation

### Manual
1. Download the latest release as a `.zip`
2. Extract the `DidYouDie` folder into your WoW AddOns directory:
   ```
   World of Warcraft/_retail_/Interface/AddOns/
   ```
3. Launch WoW and enable the addon in the AddOns menu on the character selection screen

### CurseForge
Search for **DidYouDie** on [CurseForge](https://www.curseforge.com/wow/addons) and install via the CurseForge App.

---

## Usage

The addon works automatically — no setup required. Just play the game and die.

On death:
- A large red **"Bleib liegen du Pfosten!"** message starts bouncing across your screen
- A random taunt appears below in white
- The **Release Spirit** button is locked until you hold your configured key (default: **Shift**)

The animation stops automatically when you release your spirit or resurrect.

---

## Settings

Open **ESC → Settings → Addons → DidYouDie** to:

| Setting | Description |
|---|---|
| **Death counter** | Shows your total death count across all sessions |
| **Reset counter** | Resets the death count back to zero |
| **Unlock key** | Choose which key unlocks the Release Spirit button (Shift / Ctrl / Alt / None) |

---

## Compatibility

| Version | Status |
|---|---|
| The War Within (11.x) | ✅ Supported |
| Dragonflight (10.x) | ✅ Supported |
| Wrath Classic | ❌ Not tested |

---

## Contributing

Pull requests are welcome! If you have a great taunt line to add, open an issue or PR.

The taunt lines live in `BleibLiegen.lua` in the `TAUNT_LINES` table — easy to extend.

---

## License

MIT — do whatever you want, just don't blame us when you die.
