export default function assignTabIdToWindow() {
  if (!window.sessionStorage.tabId) {
    window.tabId = Math.floor(Math.random() * 1000000);
  } else {
    window.tabId = window.sessionStorage.tabId;
    window.sessionStorage.removeItem("tabId");
  }

  return null;
}
