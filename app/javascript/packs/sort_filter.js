function searchToObj(search) {
    let obj = {}, i, parts, len, key, value;

    let _params = search.substr(1).split('&');
    for (i = 0, len = _params.length; i < len; i++) {
        parts = _params[i].split('=');
        if (! parts[0]) {continue;}
        // page parameter should not be retained
        if (parts[0] === 'page') {continue;}
        obj[parts[0]] = parts[1] || "";
    }
    return obj;
}

function setSearchParams(search, params) {
    let parts, value;
    if (typeof params === 'string') {
        value = search.match(new RegExp('[?&]' + params + '=?([^&]*)[&#$]?'));
        return value ? value[1] : undefined;
    }

    let obj = searchToObj(search);

    if (typeof params !== 'object') {return obj;}

    for (let key in params) {
        value = params[key];
        if (typeof value === 'undefined') {
            delete obj[key];
        } else {
            obj[key] = value;
        }
    }

    parts = [];
    for (let key in obj) {
        parts.push(key + (obj[key] === true ? '' : '=' + obj[key]));
    }

    return parts.join('&');
}

export function registerSubmitOnChange(node) {
    $(node || 'body').find("[data-submit-on-change]").on('change', function () {
        let id = $(this).attr('id');
        let value = $(this).val();

        let search = setSearchParams(window.location.search, {[id]: value});
        Turbolinks.visit(window.location.pathname + '?' + search);
    });
}

export default function initSorting(node) {
    registerSubmitOnChange(node);
}
