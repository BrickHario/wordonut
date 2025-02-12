const toggleInfo = () => {
    const buttons = document.querySelectorAll(".toggle-info");
  
    // Gehe durch alle Buttons und speichere den ursprünglichen Text
    buttons.forEach((button, index) => {
      const pElem = button.querySelector("p");
      if (pElem && !button.dataset.originalText) {
        button.dataset.originalText = pElem.textContent;
      }
      // Mache den ersten Button standardmäßig aktiv und setze den Text auf "Map"
      if (index === 0) {
        button.classList.add("active");
        button.closest("li").style.backgroundColor = "#E4B808";
        if (pElem) {
          pElem.textContent = "Map";
        }
        // Optional: Stelle auch das zugehörige Info-Div sichtbar, falls erwünscht
        const targetId = button.dataset.target;
        const targetDiv = document.getElementById(targetId);
        if (targetDiv) {
          targetDiv.style.display = "block";
        }
      }
    });
  
    // Füge den Event-Listener für alle Buttons hinzu
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
  
        // Setze für alle Buttons den Hintergrund und Text zurück
        buttons.forEach(btn => {
          btn.closest("li").style.backgroundColor = "";
          const p = btn.querySelector("p");
          if (p && btn.dataset.originalText) {
            p.textContent = btn.dataset.originalText;
          }
        });
  
        // Verberge alle Info-Divs und entferne die "active"-Klasse
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
  };
  
  export default toggleInfo;
  