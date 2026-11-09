// Matomo browser tracking (ADR-0008). Active only when the page has the
// matomo-* meta tags (MatomoHelper#matomo_tags, layouts/_head), that is when
// MP_MATOMO_ENABLED is true. Always cookieless: disableCookies is queued
// before any hit.
//
// Every turbo:load, the first one included, is one page view with the URL,
// title and referrer of that Turbo navigation, followed by one trackEvent per
// event element on the page (MatomoHelper#matomo_event_tag). turbo:load does
// not fire for Turbo cache previews or same-page anchors, so a page is never
// counted twice.

function meta(name) {
  return document.querySelector(`meta[name="${name}"]`)?.content;
}

// The official queue. Once matomo.js has loaded it replaces window._paq with
// its own object, so commands always go through window._paq, never through
// a saved reference.
function track(command) {
  window._paq.push(command);
}

function loadTracker(url) {
  const script = document.createElement("script");
  script.async = true;
  script.src = `${url}matomo.js`;
  document.head.appendChild(script);
}

function eventFrom(element) {
  const { matomoCategory, matomoAction, matomoName, matomoValue } = element.dataset;
  const event = ["trackEvent", matomoCategory, matomoAction, matomoName];
  if (matomoValue !== undefined && matomoValue !== "") {
    event.push(Number(matomoValue));
  }
  return event;
}

// Matomo records outlinks with one click listener on document.body and
// enables it only once, but Turbo replaces the body on every visit. Matomo
// runs a queued function with the tracker as `this` when it executes the
// command, so the body is compared then: each body gets exactly one
// listener, also when visits happen before matomo.js has loaded.
let linkTrackedBody = null;
function trackLinksOfCurrentBody() {
  if (document.body === linkTrackedBody) {
    return;
  }
  linkTrackedBody = document.body;
  this.disableLinkTracking();
  this.enableLinkTracking();
}

const url = meta("matomo-url");
const siteId = meta("matomo-site-id");

if (url && siteId) {
  window._paq = window._paq || [];
  track(["disableCookies"]);
  track(["setTrackerUrl", `${url}matomo.php`]);
  track(["setSiteId", siteId]);
  loadTracker(url);

  // The first page view keeps Matomo's default referrer, document.referrer.
  let previousUrl = null;

  document.addEventListener("turbo:load", () => {
    if (previousUrl) {
      track(["setReferrerUrl", previousUrl]);
    }
    track(["setCustomUrl", window.location.href]);
    track(["setDocumentTitle", document.title]);
    track(["trackPageView"]);
    document.querySelectorAll("[data-matomo-event]").forEach((element) => track(eventFrom(element)));
    track([trackLinksOfCurrentBody]);
    previousUrl = window.location.href;
  });
}
