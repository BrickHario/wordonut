const toggleInfo = () => {
  // Event-Listener für die .toggle-info Buttons (wie gehabt)
  const buttons = document.querySelectorAll(".toggle-info");
  buttons.forEach((button, index) => {
    const pElem = button.querySelector("p");
    if (pElem && !button.dataset.originalText) {
      button.dataset.originalText = pElem.textContent;
    }
    if (index === 0) {
      button.classList.add("active");
      button.closest("li").style.backgroundColor = "#E4B808";
      if (pElem) {
        pElem.textContent = "Map";
      }
      const targetId = button.dataset.target;
      const targetDiv = document.getElementById(targetId);
      if (targetDiv) {
        targetDiv.style.display = "block";
      }
    }
  });

  buttons.forEach(button => {
    button.addEventListener("click", function (event) {
      event.preventDefault();
      const targetId = this.dataset.target;
      const targetDiv = document.getElementById(targetId);
      const allDivs = document.querySelectorAll(".search-info");
      if (!targetDiv) {
        console.error(`Element with ID '${targetId}' not found.`);
        return;
      }
      const isVisible = targetDiv.style.display === "block";
      const isActive = this.classList.contains("active");
      buttons.forEach(btn => {
        btn.closest("li").style.backgroundColor = "";
        const p = btn.querySelector("p");
        if (p && btn.dataset.originalText) {
          p.textContent = btn.dataset.originalText;
        }
      });
      allDivs.forEach(div => (div.style.display = "none"));
      buttons.forEach(btn => btn.classList.remove("active"));
      if (!isVisible || !isActive) {
        targetDiv.style.display = "block";
        this.classList.add("active");
        this.closest("li").style.backgroundColor = "#E4B808";
        const p = this.querySelector("p");
        if (p) {
          p.textContent = "Map";
        }
      } else {
        this.classList.remove("active");
        const p = this.querySelector("p");
        if (p && this.dataset.originalText) {
          p.textContent = this.dataset.originalText;
        }
      }
    });
  });

  if (document.body.dataset.loggedIn === "true") {
    document.querySelectorAll("[data-lang]").forEach(el => {
      el.addEventListener("click", () => {
        // Open the translation section
        const translationSection = document.getElementById("translation");
        const infoSection = document.getElementById("info");
        const saveSection = document.getElementById("save");
        if (translationSection) {
          translationSection.style.display = "block";
          infoSection.style.display = "none";
          saveSection.style.display = "none";
        }
        // Read the language group name from the data-lang attribute (e.g., "Germanic")
        const langGroup = el.getAttribute("data-lang");
        // Find the corresponding div (e.g., <div id="Germanic">)
        const targetDiv = document.getElementById(langGroup);
        if (targetDiv) {
          targetDiv.style.display = "block";
          targetDiv.scrollIntoView({ behavior: "smooth", block: "start" });
        } else {
          console.error("Element with ID '" + langGroup + "' not found.");
        }
        const mapButton = Array.from(buttons).find(btn => btn.dataset.target === "translation");
        if (mapButton) {
          // Reset all buttons
          buttons.forEach(btn => {
            btn.closest("li").style.backgroundColor = "";
            const p = btn.querySelector("p");
            if (p && btn.dataset.originalText) {
              p.textContent = btn.dataset.originalText;
            }
            btn.classList.remove("active");
          });
          // Activate the map button
          mapButton.classList.add("active");
          mapButton.closest("li").style.backgroundColor = "#E4B808";
          const p = mapButton.querySelector("p");
          if (p) {
            p.textContent = "Map";
          }
        }
      });
    });
  }
  
};

export default toggleInfo;


