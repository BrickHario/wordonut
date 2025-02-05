// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import mobileMenu from "./mobile-menu.js";
import toggleInfo from "./toggle-info.js";

document.addEventListener("turbo:load", () => {
  mobileMenu();
  toggleInfo();
});

