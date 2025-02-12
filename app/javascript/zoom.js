const zoom = () => {
  const svg = document.getElementById('zoomable-svg');
  let viewBox = { x: 0, y: 0, width: 1920, height: 1080 };

  let isDragging = false;
  let isPinching = false;
  let startX, startY; // Für Dragging (Desktop und Einzelfinger-Touch)
  let initialPinchDistance = 0;
  let initialViewBox = null; // Speichert die viewBox beim Start des Pinch-Zooms

  // Bewegungseinschränkungen
  const limits = {
    minX: 0,
    minY: 0,
    maxX: 1920,
    maxY: 1080
  };

  // Helfer, um das SVG-Attribut aktuell zu halten
  const updateViewBox = () => {
    svg.setAttribute('viewBox', `${viewBox.x} ${viewBox.y} ${viewBox.width} ${viewBox.height}`);
  };

  // ============================
  // Desktop: Mausrad-Zoom (nur mit Shift)
  // ============================
  svg.addEventListener('wheel', (event) => {
    // Nur zoomen, wenn die Shift-Taste gedrückt ist
    if (!event.shiftKey) return;

    event.preventDefault();

    const zoomFactor = 1.1;
    const delta = event.deltaY > 0 ? zoomFactor : 1 / zoomFactor;

    const rect = svg.getBoundingClientRect();
    // Mausposition in SVG-Koordinaten ermitteln
    const mouseX = ((event.clientX - rect.left) / rect.width) * viewBox.width + viewBox.x;
    const mouseY = ((event.clientY - rect.top) / rect.height) * viewBox.height + viewBox.y;

    let newWidth = viewBox.width * delta;
    let newHeight = viewBox.height * delta;

    // Zoom-Limits (anpassen, wenn nötig)
    if (newWidth < 500) newWidth = 500;
    if (newWidth > 1920) newWidth = 1920;
    newHeight = (newWidth / 1920) * 1080;

    // Damit der Mauszeiger im Zoom-Zentrum bleibt:
    viewBox.x = mouseX - (mouseX - viewBox.x) * (newWidth / viewBox.width);
    viewBox.y = mouseY - (mouseY - viewBox.y) * (newHeight / viewBox.height);
    viewBox.width = newWidth;
    viewBox.height = newHeight;

    updateViewBox();
  });

  // ============================
  // Desktop: Dragging mit der Maus
  // ============================
  svg.addEventListener('mousedown', (event) => {
    isDragging = true;
    startX = event.clientX;
    startY = event.clientY;
  });

  svg.addEventListener('mousemove', (event) => {
    if (!isDragging) return;

    const dx = (event.clientX - startX) * (viewBox.width / svg.clientWidth);
    const dy = (event.clientY - startY) * (viewBox.height / svg.clientHeight);

    viewBox.x = Math.min(Math.max(viewBox.x - dx, limits.minX), limits.maxX - viewBox.width);
    viewBox.y = Math.min(Math.max(viewBox.y - dy, limits.minY), limits.maxY - viewBox.height);

    updateViewBox();

    startX = event.clientX;
    startY = event.clientY;
  });

  svg.addEventListener('mouseup', () => {
    isDragging = false;
  });

  svg.addEventListener('mouseleave', () => {
    isDragging = false;
  });

  // ============================
  // Mobile: Touch-Events (Pinch-Zoom und Dragging)
  // ============================
  svg.addEventListener(
    'touchstart',
    (event) => {
      if (event.touches.length === 1) {
        // Einzelfinger: Dragging
        isDragging = true;
        startX = event.touches[0].clientX;
        startY = event.touches[0].clientY;
      } else if (event.touches.length === 2) {
        // Zwei Finger: Pinch-Zoom
        isPinching = true;
        isDragging = false; // Während des Pinch-Zooms deaktivieren wir das Dragging

        const touch1 = event.touches[0];
        const touch2 = event.touches[1];
        // Abstand zwischen den beiden Touchpunkten
        initialPinchDistance = Math.hypot(
          touch2.clientX - touch1.clientX,
          touch2.clientY - touch1.clientY
        );
        // Aktuellen Zustand der viewBox kopieren
        initialViewBox = { ...viewBox };
      }
    },
    { passive: false }
  );

  svg.addEventListener(
    'touchmove',
    (event) => {
      // Bei Pinch-Zoom mit zwei Fingern:
      if (isPinching && event.touches.length === 2) {
        event.preventDefault(); // Verhindert das Standard-Scrollen

        const touch1 = event.touches[0];
        const touch2 = event.touches[1];
        const newDistance = Math.hypot(
          touch2.clientX - touch1.clientX,
          touch2.clientY - touch1.clientY
        );
        // Berechne den Skalierungsfaktor: Wird größer als 1, wenn die Finger auseinander gehen (reiner Zoom-In)
        const scale = newDistance / initialPinchDistance;

        // Neue viewBox-Dimensionen
        const newWidth = initialViewBox.width / scale;
        const newHeight = initialViewBox.height / scale;

        // Berechne das Zentrum des Pinch-Gestures (in Client-Koordinaten)
        const centerClientX = (touch1.clientX + touch2.clientX) / 2;
        const centerClientY = (touch1.clientY + touch2.clientY) / 2;

        // Umrechnung in SVG-Koordinaten (basierend auf der initialen viewBox)
        const rect = svg.getBoundingClientRect();
        const centerSvgX =
          ((centerClientX - rect.left) / rect.width) * initialViewBox.width +
          initialViewBox.x;
        const centerSvgY =
          ((centerClientY - rect.top) / rect.height) * initialViewBox.height +
          initialViewBox.y;

        // So wird sichergestellt, dass das Zoom-Zentrum (der Finger-Mittelpunkt)
        // im Bild gleich bleibt:
        viewBox.x = centerSvgX - (centerSvgX - initialViewBox.x) / scale;
        viewBox.y = centerSvgY - (centerSvgY - initialViewBox.y) / scale;
        viewBox.width = newWidth;
        viewBox.height = newHeight;

        // Optional: Hier kannst du auch Zoom-Limits einbauen (analog zum Mausrad)
        updateViewBox();
      } else if (isDragging && event.touches.length === 1) {
        // Einzelfinger-Dragging
        event.preventDefault();
        const touch = event.touches[0];
        const dx = (touch.clientX - startX) * (viewBox.width / svg.clientWidth);
        const dy = (touch.clientY - startY) * (viewBox.height / svg.clientHeight);

        viewBox.x = Math.min(Math.max(viewBox.x - dx, limits.minX), limits.maxX - viewBox.width);
        viewBox.y = Math.min(Math.max(viewBox.y - dy, limits.minY), limits.maxY - viewBox.height);

        updateViewBox();

        startX = touch.clientX;
        startY = touch.clientY;
      }
    },
    { passive: false }
  );

  svg.addEventListener('touchend', (event) => {
    // Wenn weniger als 2 Finger aktiv sind, beenden wir das Pinch-Zoom
    if (event.touches.length < 2) {
      isPinching = false;
    }
    if (event.touches.length === 0) {
      isDragging = false;
    }
  });

  svg.addEventListener('touchcancel', () => {
    isPinching = false;
    isDragging = false;
  });
};

// Die Zoom-Funktion sofort initialisieren
zoom();

export default zoom;
