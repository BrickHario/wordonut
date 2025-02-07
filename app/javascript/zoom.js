const zoom = () => {
    const svg = document.getElementById('zoomable-svg');
    let viewBox = { x: 0, y: 0, width: 1920, height: 1080 };
  
    let isDragging = false;
    let startX, startY;
  
    // Bewegungseinschränkungen
    const limits = {
      minX: 0,
      minY: 0,
      maxX: 1920,
      maxY: 1080
    };
  
    // Mousewheel Zoom
    svg.addEventListener('wheel', (event) => {
      event.preventDefault();
  
      const zoomFactor = 1.1;
      const delta = event.deltaY > 0 ? zoomFactor : 1 / zoomFactor;
  
      const rect = svg.getBoundingClientRect();
      const mouseX = ((event.clientX - rect.left) / rect.width) * viewBox.width + viewBox.x;
      const mouseY = ((event.clientY - rect.top) / rect.height) * viewBox.height + viewBox.y;
  
      let newWidth = viewBox.width * delta;
      let newHeight = viewBox.height * delta;
  
      // Zoom Limits
      if (newWidth < 500) newWidth = 500;
      if (newWidth > 1920) newWidth = 1920;
      newHeight = (newWidth / 1920) * 1080;
  
      viewBox.x = mouseX - (mouseX - viewBox.x) * (newWidth / viewBox.width);
      viewBox.y = mouseY - (mouseY - viewBox.y) * (newHeight / viewBox.height);
      viewBox.width = newWidth;
      viewBox.height = newHeight;
  
      svg.setAttribute('viewBox', `${viewBox.x} ${viewBox.y} ${viewBox.width} ${viewBox.height}`);
    });
  
    // Dragging Events
    svg.addEventListener('mousedown', (event) => {
      isDragging = true;
      startX = event.clientX;
      startY = event.clientY;
    });
  
    svg.addEventListener('mousemove', (event) => {
      if (!isDragging) return;
  
      const dx = (event.clientX - startX) * (viewBox.width / svg.clientWidth);
      const dy = (event.clientY - startY) * (viewBox.height / svg.clientHeight);
  
      // Begrenzte Bewegung
      viewBox.x = Math.min(Math.max(viewBox.x - dx, limits.minX), limits.maxX - viewBox.width);
      viewBox.y = Math.min(Math.max(viewBox.y - dy, limits.minY), limits.maxY - viewBox.height);
  
      svg.setAttribute('viewBox', `${viewBox.x} ${viewBox.y} ${viewBox.width} ${viewBox.height}`);
  
      startX = event.clientX;
      startY = event.clientY;
    });
  
    svg.addEventListener('mouseup', () => {
      isDragging = false;
    });
  
    svg.addEventListener('mouseleave', () => {
      isDragging = false;
    });
  };
  
  // Falls du die Funktion sofort initialisieren möchtest:
  zoom();
  
  export default zoom;
  