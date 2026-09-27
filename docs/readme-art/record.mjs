// Renders anim.html frame by frame (deterministic, no real-time capture).
import { mkdirSync } from 'node:fs'
const lib = (process.env.KIKI_README ?? process.env.HOME + '/.claude/skills/kiki-gh-readme/scripts') + '/lib.mjs'
const { launch } = await import(lib)
const dir = process.argv[2], fps = 12
mkdirSync(dir, { recursive: true })
const browser = await launch(['--allow-file-access-from-files'])
const page = await browser.newPage()
await page.setViewport({ width: 880, height: 600, deviceScaleFactor: 1 })
await page.goto('file://' + process.cwd() + '/anim.html', { waitUntil: 'networkidle0' })
const n = Math.round((await page.evaluate(() => window.DURATION)) * fps)
for (let i = 0; i < n; i++) {
  await page.evaluate(t => window.renderAt(t), i / fps)
  await page.screenshot({ path: `${dir}/f${String(i).padStart(4, '0')}.png` })
}
await browser.close()
