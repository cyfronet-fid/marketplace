import Rails from '@rails/ujs'

export default function initProbes(scope = window) {
    /**
     * Handle all internal
     * - open in new tab
     * - open in new window
     *
     * that was not handled by click event
     */
    if (history.length === 1) {
        handle_open_new_tab_event(scope);
    }

    [
        ...Array.from(scope.document.querySelectorAll("[data-probe]")),

        // IMPORTANT!!! class should be added to DOM elements only when there are any other options!!!
        ...Array.from(scope.document.querySelectorAll(".data-probe"))
    ]
        .forEach(element => {
            const actions = get_event_actions_by(element.tagName);
            actions
                .forEach(action => element.addEventListener(action, (event) => {
                    const targetElement = event.target.tagName.toLowerCase() === 'a'
                        ? event.target
                        : element;
                    if (targetElement.disabled) {
                        return;
                    }

                    if (is_new_tab_open(action, event)) {
                        handle_outside_open_new_tab_event(scope, targetElement);
                        return;
                    }

                    handle_dom_event(scope, targetElement);
                }));
        });
}

function handle_outside_open_new_tab_event(scope, element) {
    const href = element.getAttribute('href');
    const isOutsideUrl = !!href && !href.includes(window.location.origin);
    if (isOutsideUrl) {
        handle_open_new_tab_event(scope, element);
    }

    return isOutsideUrl;
}

function handle_dom_event(scope, element = null) {
    const body = {
        timestamp: new Date().toISOString(),
        source: get_source_by(scope, element),
        target: get_target_by(scope, element),
        user_action: get_action_by(scope, element)
    };
    call_user_action_controller(body).then();
}

function handle_open_new_tab_event(scope, element = null) {
    const source = get_source_by(scope, element);
    const user_action = get_action_by(scope, element);
    const body = {
        timestamp: new Date().toISOString(),
        source: { ...source, root: { type: "other" } },
        target: get_target_by(scope, element),
        user_action: { ...user_action, type: user_action.type + " - open new tab" }
    };

    call_user_action_controller(body).then();
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
            return  event.ctrlKey || event.shiftKey || event.metaKey;
    }
}

function get_event_actions_by(tagName) {
    switch(tagName.toLowerCase()) {
        case 'input':
            return ['input'];
        default:
            return ['click', 'auxclick'];
    }
}

function get_action_by(scope, element) {
    const is_ordered = scope.location.pathname.includes("summary")
        && element.getAttribute("type") === "submit";

    return {
        type: !!element ? element.tagName : "undefined",
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

function get_target_by(scope, element) {
    const target_timestamp = new Date().getTime() + Math.floor(Math.random() * (500 - 50)) + 50;
    return {
        visit_id: scope.tabId + "" + target_timestamp,
        page_id: get_target_url(scope.location.pathname, element)
    };
}

function get_source_by(scope, element) {
    return {
        visit_id: scope.tabId + "" + new Date().getTime(),
        page_id: scope.location.pathname,
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

function get_target_url(actual_url, element) {
    return !!element ? element.getAttribute('href') : actual_url;
}