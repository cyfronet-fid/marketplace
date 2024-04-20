export default function initFlash() {
  const flash = document.getElementById("flash-messages");
  if (flash) {
    flash.style.opacity = 1;
    setTimeout(function () {
      flash.style.transition = "5s";
      flash.style.opacity = 0;
    }, 1000);
    setTimeout(function () {
      flash.style.display = "none";
    }, 5000);
  }
}
