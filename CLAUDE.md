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
| ✅ v1 บิ้วแล้ว (27 ก.ย. 2026) | Grid · Focus · Split · Main + Stack · Cascade · Clean Desk · Undo · Named Layouts |
| 💡 ภายหลัง | Multi-display (ส่งข้ามจอ) · Exclude list · Snap by hotkey |

| Hotkey | ทำอะไร |
|--------|--------|
| ⌃⌥G | Grid — ตารางทุกหน้าต่างบนจอที่เมาส์อยู่ |
| ⌃⌥F | Focus — หน้าต่างหน้าสุดกลางจอ 80% + ซ่อนแอปอื่น |
| ⌃⌥S | Split — 2 หน้าต่างหน้าสุด 50/50 |
| ⌃⌥M | Main + Stack — หน้าสุดซ้าย 60% ที่เหลือซ้อนขวา |
| ⌃⌥C | Cascade — เรียงเฉียงเหมือนไพ่ |
| ⌃⌥D | Clean Desk — ซ่อนทุกแอป (กดซ้ำ = คืน) |
| ⌃⌥Z | Undo — ย้อนการจัดล่าสุด (เก็บย้อนได้ 20 ครั้ง) |

Named Layouts อยู่ในเมนู Layouts: บันทึกตำแหน่งทุกหน้าต่างทุกจอ → กดชื่อเพื่อคืนค่า (เปิดแอปที่ปิดอยู่ให้ด้วย) เก็บใน `UserDefaults` key `namedLayouts`
โหมดจัดเรียงทำงานกับ **จอที่เมาส์อยู่** เท่านั้น · ช่องไฟ (Gap) ปรับได้ในเมนู · มี Launch at Login

## Tech Stack

| Layer | Technology | ทำไม |
|-------|-----------|------|
| ภาษา | Swift 6 (language mode 5) | native, เรียก API ของ macOS ตรง ๆ |
| UI | SwiftUI `MenuBarExtra` (menu style) | เมนูบนแถบด้านบนจอ ไม่ต้องมีหน้าต่างหลัก |
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
│   ├── App/        # @main + AppDelegate (ลงทะเบียน hotkey ตอนเปิดแอป)
│   ├── Core/       # Accessibility (AX helpers) · ScreenGeometry (แปลงพิกัด) · WindowCollector (หาหน้าต่าง)
│   │               # WindowMover (ย้ายจริง) · Arranger (สั่งงาน + Undo + Clean Desk) · LayoutStore (Named Layouts)
│   ├── Modes/      # LayoutMode protocol + Layout helpers + 1 ไฟล์ต่อ 1 โหมด
│   ├── Hotkeys/    # Shortcuts table + HotkeyCenter (Carbon)
│   └── UI/         # MenuContent · NamePrompt (กล่องตั้งชื่อ layout)
├── Checks/main.swift             # เช็คสูตรคำนวณ layout ทุกโหมด (รันผ่าน scripts/check.sh)
├── Resources/Info.plist          # LSUIElement=YES (ซ่อนจาก Dock), bundle id, usage strings
├── scripts/
│   ├── build-app.sh              # swift build → ห่อเป็น build/Desktop Cleaner.app → codesign
│   ├── run.sh                    # build แล้วเปิดจาก build/ (ไว้ลองระหว่าง dev)
│   ├── install.sh                # build แล้วติดตั้งที่ ~/Applications (ตัวใช้งานจริง)
│   └── check.sh                  # รัน Checks/ — ต้องผ่านก่อน commit ทุกครั้งที่แตะ Modes/
├── docs/MODES.md                 # ข้อเสนอโหมด + ลำดับการบิ้ว
├── docs/images/                  # ภาพใน README (hero, modes, demo.gif, social-preview)
├── docs/readme-art/              # ตัวสร้างภาพ README — build.sh
├── README.md · LICENSE (MIT)
└── build/                        # output (.gitignore)
```

## หลักออกแบบโค้ด

1. **แยก "คำนวณ" ออกจาก "ย้ายจริง"** — แต่ละโหมดเป็น pure function:
   `arrange(windows: [WindowInfo], in screen: CGRect, gap: CGFloat) -> [WindowID: CGRect]`
   (`windows` เรียงจากหน้าสุด → หลังสุด) ไม่แตะ AX API เลย → เช็คได้โดยไม่ต้องเปิดแอปจริง · `Arranger` เป็นคนเดียวที่สั่งย้ายหน้าต่าง
2. **เพิ่มโหมดใหม่ = เพิ่มไฟล์เดียวใน `Modes/`** แล้วลงทะเบียนใน `LayoutModes.all` (+ hotkey ใน `Shortcuts.all` ถ้าต้องการ) และเพิ่มเช็คใน `Checks/main.swift`
3. **จด snapshot ก่อนจัดทุกครั้ง** → Undo ได้เสมอ (`Arranger.apply` ทำให้อัตโนมัติ — อย่าเรียก `WindowMover` ตรงจากที่อื่น)
4. **พิกัด** — AX ใช้จุดกำเนิดมุมซ้ายบนของจอหลัก แต่ `NSScreen` ใช้มุมซ้ายล่าง แปลงผ่าน `ScreenGeometry.toAX` ที่เดียว อย่าแปลงกระจายหลายที่
   ทุก frame ใน `WindowInfo` / `SavedWindow` / โหมด เป็นพิกัด AX
5. ข้ามหน้าต่างที่ไม่ควรแตะ: minimized, fullscreen, ไม่ใช่ `AXStandardWindow` (panel/popup), เล็กกว่า 100×60, อยู่ Space อื่น
6. หา window ID ด้วย private API `_AXUIElementGetWindow` — ใช้ได้เพราะไม่ขึ้น App Store

## Build & Run

```bash
./scripts/install.sh        # build + ติดตั้ง ~/Applications + เปิด (ตัวที่ Tle ใช้จริง)
./scripts/run.sh            # build + เปิดจาก build/ (ลองระหว่าง dev — จะ kill ตัวที่ติดตั้งไว้)
./scripts/check.sh          # เช็คสูตร layout ทุกโหมด
swift build                 # เช็คว่า compile ผ่าน (เร็วสุด)
```

### ⚠️ กับดักเรื่องสิทธิ์ Accessibility

macOS จำสิทธิ์ Accessibility ผูกกับ **ลายเซ็น (code signature)** ของแอป
- ถ้าเซ็นแบบ ad-hoc (`codesign -s -`) ลายเซ็นเปลี่ยนทุกครั้งที่ build → **ต้องไปติ๊กสิทธิ์ใหม่ทุกรอบ** น่ารำคาญมาก
- ทางแก้ (**ทำแล้ว 27 ก.ย. 2026**): self-signed certificate ชื่อ **`Desktop Cleaner Dev`** อยู่ใน login keychain (อายุ 10 ปี)
  `build-app.sh` ใช้ใบนี้อัตโนมัติ ไม่เจอจะ fallback เป็น ad-hoc · ขึ้น `CSSMERR_TP_NOT_TRUSTED` ใน `find-identity` เป็นเรื่องปกติ codesign ยังใช้ได้
  ถ้าย้ายเครื่อง ต้องสร้างใบใหม่ด้วย openssl (x509 + `extendedKeyUsage = codeSigning`) แล้ว `security import … -T /usr/bin/codesign`
- ถ้าติ๊กสิทธิ์แล้วยังไม่ทำงาน: ลบแอปออกจากรายการใน System Settings แล้วเพิ่มใหม่ หรือ `tccutil reset Accessibility com.madebytle.desktopcleaner`

## README

ภาพใน README เป็น **แผนภาพที่วาดจากตำแหน่งที่โค้ดโหมดจริงคำนวณ** ไม่ใช่ screenshot (Tle เลือก 27 ก.ย. 2026)
`docs/readme-art/dump/main.swift` เรียก `LayoutModes.all` กับเดสก์ท็อปตัวอย่าง 5 หน้าต่าง → HTML วาด → PNG/GIF
**แก้โหมด / เพิ่มโหมด / เปลี่ยนคีย์ลัด → รัน `./docs/readme-art/build.sh` แล้วแก้ตารางใน README ให้ตรง**
(ต้องมี Node, ffmpeg และสกิล kiki-gh-readme) · ถ้าเพิ่มโหมดใหม่ ต้องเพิ่มการ์ดใน `modes.html` และ step ใน `anim.html` เอง

## Git

- Remote: `github.com/tlejay/desktop-maid` (**public** ตั้งแต่ 27 ก.ย. 2026 — ห้าม commit ข้อมูลส่วนตัว/path เครื่อง) · branch `main`
- `swift test` **ใช้ไม่ได้** บนเครื่องที่มีแค่ Command Line Tools (หา test runner ไม่เจอ แม้ compile ผ่าน) — เลยใช้ `Checks/` + `scripts/check.sh` แทน

## Conventions

- สื่อสารกับ Tle เป็นภาษาไทย · โค้ดและ comments เป็นภาษาอังกฤษ
- Bundle ID: `com.madebytle.desktopcleaner`
- ไม่ใช้ dependency ภายนอกถ้าไม่จำเป็น (อยากให้ build ได้แค่มี Command Line Tools)
- ทดสอบของจริง: เปิดแอปหลาย ๆ ตัว (Finder, Safari, Notes, Terminal) แล้วกดแต่ละโหมดดู + กด Undo
