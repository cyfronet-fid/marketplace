import Rails from "@rails/ujs";
import Cookies from "js-cookie";
import { v1 as uuidv1 } from "uuid";

const ROOT_KNOWN_LABELS = ["recommendation-panel"];

const WINDOW_EVENTS_HANDLERS = {
  beforeunload: async () => {
    if (history.length !== 1) {
      setCookies();
    }
    window.probesInitialized = false;
    window.sourceIdOverride = null;
  },
  popstate: async (event) => popstate(event),
};

async function popstate(event) {
  window.popstateHandler = true;

  const target = get_target_by(null, null, location.pathname);

  await call_user_action_controller({
    timestamp: new Date().toISOString(),
    source: get_source_by(),
    target: target,
    user_action: get_action_by(),
  });
  window.recommendationSourceId = target.visit_id;
  window.recommendationLastPageId = target.page_id;
  sessionStorage.setItem("sourceId", target.visit_id);
  sessionStorage.setItem("lastPageId", target.page_id);
  await _initProbes(true, true);
}

async function _initProbes(force, skipInitial) {
  if (!force && window.probesInitialized) {
    return;
  }

  window.probesInitialized = true;

  setCookies();
  if (window.recommendationPrevious && !skipInitial && !window.sourceIdOverride) {
    await handleInitialNavigationEvent();
  }
  // Handle all internal open in new tab/window that was not handled by click event
  else if (window.recommendationSourceId != null && !skipInitial && !window.sourceIdOverride) {
    await handle_any_event();
  }

  handle_browser_events();

  // Handle DOM events
  const elements = [
    ...Array.from(window.document.querySelectorAll("[data-probe]")),

    // IMPORTANT!!! class should be added to DOM elements only when there are any other options!!!
    ...Array.from(window.document.querySelectorAll(".data-probe")),
  ];
  const elementsSize = elements.length;
  for (let i = 0; i < elementsSize; i++) {
    elements[i].addEventListener("mousedown", updateCookiesEventHandler);
    elements[i].addEventListener("mouseup", updateCookiesEventHandler);
    elements[i].addEventListener("contextmenu", updateCookiesEventHandler);
  }
}

export default async function initProbes() {
  if (document.hasFocus()) {
    await _initProbes();
  } else {
    setTimeout(() => _initProbes(), 5000);
    window.addEventListener("focus", () => _initProbes());
  }
}

let currentMouseTarget = null;

function updateCookiesEventHandler(event) {
  currentMouseTarget = event.target;
  setCookies(undefined, undefined, event.target);
}

function setCookies(targetId, source, element) {
  if (targetId == null) {
    targetId = uuidv1();
  }

  if (source == null) {
    source = get_source_by(element, true);
    source.visit_id = window.sourceIdOverride ?? window.recommendationSourceId;
  }

  const expires = new Date(new Date().getTime() + 5000);

  Cookies.set("source", JSON.stringify(source), { expires });
  Cookies.set("targetId", targetId, { expires });
  Cookies.set("lastPageId", window.location.pathname, { expires });
}

function handle_browser_events() {
  const events = Object.keys(WINDOW_EVENTS_HANDLERS);
  const windowEventsSize = events.length;
  remove_browser_events_listeners(window);

  for (let i = 0; i < windowEventsSize; i++) {
    window.addEventListener(events[i], WINDOW_EVENTS_HANDLERS[events[i]]);
  }
}

function remove_browser_events_listeners() {
  const events = Object.keys(WINDOW_EVENTS_HANDLERS);
  const windowEventsSize = events.length;
  for (let i = 0; i < windowEventsSize; i++) {
    window.removeEventListener(events[i], WINDOW_EVENTS_HANDLERS[events[i]]);
  }
}

async function handle_any_event(element = null) {
  const target = get_target_by(element);
  const source = get_source_by(element);
  const body = {
    timestamp: new Date().toISOString(),
    source: source,
    target: target,
    user_action: get_action_by(element),
  };

  setCookies(target.visit_id, source);

  await call_user_action_controller(body);

  remove_browser_events_listeners();
}

async function handleInitialNavigationEvent() {
  await call_user_action_controller({
    timestamp: new Date().toISOString(),
    source: window.recommendationPrevious,
    target: get_target_by(null, window.recommendationSourceId),
    user_action: get_action_by(),
  });
}

const call_user_action_controller = (body) => {
  if (body.source.visit_id == null) {
    return;
  }

  return fetch("/user_action", {
    method: "POST",
    headers: {
      "X-CSRF-Token": Rails.csrfToken(),
      "Content-type": "application/json",
    },
    body: JSON.stringify(body),
  })
    .then()
    .catch((error) => console.log(error));
};

function get_action_by(element) {
  const is_ordered = !!(
    window.location.pathname.includes("summary") &&
    element &&
    element.getAttribute("type") === "submit"
  );

  return {
    type: !!element ? element.tagName : "browser action",
    text: get_element_text(element),
    order: is_ordered,
  };
}

function get_element_text(element) {
  if (!element || !element.tagName) {
    return "";
  }

  switch (element.tagName.toLowerCase()) {
    case "textarea":
      return element.val();
    case "input":
      switch (element.getAttribute("type").toLowerCase()) {
        case "text":
          return element.value;
        default: {
          return "";
        }
      }
    default:
      return element.textContent;
  }
}

function get_target_by(element, visit_id, page_id) {
  return {
    // visit_id: +window.tabId + new Date().getTime() + 200,
    visit_id: visit_id || uuidv1(),
    page_id: page_id || get_target_url(element),
  };
}

function get_source_by(element, pageIdOverride) {
  const storageVisitId = sessionStorage.getItem("sourceId");
  const newVisitId = uuidv1();
  const visitId = !!storageVisitId ? storageVisitId : newVisitId;
  const lastPageId = sessionStorage.getItem("lastPageId");
  const isBrowserEvent = !element;
  const pageId = !!lastPageId && isBrowserEvent && !pageIdOverride ? lastPageId : window.location.pathname;

  return {
    visit_id: visitId,
    page_id: pageId,
    root: get_source_root_by(element),
  };
}

function get_source_root_by(element) {
  const resource_type_object = { resource_type: "service" };
  if (!element) {
    return { ...resource_type_object, type: "other" };
  }

  // We can add other labels if we need to determine more root types
  const dataProbeLabel = element.getAttribute("data-probe");
  const dataProbeType = ROOT_KNOWN_LABELS.includes(dataProbeLabel) ? dataProbeLabel : "other";

  const serviceId = parseInt(element.getAttribute("data-service-id"));

  return {
    type: dataProbeType,
    ...(!Number.isNaN(serviceId) && { resource_id: serviceId }),
    ...resource_type_object,
  };
}

function get_target_url(element) {
  const current_url = window.location.pathname;
  if (!element) {
    return current_url.split("?")[0];
  }

  const href = element.getAttribute("href");
  return (!!href ? href : current_url).split("?")[0];
}
