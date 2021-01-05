// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

function handleError(error) {
  if (error) {
    alert(error.message);
  } else {
    console.log("success");
  }
}

let Hooks = {};

var session;
var publisher;

Hooks.PublisherInit = {
  mounted() {
    this.pushEvent("get_publish_info", {}, (reply, ref) => {
      session = OT.initSession(reply.key, reply.session_id);
      publisher = OT.initPublisher('publisher-div', {}, handleError);
      session.connect(reply.token, (error) => {
        if (error) {
          handleError(error);
        } else {
          session.publish(publisher, (error) => {
            if (error) {
              console.log(error);
            } else {
              setTimeout(() => {
                this.pushEvent("store_stream_id", {stream_id: publisher.streamId}, (reply, ref) => {});
              });
            }
          });
        }
      });
      session.on("streamCreated", (event) => {
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
    setTimeout(() => {subscribeWhenReady(session, stream, id)}, 500);
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: Hooks, params: {_csrf_token: csrfToken}})

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
