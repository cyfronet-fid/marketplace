import Rails from '@rails/ujs'

export default function initProbes(scope = window) {
    scope
        .document
        .querySelectorAll("[data-probe]")
        .forEach((element) => {
            element.removeEventListener('click', call_user_action_controller);
            element.addEventListener('click', async () => await call_user_action_controller(scope, element));
        });
}

async function call_user_action_controller(scope, element) {
    return await fetch("/user_action", {
        method: "POST",
        headers: {
            "X-CSRF-Token": Rails.csrfToken(),
            "Content-type": "application/json"
        },
        body: get_user_action_from(scope, element)
    });
}

function get_user_action_from(scope, element) {
    return JSON.stringify({
        timestamp: new Date().getTime(),
        source: get_source_by(scope, element),
        target: get_target_by(scope, element),
        action: get_action_by(scope, element)
    });
}

function get_action_by(scope, element) {
    const is_ordered = scope.location.pathname.includes("summary")
        && element.getAttribute("type") === "submit";
    return {
        type: element.tagName,
        text: element.textContent,
        order: is_ordered
    };
}

function get_target_by(scope, element) {
    return {
        visit_id: scope.tabId + "." + new Date().getTime(),
        page_id: get_target_url(scope.location.pathname, element)
    };
}

function get_source_by(scope, element) {
    return {
        visit_id: scope.tabId + "." + new Date().getTime(),
        page_id: scope.location.pathname,
        root: get_source_root_by(element)
    };
}

function get_source_root_by(element) {
    const is_recommendation_panel = element.getAttribute('data-probe') === "recommendation-panel";
    return is_recommendation_panel
        ? {
            root: {
                type: 'recommendation_panel',
                service_id: element.getAttribute('data-service-id')
            }
        }
        : { type: 'other' };
}

function get_target_url(actual_url, element) {
    if (element.getAttribute('href')) {
        return element.getAttribute('href');
    }

    if (element.hasChildNodes()) {
        const inside_hrefs = Array.prototype.slice.call(element.querySelectorAll('a'))
            .map(child => child.getAttribute('href'))
            .filter(href => href != null);
        if (inside_hrefs != null && inside_hrefs.length === 1) {
            return inside_hrefs.pop();
        }
    }

    return actual_url;
}