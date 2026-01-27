// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Copy to clipboard hook
let Hooks = {}
Hooks.CopyToClipboard = {
  mounted() {
    this.el.addEventListener("click", e => {
      const text = this.el.getAttribute("phx-value-text")
      if (text) {
        navigator.clipboard.writeText(text).then(() => {
          // Show a brief visual feedback
          const originalText = this.el.getAttribute("title")
          this.el.setAttribute("title", "Copied!")
          setTimeout(() => {
            this.el.setAttribute("title", originalText || "Copy to clipboard")
          }, 2000)
        }).catch(err => {
          console.error("Failed to copy text: ", err)
        })
      }
    })
  }
}

// Scroll to top hook
Hooks.ScrollToTop = {
  mounted() {
    window.scrollTo({ top: 0, behavior: 'smooth' })
  },
  updated() {
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}

let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Scroll to top on step changes
window.addEventListener("phx:scroll-to-top", _info => {
  window.scrollTo({ top: 0, behavior: 'smooth' })
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

