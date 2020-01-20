export default function initFlash() {
  const flash = $(".flash-container");
  if (flash.length > 0) {
    const fadeOut = function() { flash.fadeOut() };
    flash.click(fadeOut);
    setTimeout(fadeOut, 5000);
  }
}
