const toggleInfo = () => {
    const buttons = document.querySelectorAll(".toggle-info");

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

           
            allDivs.forEach(div => div.style.display = "none");
            buttons.forEach(btn => btn.classList.remove("active"));

            if (!isVisible || !isActive) {
                targetDiv.style.display = "block";
                this.classList.add("active"); 
            } else {
                this.classList.remove("active"); 
            }
        });
    });
}

export default toggleInfo;
