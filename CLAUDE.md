# CLAUDE.md — 129 Desktop Cleaner

## โปรเจคนี้คืออะไร

Mac App เล็ก ๆ อยู่บน **Menu Bar** (ไม่มีไอคอนใน Dock) กดทีเดียวแล้วจัดหน้าต่างทุกแอปบนจอให้เป็นระเบียบ
ตาม **โหมด** ที่เลือก (Grid, Focus, Split ฯลฯ) — ดูข้อเสนอโหมดทั้งหมดใน [`docs/MODES.md`](docs/MODES.md)

**บิ้วสดใช้เอง ไม่ขึ้น Mac App Store** — ผลคือ:
- ไม่ต้องใช้ App Sandbox → เรียก Accessibility API ย้ายหน้าต่างแอปอื่นได้เต็มที่
- ไม่ต้องมี Apple Developer account / notarize
- ต้องขอสิทธิ์ **Accessibility** จากผู้ใช้ 1 ครั้ง (System Settings → Privacy & Security → Accessibility)

## โหมด

| สถานะ | โหมด |
|-------|------|
| ✅ v1 (Tle เลือก 27 ก.ย. 2026) | Grid + Undo · Focus · Clean Desk · Split · Main + Stack · Cascade · Named Layouts |
| 💡 ภายหลัง | Snapshot & Restore (มากับ Undo) · Multi-display · Exclude list · Snap by hotkey |

ลำดับบิ้ว: Grid + Undo → Focus / Split / Main + Stack → Clean Desk / Cascade → Named Layouts

## Tech Stack

| Layer | Technology | ทำไม |
|-------|-----------|------|
| ภาษา | Swift 6 (language mode 5) | native, เรียก API ของ macOS ตรง ๆ |
| UI | SwiftUI `MenuBarExtra` + `Settings` | เมนูบนแถบด้านบนจอ ไม่ต้องมีหน้าต่างหลัก |
| จัดหน้าต่าง | Accessibility API (`AXUIElement`) | วิธีเดียวที่ย้าย/ย่อหน้าต่างของแอปอื่นได้ |
| หาหน้าต่าง | `CGWindowListCopyWindowInfo` + `NSWorkspace` | รู้ว่าแอปไหนเปิดอยู่ หน้าต่างอยู่จอไหน |
| Hotkey | Carbon `RegisterEventHotKey` | global shortcut ไม่ต้องใช้ lib ภายนอก |
| Build | **Swift Package Manager** + `scripts/build-app.sh` | เครื่องนี้มีแค่ Command Line Tools **ไม่มี Xcode** — ห้ามสร้าง `.xcodeproj` |
| ขั้นต่ำ | macOS 14 Sonoma | |

## โครงสร้างโฟลเดอร์

```
129 Desktop Cleaner/
├── Package.swift                 # SwiftPM manifest (executable target)
├── Sources/DesktopCleaner/
│   ├── App/        # entry point (@main), MenuBarExtra, AppState
│   ├── Core/       # Accessibility permission, WindowInfo, WindowMover (AX read/write)
│   ├── Modes/      # LayoutMode protocol + 1 ไฟล์ต่อ 1 โหมด (GridMode.swift, FocusMode.swift …)
│   ├── Hotkeys/    # global hotkey registration
│   └── UI/         # SwiftUI views: menu content, settings
├── Resources/Info.plist          # LSUIElement=YES (ซ่อนจาก Dock), bundle id, usage strings
├── scripts/
│   ├── build-app.sh              # swift build → ห่อเป็น build/Desktop Cleaner.app → codesign
│   └── run.sh                    # build แล้วเปิดแอป (kill ตัวเก่าก่อน)
├── docs/MODES.md                 # ข้อเสนอโหมด + ลำดับการบิ้ว
└── build/                        # output (.gitignore)
```

## หลักออกแบบโค้ด

1. **แยก "คำนวณ" ออกจาก "ย้ายจริง"** — แต่ละโหมดเป็น pure function:
   `arrange(windows: [WindowInfo], in screen: CGRect) -> [WindowID: CGRect]`
   ไม่แตะ AX API เลย → ทดสอบได้โดยไม่ต้องเปิดแอปจริง · `WindowMover` ใน `Core/` เป็นคนเดียวที่ย้ายหน้าต่าง
2. **เพิ่มโหมดใหม่ = เพิ่มไฟล์เดียวใน `Modes/`** แล้วลงทะเบียนใน `LayoutModes.all`
3. **จด snapshot ก่อนจัดทุกครั้ง** → Undo ได้เสมอ
4. **พิกัด** — AX ใช้จุดกำเนิดมุมซ้ายบนของจอหลัก แต่ `NSScreen` ใช้มุมซ้ายล่าง ต้องแปลงผ่านฟังก์ชันกลางที่เดียว อย่าแปลงกระจายหลายที่
5. ข้ามหน้าต่างที่ไม่ควรแตะ: minimized, fullscreen, หน้าต่างเล็ก ๆ ลอย (panel/popup), แอปใน exclude list

## Build & Run

```bash
./scripts/run.sh            # build + เปิดแอป (ใช้บ่อยสุด)
./scripts/build-app.sh      # build อย่างเดียว → build/Desktop Cleaner.app
swift build                 # เช็คว่า compile ผ่าน (เร็วสุด)
```

### ⚠️ กับดักเรื่องสิทธิ์ Accessibility

macOS จำสิทธิ์ Accessibility ผูกกับ **ลายเซ็น (code signature)** ของแอป
- ถ้าเซ็นแบบ ad-hoc (`codesign -s -`) ลายเซ็นเปลี่ยนทุกครั้งที่ build → **ต้องไปติ๊กสิทธิ์ใหม่ทุกรอบ** น่ารำคาญมาก
- ทางแก้: สร้าง self-signed certificate ชื่อ **`Desktop Cleaner Dev`** ใน Keychain ครั้งเดียว (Keychain Access → Certificate Assistant → Create a Certificate → Type: Code Signing)
  `build-app.sh` จะใช้ใบนี้อัตโนมัติถ้าเจอ ไม่เจอจะ fallback เป็น ad-hoc
- ถ้าติ๊กสิทธิ์แล้วยังไม่ทำงาน: ลบแอปออกจากรายการใน System Settings แล้วเพิ่มใหม่ หรือ `tccutil reset Accessibility com.madebytle.desktopcleaner`

## Git

- Remote: `github.com/tlejay/desktop-maid` (private) · branch `main`

## Conventions

- สื่อสารกับ Tle เป็นภาษาไทย · โค้ดและ comments เป็นภาษาอังกฤษ
- Bundle ID: `com.madebytle.desktopcleaner`
- ไม่ใช้ dependency ภายนอกถ้าไม่จำเป็น (อยากให้ build ได้แค่มี Command Line Tools)
- ทดสอบของจริง: เปิดแอปหลาย ๆ ตัว (Finder, Safari, Notes, Terminal) แล้วกดแต่ละโหมดดู — layout math ควรมี unit test เมื่อเริ่มมีหลายโหมด
