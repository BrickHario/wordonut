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

