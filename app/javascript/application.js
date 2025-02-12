// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import mobileMenu from "mobile-menu";
import toggleInfo from "toggle-info";
import zoom from "zoom";

document.addEventListener("turbo:load", () => {
  mobileMenu();
  toggleInfo();
  zoom();
});

document.addEventListener("turbo:load", function() {
  // Lade-Overlay beim Absenden des Formulars anzeigen
  var translateForm = document.getElementById("translate-form");
  if (translateForm) {
    translateForm.addEventListener("submit", function() {
      document.getElementById("loading-overlay").style.display = "flex";
    });
  }

  // Lade-Overlay anzeigen, wenn eine Übersetzung angeklickt wird
  document.querySelectorAll(".translation-link").forEach(function(button) {
    button.addEventListener("click", function() {
      document.getElementById("loading-overlay").style.display = "flex";
    });
  });
});



