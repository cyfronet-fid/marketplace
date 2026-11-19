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

// Calls onFailure when matomo.js does not run as the tracker: the request
// fails (an ad blocker, Matomo down), or the file loads but leaves
// window._paq an array, which matomo.js replaces with its tracker as it runs.
function loadTracker(url, onFailure) {
  const script = document.createElement("script");
  script.async = true;
  script.src = `${url}matomo.js`;
  script.addEventListener("load", () => {
    if (Array.isArray(window._paq)) {
      onFailure();
    }
  });
  script.addEventListener("error", onFailure);
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

const url = meta("matomo-url");
const siteId = meta("matomo-site-id");

if (url && siteId) {
  window._paq = window._paq || [];
  track(["disableCookies"]);
  track(["setTrackerUrl", `${url}matomo.php`]);
  track(["setSiteId", siteId]);
  // client_uid, the visitor's recommender ID that links from the search
  // portal carry (ServicesController#override_user_action_info), stays out of
  // the url and urlref Matomo sends; the other parameters are kept.
  track(["setExcludedQueryParams", ["client_uid"]]);
  // Outlinks. enableLinkTracking listens on document.body, once, and Turbo
  // replaces the body on every visit; a listener on document, which Turbo
  // keeps, sees the link clicks of every body.
  track(["addListener", document]);

  // Without the tracker nothing sends the queue, so a failed load drops it
  // and later visits queue nothing until the next full page load. No retry:
  // it can't get past an ad blocker, and hits replayed after an outage would
  // be recorded at the time they're sent, not at the time of the visit.
  let trackerFailed = false;
  loadTracker(url, () => {
    trackerFailed = true;
    window._paq = [];
  });

  // The first page view keeps Matomo's default referrer, document.referrer.
  let previousUrl = null;

  document.addEventListener("turbo:load", () => {
    if (trackerFailed) {
      return;
    }
    if (previousUrl) {
      track(["setReferrerUrl", previousUrl]);
    }
    track(["setCustomUrl", window.location.href]);
    track(["setDocumentTitle", document.title]);
    track(["trackPageView"]);
    document.querySelectorAll("[data-matomo-event]").forEach((element) => track(eventFrom(element)));
    previousUrl = window.location.href;
  });
}
