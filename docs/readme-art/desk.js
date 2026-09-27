// Draws a stylised Mac desktop from frames computed by the real LayoutMode code (frames.js).
const APPS = {
  Browser:  { color: '#3b82f6', icon: '🌐' },
  Editor:   { color: '#8b5cf6', icon: '⌨️' },
  Terminal: { color: '#10b981', icon: '▶' },
  Notes:    { color: '#f59e0b', icon: '📝' },
  Music:    { color: '#ec4899', icon: '♪' },
}
const Z = ['Music', 'Notes', 'Terminal', 'Editor', 'Browser'] // back → front

function desk(el, width, { dimUnmoved = null } = {}) {
  const { w: sw, h: sh } = FRAMES.screen
  const scale = width / sw
  const menu = Math.max(6, 25 * scale), dock = Math.max(6, 75 * scale)
  el.classList.add('desk')
  el.style.width = width + 'px'
  el.style.height = (sh + 25 + 75) * scale + 'px'
  el.innerHTML = `<div class="menubar" style="height:${menu}px"></div><div class="area" style="top:${menu}px;height:${sh * scale}px"></div>
    <div class="dock" style="height:${dock * .62}px;bottom:${dock * .19}px"></div>`
  const area = el.querySelector('.area')
  const wins = {}
  for (const name of Z) {
    const w = document.createElement('div')
    w.className = 'win'
    w.style.setProperty('--c', APPS[name].color)
    const bar = Math.max(7, 26 * scale)
    w.innerHTML = `<div class="tb" style="height:${bar}px;font-size:${Math.max(6, 12 * scale)}px"><i></i><i></i><i></i><span>${APPS[name].icon} ${name}</span></div>
      <div class="body"><b></b><b></b><b></b><b></b></div>`
    area.appendChild(w)
    wins[name] = w
  }
  const api = {
    set(frames, t = 1, from = null) {
      for (const f of frames) {
        const w = wins[f.app]
        const a = from ? from.find(x => x.app === f.app) : f
        const lerp = (k) => (a[k] ?? f[k]) + ((f[k] ?? a[k]) - (a[k] ?? f[k])) * t
        const hid = f.hidden ? t : (a.hidden ? 1 - t : 0)
        const src = f.hidden ? a : f
        const pick = (k) => f.hidden || a.hidden ? src[k] : lerp(k)
        w.style.left = pick('x') * scale + 'px'
        w.style.top = pick('y') * scale + 'px'
        w.style.width = pick('w') * scale + 'px'
        w.style.height = pick('h') * scale + 'px'
        w.style.opacity = 1 - hid
        w.style.transform = `scale(${1 - hid * .15})`
        w.style.filter = dimUnmoved && dimUnmoved.includes(f.app) ? 'saturate(.3) brightness(.75)' : ''
      }
    },
  }
  return api
}
