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

function showLoadingOverlay() {
  document.getElementById("loading-overlay").style.display = "flex";
}

if (window.Turbo) {
  document.addEventListener("turbo:load", function() {
    var translateForm = document.getElementById("translate-form");
    if (translateForm) {
      translateForm.addEventListener("submit", showLoadingOverlay);
    }
    document.querySelectorAll(".translation-link").forEach(function(button) {
      button.addEventListener("click", showLoadingOverlay);
    });
  });
} else {
  document.addEventListener("DOMContentLoaded", function() {
    var translateForm = document.getElementById("translate-form");
    if (translateForm) {
      translateForm.addEventListener("submit", showLoadingOverlay);
    }
    document.querySelectorAll(".translation-link").forEach(function(button) {
      button.addEventListener("click", showLoadingOverlay);
    });
  });
}




