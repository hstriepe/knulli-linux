# Knulli - Fork (hstriepe/knulli-linux) - unreleased

## Changelog

#### ADDED
* **Build:** Build on macOS hosts (Apple Silicon) with OrbStack and a case-sensitive build volume. The `*_armhf_libs` targets run in an amd64 image under Rosetta.
* **Network diagnostics:** New `knulli-diag-net` command writes a report on SSH, Samba, WiFi and scraper state to `/userdata/system/logs/`. The report can be read over the share when SSH is down.

#### IMPROVED
* **Wi-Fi (H700):** Turned off RTL8821CS power saving (`rtw_power_mgnt=0`, `rtw_ips_mode=0`) and connman background scanning, so WPA2 connections stay up.

#### FIXED
* **SSH on exFAT/NTFS shares:** Fixed key-based login when SHARE isn't ext4/btrfs. The host keys and `authorized_keys` stay on the share, and SSH now reads them from a private copy made at start. Restart SSH after editing `authorized_keys`.
* **Samba on exFAT/NTFS/FAT32 shares:** Turned off extended-attribute storage (DOS attributes/streams) on these filesystems, and allowed macOS `._*` files so Finder copies work.
* **Libretro cores:** Fixed the `mame` build (cross-compiler passed to genie) and the `hatari` build (upstream `main` branch, CMake).

# Knulli - SCARAB - (20260511)

## Changelog

#### ADDED
* **Device Support:**
    * Added support for revisioned devices of the **Anbernic RG XX series** (H700).
    * Added support for **Miyoo Flip, Powkiddy X55 and RGB30, and Anbernic RG ARC-S** (Rockchip RK3566).
    * Added support for **Retroid Pocket 5, Flip 2, Mini, and Mini V2** (Qualcomm SM8250).
    * Added support for **GKD Pixel 2, BattleXP G350, MagicX Xu mini-m, and R36S** (Rockchip RK3326).
    * Added initial alpha support for **TrimUI Smart Pro S (TSPS)** (Allwinner A527).
    * Added initial alpha support for **Anbernic RG Vita Pro** (RK3576) and **RG-DS** (RK3568).
* **OS Features:**
    * **Syncthing Integration:** Added full menu support for Syncthing (Device Settings -> Sync Now) including "Scan on Game Exit" and ES notifications.
    * **Battery HUD:** Added a new Head-Up Display setting to show real-time battery percentage during gameplay (Decorations -> HUD -> Battery).
    * **GPU Boost:** New service to dynamically adjust GPU frequency based on CPU load for better performance.
    * **SilkyRGB:** Integrated new LED management software for advanced effects and RetroAchievements animations (Thanks doughno!).
    * **Terminal:** Added VaixTerm terminal program.
    * **Advanced Fan Control:** Added fan modes (quiet/normal/performance) for supported devices like RP5 and TSP-S.
    * Added new ES background music collection.
    * New soft reset (hotkey + double-tap start) which will restart ES and/or force close of running application.
* **Emulation:**
    * Added support for **Saturn (Yabasanshiro)** standalone emulator for H700 and RK3566.
    * Updated **RetroArch** to **1.22.2**.
    * Added `libretro-geolith` core support for Neo-Geo (.neo format).
    * Added `libretro melonDS-DS` core.
    * Added support for **Gamecube (dolphin)** and **Wii (dolphin)**, **3DS (Azahar)**, and **PS2 (AetherSX2)** on compatible high-performance devices.

#### IMPROVED
* **System Architecture:** Restructured the repository using submodules for independent Buildroot and Batocera package management.
* **Battery Logic:** Implemented BatteryPlus for more accurate and dynamic battery percentage calculation by learning device-specific “full” states, including calibration status and battery voltage reporting in System Information.
* **Power Management:**
    * New **idlewatcher** with configurable hooks for `idle`, `extended`, and `active` states.
    * Enabled **RTC suspend** for auto-wake and safe shutdown, allowing **shutdown** after x minutes in **suspend**.
    * Added option for bypassing power saving while the device is being charged/plugged to a power source.
    * Applied general CPU undervolting for H700, a133, and RK3566 to improve thermals and battery life.
    * Added CPU frequency script and init service that builds available frequency lists directly in ES.
* **Connectivity:**
    * Significant improvements to Bluetooth pairing stability, responsiveness, and multiple controller handling.
    * Improved Wi-Fi auto-retry logic and internet connectivity checks.
    * Improved detection of internet connection on boot when retroachievements and quick resume are enabled.
* **Input:**
    * Added new input driver for a133 devices which support auto calibrating joysticks and rumble(thanks jpe230!).
* **Audio:**
    * Improved max volume for sm8250.
* **UI/ES:**
    * Added display color temperature settings for compatible devices.
    * Added power led setting for compatible devices(hotkey: hotkey + power).
    * Added advanced audio gain settings (+14 to +18dB).
    * Added RetroArch V-Sync and Hard GPU Sync settings to ES.
    * Added PortMaster installation directly into Device Settings.
    * Themes can now override notification Y-offsets to avoid overlap with battery/clock info.
    * Improved brightness dim/undim animation.
    * Added DSP ES setting for Flycast.
    * Added ES setting for periodic SRM save dumping for libretro cores; when enabled, in-game saves are written to SD card every 10 seconds to help prevent data loss. Enabled by default.
    * Added ES setting for max incremental save states.
    * Added ES settings for advanced drastic PiP corner and bilinear filtering.
    * Added ES settings for VBA/gpSP color correction and interframe blending.
* **Misc:**
    * SSH(dropbear) is now a service which can be enabled/disabled.
    * Set I/O scheduler to noop/none for reduced scheduling overhead.
    * Refactored and improved zramswap to prioritize lz4.
    * Automatic migration of legacy SD2 data(batocera.conf) on applicable devices.
    * Automatic pausing of battery saving features while scraping.
    * Updated A133 kernel modules. Added ZRAM support, and several wifi usb adapter support for Powkiddy V90s/V20.
#### FIXED
* **Storage:**
    * Fixed SHARE partition resize issues to ensure full compatibility with Windows and macOS.
* **Graphics/Display:**
    * Fixed screen and resume issues for newer RG40XX-V and RG40XX-H hardware revisions.
    * Fixed display orientation regressions on RG28XX.
    * Fixed HDMI switching and DRM connector issues for RK3566 devices.
    * Added additional injection methods for MangoHud compatibility with A133, RK3566, etc.
* **Audio:**
    * Fixed audio desync on SM8250 after suspend/resume.
    * Fixed headphone detection and audio routing on Miyoo Flip.
    * Fixed reversed audio channels on TrimUI Smart Pro S.
    * Fixed audio crashes when toggling Bluetooth states.
    * Fixed low volume with stand alone Yabasanshiro.
* **Emulation:**
    * Fixed viewport issues with RetroArch v1.22.
    * Fixed configuration and compilation flags for AetherSX2 and Azahar.
    * Fixed Advanced Drastic config generation when the config folder is missing.
* **General:**
    * Fixed the TrimUI Smart Pro-S Bootloader so it no longer has issues with Windows corrupting the partition table.

Full changelog can be seen [here](https://github.com/knulli-cfw/knulli-linux/compare/7dabcbbfaa93512530e99a130e40ab1e4166987a..6edb6906f0d2754f35259bad6e1d0de3eda7363a)

# Knulli - Gladiator II - (20250813)

## ChangeLog

### ADDED ###
- Devices support
    - Added support for Anbernic RG34XX SP
    - Added support for Anbernic RG35XX Pro
    - Added preliminary support for the Powkiddy V90S and V20
- OS features
    - Introduced [OTA (Over-The-Air) update support](https://knulli.org/play/update): Knulli now supports OTA updates, these update not only the root file system, but the internal partitions, so changes like kernel updates are being taken care of. Some important details about OTA:
      - Stable builds will get OTA updates for fixes but no major changes. Expect a 3-4 month update cycle
      - Alpha builds will get frequent OTA updates (limited to [Knulli supporters](https://knulli.org/community/contribute/))
    - Added [soft reset function hotkey shortcut](https://knulli.org/play/hotkey-shortcuts): Added new soft reset feature where holding hotkey and double tapping start on the device will force exit any running application and restart ES
    - Added disk check utility: Added a built in function to check sd card file system consistency
    - Added [factory reset script functionality](https://knulli.org/configure/reset-to-factory-settings): This allows to reset the systems folder when you update. You can do this if you have updated and some things are not working as expected. This option creates a backup of your current system folder in case you want to recover some data. It also adopts your previous PortMaster installation.
    - Introduced [Samba (SMB, Windows Network) as a dedicated service](https://knulli.org/play/add-games/network-transfer): Samba is now an optional service, you can enable it in ``Settings -> System Settings -> SAMBA``
    - Added device statistics gathering support: This helps us understand the adoption rate of the different builds as well as the overall interest on each particular model. Of course you can disable telemetry data if you desire to do so (Settings -> Device Settings -> Disable Telemetry)
  - Emulation features
    - bezel support for several standalone emulators on H700 devices
    - introduced new *Default-Knulli-SP* bezel decoration set for GBA on 4:3 SP displays

### FIXED ###
- OS features
    - Removed MTP (Media Transfer Protocol) support system-wide: Some preliminary alpha versions introduced MTP support. This resulted in several issues with file system corruption. It's now disabled until a better implementation is added. Users can still use SFTP, ADB, or SAMB
    - Fixed auto-assignment for USB controllers
    - Enhanced suspend/resume functionality across multiple devices
    - Improved USB and Bluetooth management during suspend
    - Improved power-off handling for various devices
    - Updated battery management and power saving
    - Improved lid control mechanisms
    - Cardinal snapping fixes for RG-CubeXX, RG35XX-H, RG40XX-H, and RG40XX-V
    - Fixed reversed L/R audio channels on A133 devices
    - Fixed RGB achievement effects on A133 devices
    - Fixed non-working toggle switch functionality on TrimUI Smart Pro
    - Fixed Bluetooth being enabled after boot on A133 devices despite being disabled in settings
    - Fixed devices not recovering from display-off mode (now brightness=0 instead)
    - Wi-Fi connection stability improvements with better timeout handling
    - Battery saver no longer suspends during media playback
    - Audio mute toggle now persists when changing outputs or entering menus
    - Resize script corrected for ExFAT conversion and partition order
- Emulation features
    - Fixed crashes in standalone emulators when bezels are enabled on A133 (TrimUI Brick, Smart Pro, etc.)
    - Fixed PPSSPP standalone `glCopyImage` segfault on A133/PowerVR GE8300 that resulted in emulation issues in the TrimUI Smart Pro and Brick
    - Workaround for Flycast/vl/xtreme core compatibility (Dreamcast, NAOMI, Atomiswave, NAOMI2) on A133 devices
    - Changed default Korean font
    - Replaced JP-only font with full CJK support using WenQuanYi Micro Hei
    - Set CJK fonts based on RetroArch user language or system locale
    - Fixed RetroArch OSD CJK font display issues
    - Fixed Advanced Drastic emulator config path issues

### CHANGED / IMPROVED ###
- OS features
    - Enhanced suspend/resume functionality and power management
    - Improved battery saver behavior
    - Enhanced brightness control and soft reset behavior
    - Updated Bluetooth service handling
    - Improved EmulationStation audio wait
    - Multi-resolution bezel sets now use consistent aspect-ratio naming patterns
    - Updated Art-Book-Next theme
    - Updated ES-Knulli theme
    - Filtering Knulli-compatible themes
    - Auto volume attenuation when using headphones on A133 devices
    - Added MPV support for M3U, MP3, FLAC
    - MPV now skips applying bezels/HUD overlays
    - Improved audio handling across devices
    - NetPlay hotspot detection via `has_ap_mode`
    - Auto-detection of Wi-Fi interface for ad-hoc NetPlay
    - Faster game launch
    - Unified USB mode control into single init script (ADB, MTP, off)
    - ConnMan startup delay and extended Wi-Fi timeouts
    - Removed debug output from init scripts
    - Pico-8 installer update to auto-remove previous installation before reinstall
- Emulation features
    - Adjusted rewind granularity for better performance

# Knulli - Gladiator - (20250505)

## ChangeLog

### ADDED ###
- Device support
    - support for RG34XX
- OS features
    - Introduced a new Knulli on-screen manual
    - Introduced Device Settings menu
        - RGB Settings: Moved to Device Settings
        - RGB Settings: Battery indication can now be configured
        - Power Management: Moved to Device Settings
        - Power Management: New options added
        - Power Management: Introduced new (optional) aggressive battery saver
            - Sets CPU governor to powersave when device is idle
            - Disables Wi-Fi while in-game unless retro-achievements are enabled
        - USB Settings: Toggle between ADB, the newly introduced MTP, and no USB access
        - Pico-8 Installer: Can now be launched from Device Settings
        - Pico-8 Installer: Removes previous Pico-8 installation automatically now
        - Added support for TrimUI switch input (can be configured in Device Settings to mute/unmute or turn RGB on/off or turn airplane mode on/off)
    - Introduced automatic assignment of controllers to players (in order of connecting the controllers)
    - Automatically switches between Bluetooth audio and built-in speaker output when devices connect/disconnect
    - Added date and time display to the EmulationStation screensaver
    - Added Korean input support to the EmulationStation on-screen popup keyboard
    - Adjusted refresh rate to 60 Hz on RG35XX SP, RG34XX, RG34XX SP, and RG CubeXX (thank you, [@TheGammaSqueeze](https://github.com/TheGammaSqueeze/))
    - Added single rainbow RGB mode to TrimUI Brick and Smart Pro
    - Added MPV video player
        - Disabled power saving while MPV is playing videos
    - Introduced new EmulationStation notifications, e.g. Wi-Fi connection failure, virtual joystick mode, etc.
    - Added support for USB audio. Just plug the USB DAC2 compatible device and go to *Settings* → *System Settings* → *Audio Output* and select your audio device.
    - Added support for ZRAM swap support. Toggle the option at *Settings* → *System Settings* → *Services* → *ZRAMSWAP* to enable it.
- Emulation features
    - Introduced Quick Resume mode to boot right back into your game
    - Introduced a toggle to the Ports system which purposely breaks cardinal mapping by swapping A/B and X/Y to match the Nintendo-style button labels with in-game prompts for Xbox controllers
    - Introduced tate mode to RG34XX
    - Netplay improvements
        - Added support for local hotspot (Adhoc) connectivity in EmulationStation Netplay
        - Added support for LAN game discovery in EmulationStation Netplay
        - EmulationStation setting for automatically creating a Netplay lobby on game start
        - EmulationStation setting to filter Netplay lobby results to relay server games only
    - Enabled global hotkey customization for RetroArch cores
    - Added [shimmerless shaders by Woohyun-Kang](https://github.com/Woohyun-Kang/Sharp-Shimmerless-Shader) for RetroArch cores

### FIXED ###

- Fixed RGB support for TrimUI Brick
- Fixed RGB brightness when booting when HDMI is already plugged
- Fixed sleep mode for TrimUI Brick/Smart Pro
- Fixed Dpad/Analog toggle (virtual joystick) for TrimUI Brick
- Fixed rumble confirmations on TrimUI Brick (still no rumble in-game)
- Adapted bezel positioning via configgen to new requirements of RetroArch 1.20.x
- Battery saving no longer interrupts MPV (the video player)
- Fixed issues with auto-pairing and re-connecting of Bluetooth controllers
- Fixed cursor movement bug in the popup keyboard
- Fixed EmulationStation rendering issue with the Korean character '가'
- Fixed bezels and charging screen for RG28XX
- Fixed issue with volume indicator overlay not showing on TrimUI devices

### CHANGED / IMPROVED
- OS features
    - Default file system is exFAT now (will only be applied when flashing)
    - Consolidated resizing/formatting scripts across various SOCs
    - RGB daemon must no longer be enabled as a service
    - Improved stability and consistency of Wi-Fi (e.g., by adding `connman` delay and increasing timeout limit)
    - Improved EmulationStation launch speed by limiting recursive depth of game to 1
    - Added per-system toggle to lift the recursive depth limit if required
    - MacOS system files (indicated by file name prefix `._`) are no longer considered as games and therefore hidden from EmulationStation
    - Renamed "Overclock" menu to "CPU Clock Rate" (because on most devices, this menu is for "underclocking")
    - Disabled IPv6 by default
- Emulation features
    - Updated RetroArch to 1.20.x
    - Updated ScummVM to 2.9.0
    - Replaced default Korean font: NanumMyeongjo → NanumSquare_acB
    - Replaced Drastic-Steward with Advanced Drastic

# Knulli - Firefly - (20241204)

## ChangeLog

### ADDED ###
- Device support
    - support for RG40XX-H, RG40XX-V, RG CubeXX
    - preliminary support for the TrimUI Brick
    - initial work for the Miyoo A30 (still WIP, not working)
- OS features
    - gammas fix for joystick cardinal snapping
    - battery saver mode. (under system settings -> power management)
    - HDMI output modes for 480p, 720p, and 1080p.
    - Bluetooth support for the TSP
    - lid shutdown service for RG35XX-SP to change lid closed behavior to shutdown
    - RGB LEDs support for RG40XX-H/V and RG CubeXX
        - RGB Settings GUI in Tools section
        - RGB LEDs indicating battery status (low, very low, charging)
        - RGB LEDs play rainbow animation when RetroAchievements are earned
        - Brightness of LEDs lowers/raises with screen brightness
    - new default background music for EmulationStation
    - stereo check audio file. call via "batocera-audio test"
    - Romanian translation (SilverGreen93)
    - squashfs support MSU-MD
- Emulation features
    - EmulationStation setting for RetroArch integer overscale
    - EmulationStation settings for Lexaloffle Pico-8
    - EmulationStation setting for Drastic image scaling: bilinear(smooth) and nearest-neighbor (sharp)
    - EmulationStation settings for RetroArch emulators to customize hotkeys
    - EmulationStation setting for RetroArch to change fast-forward hold/toggle
    - EmulationStation setting for DSP audio in Flycast/FlycastVL(default is off). Copied es settings from Flycast to FlycastVL.
    - Support for multi-resolution bezels
        - including new bezel set default-knulli with bezels for 4:3 (internal LCD) and 16:9 displays (HDMI)
    - Drastic-Steward emulator. (Note that hotkeys and inputs differ from Drastic!)

### FIXED ###
- directional inputs sometimes getting stuck in official pico8
- inconsistent IP address when booting/enabling Wi-Fi due to multiple wlans present. Now always enables first wlan found and disables any others.
- issue with Wi-Fi not connecting at boot (again). WPA3 still doesn't work
- issue with Wi-Fi not working with Wi-Fi dongles on affected devices
- bug in S29namebluetooth that resulted in duplicate lines
- reversed stereo audio channels for the RG40XX-H
- issue with audio switching before es reloads when switching between internal LCD and HDMI out
- updated/fixed some issues with handheld tate mode
- on RG35XX-SP if lid is closed and wakes up from suspend will auto-suspend
- maximum audio volume for the TSP
- allow users to add their own RetroAchievements Web API Key to access their RetroAchievement summary in EmulationStation (resolves Error 419)

### CHANGED / IMPROVED
- OS features
    - updated EmulationStation to the latest version, it's now maintained as separate fork
    - default EmulationStation screensaver is now slideshow
    - volume/brightness can be adjusted by holding down inputs
    - updated powermode/battery mode scripts
    - updated power-button script for suspend and shutdown with optimized event detection, eliminating the need for excessive loops and checks
    - brightness has a new floor which allows for very low brightness
    - disabled Wi-Fi background scanning for better battery life
    - added check so emulation station can't have more than one instance running
    - improvements to batocera-resolution
    - improvements to batocera-audio
    - updated SDL2 patches and version to 2.30
    - consolidated H700 overlay and patches for all H700 boards
    - updated all DTBs for all the H700 boards so now each board has a unique model identifier
    - updated DTBs to include unique controller identifiers for all boards
    - added board checks for many scripts
    - removed some unnecessary init and daemon scripts
- Emulation features
    - updated Lexaloffle Pico-8 configgen
    - Drastic inputs have changed to be more universal between all devices(single joystick etc)
    - emulators start with a negative niceness. May provide marginal performance improvements
    - default N64 emulator is now Parallel Libretro core.
    - glN64 now the default gfx plugin for Parallel Libretro core
    - updated Amiberry to 5.7.4
    - updated PPSSPP to 1.18.1
    - handheld tate mode now works with MAME 078 Plus
