// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"
import "phoenix_html"
import { Socket } from "phoenix"
import NProgress from "nprogress"
import { LiveSocket } from "phoenix_live_view"

// Open tok
const OT = require('@opentok/client');

function handleError(error) {
  if (error) {
    alert(error.message);
  } else {
    console.log("success");
  }
}

let Hooks = {};

// ========= HIGHLIGHT CURRENT PAGE IN NAVBAR HOOK ==========

/*
The root layout containing the navbar is not a part of live view and is not rerendered on live_redirect.
This hook is triggered whenever the top level container is remounted and it highlights the current
active navbar link
*/

// ======== INIFINITE SCROLL HOOK =========

let scrollAt = () => {
  // How far from top user has scrolled
  let scrollTop = document.documentElement.scrollTop || document.body.scrollTop

  // Total height of page including parts that are hidden due to overeflow
  let scrollHeight = document.documentElement.scrollHeight || document.body.scrollHeight

  // Height of visible portion of page
  let clientHeight = document.documentElement.clientHeight

  // How much percentage of the page the user has scrolled
  return scrollTop / (scrollHeight - clientHeight) * 100
}

Hooks.InfiniteScroll = {
  // Get current page
  page() { return this.el.dataset.page },
  mounted() {
    // save current page in pending, used to track if infinite scroll has already triggered or not
    this.pending = this.page()

    // When user scrolls beyond 90% of the page
    window.addEventListener("scroll", e => {
      console.log("add event listner");
      // check if the page hasnt been updated (infinite scroll still not triggered)
      if (this.pending == this.page() && scrollAt() > 90) {

        // Update page = page + 1 as we will be fetching more pages
        this.pending = this.page() + 1

        // Push an event to feth more pages
        this.pushEvent("load-more", {})
      }
    })
  },

  // On reconnection or updates make sure pending is set correctly to current page
  reconnected() { this.pending = this.page() },
  updated() { this.pending = this.page() }
}

// ======== HOOK TO OBTAIN PUBLISHER INFO AND SHARE STREAM ID TO ENABLE VIDEO SHARING VIA TOKBOX =========

var session;
var publisher;

Hooks.PublisherInit = {
  mounted() {

    // Push an event to get session, api key and token to stream to tokbox
    this.pushEvent("get_publish_info", {}, (reply, ref) => {

      // Initilize tokbox session
      session = OT.initSession(reply.key, reply.session_id);

      // Intialize self as publisher and register a div where published video will be seen
      publisher = OT.initPublisher('publisher-div', {}, handleError);

      // Connect to tokbox session using token
      session.connect(reply.token, (error) => {
        if (error) {
          handleError(error);
        } else {
          // Publish to tokbox session
          session.publish(publisher, (error) => {
            if (error) {
              console.log(error);
            } else {

              // On successfully publishing to tokbox we get a steam id
              // Share this stream id with the subscribers so that they can subscribe to published video in the session
              setTimeout(() => {
                // The live view stores this stream id in the subscribers view, so that they can subscribe to this stream
                this.pushEvent("store_stream_id", { stream_id: publisher.streamId }, (reply, ref) => { });
              });
            }
          });
        }
      });

      // Event listerner triggered whenever new steam is created in session
      session.on("streamCreated", (event) => {

        // Use the stream id stored by live view in the html page to subscribe and watch the publishers stream
        subscribeWhenReady(session, event.stream, event.stream.id);
      });
    });
  }
}

function subscribeWhenReady(session, stream, id) {
  const target = document.getElementById('subscriber-div-' + id);
  if (target) {
    session.subscribe(stream, 'subscriber-div-' + id);
  } else {
    setTimeout(() => { subscribeWhenReady(session, stream, id) }, 500);
  }
}

// =========== SCROLL TO LATEST CHAT MESSAGE ON NEW MESSAGE ============

Hooks.OnNewChatMsg = {
  updated () {
    let chats = document.getElementsByClassName("bubble");
    chats[chats.length - 1] && chats[chats.length - 1].scrollIntoView({ behavior: "smooth" });
  }
}

Hooks.OnRedirect = {
  mounted() {
    document.querySelectorAll('.nav-item a').forEach(elem => {
      if (document.URL.endsWith(elem.pathname)) {
        elem.parentElement.classList.add('active-nav');
      }
      else {
        elem.parentElement.classList.remove("active-nav");
      }
    });
  }
}

//==============================================================================

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, params: { _csrf_token: csrfToken } })

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
