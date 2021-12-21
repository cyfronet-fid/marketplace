export default function initBadgeState(scope = document) {
  const badge = document.getElementsByClassName("badge")[0];
  if (badge) {
    document.getElementsByClassName("badge")[0].addEventListener("click", function () {
      const target = document.getElementById("badge-text");
      const collapsed = target.classList.contains("show");
      const expiration = new Date(new Date().getTime() + 1000 * 1800).toGMTString();
      document.cookie = `badge-text=${collapsed};expires=${expiration};sameSite=None;secure`;
    });
  }
}
