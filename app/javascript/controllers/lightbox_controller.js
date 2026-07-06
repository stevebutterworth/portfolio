import { Controller } from "@hotwired/stimulus"

// Dark immersive gallery. Reads image paths, an optional video URL and the title
// from a <template data-lightbox-target="data"> child, builds an overlay on demand.
export default class extends Controller {
  static targets = ["data"]

  connect() {
    const div = this.dataTarget.content.firstElementChild.dataset
    this.images = JSON.parse(div.images).map((p) => `/media/${p}`)
    this.videos = JSON.parse(div.videos || "[]")
    this.title = div.title || ""
    this.index = 0
    this.onKey = this.onKey.bind(this)
  }

  disconnect() {
    // Turbo Drive keeps the document alive across visits; make sure an open
    // overlay never leaks its keydown listener or leaves body scroll locked.
    this.close()
  }

  open() {
    this.index = 0
    this.overlay = this.build()
    document.body.appendChild(this.overlay)
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this.onKey)
    this.trigger = document.activeElement
    this.overlay.querySelector(".lightbox-close").focus()
  }

  close() {
    if (!this.overlay) return
    this.overlay.remove()
    this.overlay = null
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.onKey)
    if (this.trigger) this.trigger.focus()
  }

  onKey(e) {
    if (e.key === "Escape") this.close()
    if (e.key === "ArrowRight") this.go(1)
    if (e.key === "ArrowLeft") this.go(-1)
    if (e.key === "Tab") this.trapFocus(e)
  }

  // Keep Tab and Shift+Tab cycling inside the overlay while it is open.
  trapFocus(e) {
    if (!this.overlay) return
    const focusables = this.overlay.querySelectorAll("button")
    if (focusables.length === 0) return
    const first = focusables[0]
    const last = focusables[focusables.length - 1]
    const active = document.activeElement
    if (!this.overlay.contains(active)) {
      e.preventDefault()
      first.focus()
    } else if (e.shiftKey && active === first) {
      e.preventDefault()
      last.focus()
    } else if (!e.shiftKey && active === last) {
      e.preventDefault()
      first.focus()
    }
  }

  go(delta) {
    const total = this.slides().length
    this.index = (this.index + delta + total) % total
    this.paint()
  }

  slides() {
    const s = this.images.map((src) => ({ type: "image", src }))
    this.videos.forEach((src) => s.push({ type: "video", src }))
    return s
  }

  paint() {
    const slide = this.slides()[this.index]
    const stage = this.overlay.querySelector(".lightbox-stage-media")
    if (slide.type === "video") {
      stage.innerHTML = this.directVideo(slide.src)
        ? `<video class="lightbox-video" src="${this.esc(slide.src)}" controls></video>`
        : `<iframe class="lightbox-video" src="${this.esc(this.embed(slide.src))}" allow="autoplay; fullscreen" allowfullscreen></iframe>`
    } else {
      stage.innerHTML = `<img class="lightbox-img" src="${this.esc(slide.src)}" alt="">`
    }
    this.overlay.querySelector(".lightbox-counter").textContent =
      `${String(this.index + 1).padStart(2, "0")} / ${String(this.slides().length).padStart(2, "0")}`
    this.overlay.querySelectorAll(".lightbox-thumb").forEach((t, i) =>
      t.classList.toggle("is-active", i === this.index)
    )
  }

  // True for direct video files that should play in a <video> tag, not an iframe.
  directVideo(url) {
    return /\.(mp4|webm|mov)$/i.test(url.split(/[?#]/)[0])
  }

  // Content is repo-controlled, but never trust interpolation into innerHTML.
  esc(value) {
    return String(value).replace(/[&<>"']/g, (c) => (
      { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]
    ))
  }

  embed(url) {
    const yt = url.match(/[?&]v=([^&]+)/) || url.match(/youtu\.be\/([^?]+)/)
    if (yt) return `https://www.youtube.com/embed/${yt[1]}`
    const vim = url.match(/vimeo\.com\/(\d+)/)
    if (vim) return `https://player.vimeo.com/video/${vim[1]}`
    return url
  }

  build() {
    const el = document.createElement("div")
    el.className = "lightbox-overlay"
    el.setAttribute("role", "dialog")
    el.setAttribute("aria-modal", "true")
    el.setAttribute("aria-label", this.title)
    el.innerHTML = `
      <div class="lightbox-top">
        <div class="lightbox-meta"><span class="lightbox-counter"></span> <span>${this.esc(this.title)}</span></div>
        <button class="lightbox-close" aria-label="Close">&#10005;</button>
      </div>
      <div class="lightbox-stage">
        <button class="lightbox-arrow lightbox-prev" aria-label="Previous">&#8249;</button>
        <div class="lightbox-stage-media"></div>
        <button class="lightbox-arrow lightbox-next" aria-label="Next">&#8250;</button>
      </div>
      <div class="lightbox-film">${this.slides()
        .map(
          (s, i) =>
            `<button class="lightbox-thumb" data-i="${i}">${
              s.type === "video" ? "<span class='lightbox-play'>&#9654;</span>" : ""
            }<img src="${this.esc(s.type === "image" ? s.src : this.images[0])}" alt=""></button>`
        )
        .join("")}</div>`
    el.querySelector(".lightbox-close").addEventListener("click", () => this.close())
    el.querySelector(".lightbox-prev").addEventListener("click", () => this.go(-1))
    el.querySelector(".lightbox-next").addEventListener("click", () => this.go(1))
    el.addEventListener("click", (e) => { if (e.target === el) this.close() })
    el.querySelectorAll(".lightbox-thumb").forEach((t) =>
      t.addEventListener("click", () => { this.index = Number(t.dataset.i); this.paint() })
    )
    this.overlay = el
    this.paint()
    return el
  }
}
