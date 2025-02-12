const toggleInfo = () => {
    const buttons = document.querySelectorAll(".toggle-info");
    const firstLi = document.querySelector(".info-menu ul li:first-child");

    // Set initial background color for the first <li>
    if (firstLi) {
        firstLi.style.backgroundColor = "#E4B808";
    }

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

            // Reset background color for all <li> elements
            buttons.forEach(btn => btn.closest("li").style.backgroundColor = "");

            // Hide all divs and remove 'active' class
            allDivs.forEach(div => div.style.display = "none");
            buttons.forEach(btn => btn.classList.remove("active"));

            if (!isVisible || !isActive) {
                targetDiv.style.display = "block";
                this.classList.add("active");
                this.closest("li").style.backgroundColor = "#E4B808"; // Add background to the clicked <li>
            } else {
                this.classList.remove("active");
            }
        });
    });
}

export default toggleInfo;
