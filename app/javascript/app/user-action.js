import Rails from '@rails/ujs'

export default function initProbes(scope = window) {
    [
        ...Array.from(scope.document.querySelectorAll("[data-probe]")),

        // IMPORTANT!!! class should be added to DOM elements only when there are any other option!!!
        ...Array.from(scope.document.querySelectorAll(".data-probe"))
    ]
        .forEach(element => {
            const action = get_event_action_by(element.tagName);
            element.addEventListener(action, async () => {
                // prevent call for disabled element
                if (element.disabled) {
                    return;
                }

                const body = get_dom_action_from(scope, element);
                await call_user_action_controller(body);
            });
        });
}

const call_user_action_controller = async (body) => {
    return await fetch("/user_action", {
        method: "POST",
        headers: {
            "X-CSRF-Token": Rails.csrfToken(),
            "Content-type": "application/json"
        },
        body: body
    })
        .catch(error => console.log(error));
}

function get_event_action_by(tagName) {
    switch(tagName.toLowerCase()) {
        case 'input':
            return 'input';
        default:
            return 'click';
    }
}

function get_dom_action_from(scope, element) {
    return JSON.stringify({
        timestamp: new Date().toISOString(),
        source: get_source_by(scope, element),
        target: get_target_by(scope, element),
        user_action: get_action_by(scope, element)
    });
}

function get_action_by(scope, element) {
    const is_ordered = scope.location.pathname.includes("summary")
        && element.getAttribute("type") === "submit";

    return {
        type: element.tagName,
        text: get_element_text(element),
        order: is_ordered
    };
}

function get_element_text(element) {
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
    if (element.hasAttribute('href')) {
        return element.getAttribute('href');
    }

    const isOnlyChildAnchor = element.hasChildNodes()
        && element.children.length === 1
        && element.children[0].hasAttribute('href');
    if (isOnlyChildAnchor) {
        return element.children[0].getAttribute('href');
    }

    const isParentAnchor = element.parentNode.hasAttribute('href');
    if (isParentAnchor) {
        return parent.getAttribute('href');
    }

    return actual_url;
}