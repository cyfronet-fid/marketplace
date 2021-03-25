import Rails from '@rails/ujs'

const WINDOW_EVENTS_HANDLERS = {
    beforeunload: async () => {
        if (history.length !== 1) {
            await handle_any_event();
        }
    },
    popstate: async () => await handle_any_event()
};

export default async function initProbes() {
    // Handle all internal open in new tab/window that was not handled by click event
    if (history.length === 1) {
        await handle_any_event();
    }

    handle_browser_events();

    // Handle DOM events
    const elements = [
        ...Array.from(window.document.querySelectorAll("[data-probe]")),

        // IMPORTANT!!! class should be added to DOM elements only when there are any other options!!!
        ...Array.from(window.document.querySelectorAll(".data-probe"))
    ];
    const elementsSize = elements.length;
    let actions, actionsSize;
    for (let i = 0; i < elementsSize; i++) {
        actions = get_event_actions_by(elements[i].tagName);
        actionsSize = actions.length;
        for (let x = 0; x < actionsSize; x++) {
            add_dom_event_listener(elements[i], actions[x]);
        }
    }
}

function add_dom_event_listener(element, action) {
    element.addEventListener(action, async (event) => {
        // IMPORTANT!!! In case when child dom element "a" (link) can't be tagged directly
        const isTargetElementLink = event.target.tagName.toLowerCase() === 'a';
        const targetElement = isTargetElementLink ? event.target : element;
        if (targetElement.disabled) { return; }

        if (is_new_tab_open(action, event)) {
            await handle_outside_open_new_tab_event(targetElement);
            return;
        }

        await handle_any_event(targetElement);
    });
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

async function handle_outside_open_new_tab_event(element) {
    const href = element.getAttribute('href');
    const isOutsideUrl = !!href && !href.includes(window.location.origin);
    if (isOutsideUrl) {
        await handle_any_event(element);
    }
}

async function handle_any_event(element = null) {
    const body = {
        timestamp: new Date().toISOString(),
        source: get_source_by(element),
        target: get_target_by(element),
        user_action: get_action_by(element)
    };

    await call_user_action_controller(body);

    localStorage.setItem("lastTargetVisitId", "" + body.target.visit_id);
    localStorage.setItem("lastPageId", window.location.pathname);

    remove_browser_events_listeners();
}

const call_user_action_controller = (body) => {
    return fetch("/user_action", {
        method: "POST",
        headers: {
            "X-CSRF-Token": Rails.csrfToken(),
            "Content-type": "application/json"
        },
        body: JSON.stringify(body)
    })
        .then()
        .catch(error => console.log(error));
}

function is_new_tab_open(action, event) {
    switch (action) {
        case 'auxclick':
            return event.button === 1;
        case 'click':
            return event.ctrlKey || event.shiftKey || event.metaKey;
        default:
            return false;
    }
}

function get_event_actions_by(tagName) {
    switch(tagName.toLowerCase()) {
        case 'input':
            return ['input'];
        case 'a':
            return ['click', 'auxclick'];
        default:
            return ['click'];
    }
}

function get_action_by(element) {
    const is_ordered = window.location.pathname.includes("summary")
        && element
        && element.getAttribute("type") === "submit";

    return {
        type: !!element ? element.tagName : "browser action",
        text: get_element_text(element),
        order: is_ordered
    };
}

function get_element_text(element) {
    if (!element || !element.tagName) {
        return "";
    }

    switch (element.tagName.toLowerCase()) {
        case 'textarea':
            return element.val();
        case 'input':
            switch (element.getAttribute("type").toLowerCase()) {
                case 'text':
                    return element.value;
                default: {
                    return "";
                }
            }
        default:
            return element.textContent;
    }
}

function get_target_by(element) {
    console.log(localStorage.getItem("nextPageId"))

    return {
        visit_id: +window.tabId + new Date().getTime() + 200,
        page_id: get_target_url(element)
    };
}

function get_source_by(element) {
    const storageVisitId = +localStorage.getItem("lastTargetVisitId");
    const newVisitId = +window.tabId + new Date().getTime();
    const visitId = !!storageVisitId ? storageVisitId : newVisitId;
    const lastPageId = localStorage.getItem("lastPageId");
    const isBrowserEvent = !element;
    const pageId = !!lastPageId && isBrowserEvent ? lastPageId : window.location.pathname;

    return {
        visit_id: visitId,
        page_id: pageId,
        root: get_source_root_by(element)
    };
}

function get_source_root_by(element) {
    if (!element) {
        return { type: 'other' };
    }

    const is_recommendation_panel = element.getAttribute('data-probe') === "recommendation-panel";
    if (is_recommendation_panel) {
        return {
            type: 'recommendation_panel',
            service_id: parseInt(element.getAttribute('data-service-id'))
        }
    }

    return { type: 'other' };
}

function get_target_url(element) {
    const current_url = window.location.pathname;
    if (!element) {
        return current_url.split("?")[0];
    }

    const href = element.getAttribute('href');
    return (!!href ? href : current_url).split("?")[0];
}