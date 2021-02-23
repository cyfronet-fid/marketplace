export default function handleTabId() {
    window.addEventListener("beforeunload", function (e)
    {
        window.sessionStorage.tabId = window.tabId;

        return null;
    });

    window.addEventListener("load", function (e)
    {
        if (window.sessionStorage.tabId)
        {
            window.tabId = window.sessionStorage.tabId;
            window.sessionStorage.removeItem("tabId");
        }
        else
        {
            window.tabId = Math.floor(Math.random() * 1000000);
        }

        return null;
    });
}