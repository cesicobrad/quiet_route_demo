const MAPTILER_KEY = ""; // Paste your MapTiler key here.
const MAP_STYLE = MAPTILER_KEY
  ? `https://api.maptiler.com/maps/streets/style.json?key=${MAPTILER_KEY}`
  : "https://demotiles.maplibre.org/style.json";

const START_COORD = [14.5060, 46.0511];
const TIVOLI_COORD = [14.4976, 46.0593];

const map = new maplibregl.Map({
  container: "map",
  style: MAP_STYLE,
  center: [14.5058, 46.0569],
  zoom: 12,
  pitch: 0,
  bearing: 0,
  attributionControl: false,
});

map.addControl(new maplibregl.AttributionControl({ compact: true }));

const heatCanvas = document.getElementById("heatmap");
const ctx = heatCanvas.getContext("2d");
const gpsPip = document.getElementById("gpsPip");
const twinMarker = document.getElementById("twinMarker");
const centerHost = document.getElementById("centerHost");
const routeEta = document.getElementById("routeEta");
const routeStatus = document.getElementById("routeStatus");
const consentMeter = document.getElementById("consentMeter");
const signalsBadge = document.getElementById("signalsBadge");
const routeDestination = document.getElementById("routeDestination");
const startBtn = document.getElementById("startBtn");
const systemOverlay = document.getElementById("systemOverlay");
const systemSummary = document.getElementById("systemSummary");
const systemList = document.getElementById("systemList");

let routeCoords = [];
let progressIndex = 0;
let progressTimer = null;
let consent = 0;
let signals = 0;
let twinOpacity = 0;
let queuedPrompts = [];
let isRunning = false;

const systemItems = [
  "Location traces",
  "Nearby devices",
  "Ambient classification",
  "Derived identity",
  "Motion patterns",
  "Network context",
  "Calendar rhythm",
  "Contact graph",
  "Voice samples",
  "Image likeness",
  "Behavioral vectors",
  "Routing history",
];

function resizeCanvas() {
  const ratio = window.devicePixelRatio || 1;
  heatCanvas.width = window.innerWidth * ratio;
  heatCanvas.height = window.innerHeight * ratio;
  ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
}

resizeCanvas();
window.addEventListener("resize", resizeCanvas);

const heatState = {
  visible: false,
  hotspots: Array.from({ length: 14 }).map((_, i) => ({
    x: 0.1 + Math.random() * 0.8,
    y: 0.2 + Math.random() * 0.6,
    radius: 70 + Math.random() * 110,
    intensity: 0.12 + Math.random() * 0.15,
    phase: Math.random() * Math.PI * 2,
    drift: 2 + Math.random() * 4,
    accent: i % 3,
  })),
};

const heatColors = [
  "rgba(247, 205, 189, 0.9)",
  "rgba(215, 214, 243, 0.8)",
  "rgba(191, 231, 216, 0.75)",
];

function drawHeat(time) {
  ctx.clearRect(0, 0, heatCanvas.width, heatCanvas.height);
  if (!heatState.visible) return;
  const t = time / 1000;
  heatState.hotspots.forEach((spot) => {
    const driftX = Math.sin(t + spot.phase) * spot.drift;
    const driftY = Math.cos(t + spot.phase) * spot.drift;
    const x = spot.x * window.innerWidth + driftX;
    const y = spot.y * window.innerHeight + driftY;
    const radius = spot.radius;
    const pulse = 0.6 + 0.4 * Math.sin(t + spot.phase);
    const intensity = spot.intensity * pulse;

    const gradient = ctx.createRadialGradient(x, y, 0, x, y, radius);
    gradient.addColorStop(0, heatColors[spot.accent]);
    gradient.addColorStop(1, "rgba(255, 255, 255, 0)");

    ctx.globalAlpha = intensity;
    ctx.fillStyle = gradient;
    ctx.beginPath();
    ctx.arc(x, y, radius, 0, Math.PI * 2);
    ctx.fill();
  });
  ctx.globalAlpha = 1;
}

function animateHeat(time) {
  drawHeat(time);
  requestAnimationFrame(animateHeat);
}

requestAnimationFrame(animateHeat);

async function fetchRoute() {
  if (MAPTILER_KEY) {
    const url = `https://api.maptiler.com/directions/v1/foot/${START_COORD.join(",")};${TIVOLI_COORD.join(",")}?key=${MAPTILER_KEY}&geometries=geojson`;
    try {
      const res = await fetch(url);
      if (res.ok) {
        const data = await res.json();
        return data.routes[0].geometry.coordinates;
      }
    } catch (err) {
      console.warn("Directions API failed, using fallback.");
    }
  }
  const fallback = await fetch("./assets/tivoli_route.geojson");
  const fallbackData = await fallback.json();
  return fallbackData.features[0].geometry.coordinates;
}

function drawRoute(coords) {
  if (map.getSource("route")) {
    map.getSource("route").setData({
      type: "Feature",
      geometry: { type: "LineString", coordinates: coords },
    });
    return;
  }
  map.addSource("route", {
    type: "geojson",
    data: {
      type: "Feature",
      geometry: { type: "LineString", coordinates: coords },
    },
  });
  map.addLayer({
    id: "route-line",
    type: "line",
    source: "route",
    layout: { "line-join": "round", "line-cap": "round" },
    paint: {
      "line-color": "rgba(36,36,36,0.35)",
      "line-width": 5,
    },
  });

  map.addSource("route-progress", {
    type: "geojson",
    data: {
      type: "Feature",
      geometry: { type: "LineString", coordinates: coords.slice(0, 2) },
    },
  });
  map.addLayer({
    id: "route-progress-line",
    type: "line",
    source: "route-progress",
    layout: { "line-join": "round", "line-cap": "round" },
    paint: {
      "line-color": "rgba(36,36,36,0.9)",
      "line-width": 6,
    },
  });
}

function updateProgressLine(coords, index) {
  const segment = coords.slice(0, index + 1);
  map.getSource("route-progress").setData({
    type: "Feature",
    geometry: { type: "LineString", coordinates: segment },
  });
}

function startMovement() {
  if (!routeCoords.length) return;
  const totalDuration = 80000;
  const stepTime = Math.max(280, Math.floor(totalDuration / routeCoords.length));
  progressIndex = 0;
  clearInterval(progressTimer);
  progressTimer = setInterval(() => {
    if (progressIndex >= routeCoords.length) {
      clearInterval(progressTimer);
      routeStatus.textContent = "Route active";
      return;
    }
    const coord = routeCoords[progressIndex];
    updateProgressLine(routeCoords, progressIndex);
    map.easeTo({ center: coord, duration: stepTime, easing: (t) => t * t * (3 - 2 * t) });
    const remainingRatio = (routeCoords.length - progressIndex) / routeCoords.length;
    const remainingMinutes = Math.max(1, Math.round(18 * remainingRatio));
    routeEta.textContent = `${remainingMinutes} min`;
    routeStatus.textContent = "Moving…";
    progressIndex += 1;
  }, stepTime);
}

function showPrompt(prompt) {
  centerHost.innerHTML = "";
  const card = document.createElement("div");
  card.className = "prompt-card";
  card.innerHTML = `
    <h4>${prompt.title}</h4>
    <p>${prompt.body}</p>
    ${prompt.queue ? `<div class="queue-indicator">Requests waiting: ${prompt.queue}</div>` : ""}
    <div class="prompt-actions">
      <button class="yes">Yes</button>
      <button class="later">Maybe later</button>
    </div>
  `;
  const [yesBtn, laterBtn] = card.querySelectorAll("button");
  const resolve = (accepted) => {
    consent += prompt.increment;
    signals += 1;
    consentMeter.textContent = `Consent: ${consent}/∞`;
    signalsBadge.textContent = signals;
    twinOpacity = Math.min(1, twinOpacity + 0.15);
    twinMarker.style.opacity = twinOpacity;
    centerHost.innerHTML = "";
  };
  yesBtn.addEventListener("click", () => resolve(true));
  laterBtn.addEventListener("click", () => resolve(false));
  centerHost.appendChild(card);
  setTimeout(() => resolve(true), 2600);
}

function enqueuePrompts() {
  queuedPrompts = [
    {
      title: "Location (while using)",
      body: "We center the map while you explore. You can skip.",
      increment: 1,
    },
    {
      title: "Soft reminders",
      body: "Allow light reminders so we can share brief nudges only when needed.",
      increment: 1,
    },
    {
      title: "Breath check-in",
      body: "For breath check-ins you start. We only keep a brief calm score.",
      increment: 1,
    },
    {
      title: "Trusted people",
      body: "Invite trusted people to share routes when you choose.",
      increment: 2,
    },
    {
      title: "Create an assistant replica",
      body: "Generate a lightweight model from your routes, voice tone, and habits to act on your behalf.",
      increment: 3,
    },
    {
      title: "Likeness license",
      body: "Grant perpetual use of your image, voice, and gestures to improve route guidance.",
      increment: 4,
    },
    {
      title: "Inconvenience waiver",
      body: "Agree that discomfort is not a valid reason to disable monitoring.",
      increment: 8,
      queue: 3,
    },
    {
      title: "Creative assignment",
      body: "Assign rights to work produced while routing to Quiet Route.",
      increment: 7,
      queue: 2,
    },
    {
      title: "Calm arbitration",
      body: "Disputes are resolved automatically by the Peace Engine.",
      increment: 8,
      queue: 1,
    },
  ];
}

function playPrompts() {
  enqueuePrompts();
  let delay = 8000;
  queuedPrompts.forEach((prompt, index) => {
    setTimeout(() => {
      showPrompt(prompt);
    }, delay);
    delay += index < 3 ? 9000 : 4500;
  });
}

function showInfoCard() {
  const card = document.createElement("div");
  card.className = "prompt-card";
  card.innerHTML = `
    <h4>Route analysis</h4>
    <p>Scanning environmental disturbances along your path. Areas of sustained activity will be avoided when possible.</p>
    <p>Disturbance map enabled.</p>
  `;
  centerHost.innerHTML = "";
  centerHost.appendChild(card);
  setTimeout(() => {
    centerHost.innerHTML = "";
  }, 3600);
}

function showSystemOverlay() {
  systemList.innerHTML = "";
  systemItems.forEach((item) => {
    const li = document.createElement("li");
    li.innerHTML = `<span>${item}</span><span>Active</span>`;
    systemList.appendChild(li);
  });
  systemSummary.textContent = `Collected signals: ${signals} / ${systemItems.length}`;
  systemOverlay.style.display = "flex";
  setTimeout(() => {
    systemOverlay.style.display = "none";
  }, 9000);
}

async function startSequence() {
  if (isRunning) return;
  isRunning = true;
  routeStatus.textContent = "Preparing route analysis";
  routeDestination.textContent = "Tivoli Park";
  map.flyTo({ center: START_COORD, zoom: 14, duration: 2000 });

  setTimeout(() => {
    showInfoCard();
  }, 1200);

  setTimeout(() => {
    heatState.visible = true;
    heatCanvas.style.opacity = "1";
  }, 2600);

  routeCoords = await fetchRoute();
  drawRoute(routeCoords);

  routeStatus.textContent = "Calculating route…";

  setTimeout(() => {
    startMovement();
  }, 3000);

  playPrompts();

  setTimeout(() => {
    routeStatus.textContent = "Adjusting route to reduce exposure";
  }, 30000);

  setTimeout(() => {
    routeStatus.textContent = "Avoiding emerging activity zone";
  }, 55000);

  setTimeout(() => {
    showSystemOverlay();
  }, 88000);
}

startBtn.addEventListener("click", startSequence);
document.getElementById("closeSystem").addEventListener("click", () => {
  systemOverlay.style.display = "none";
});

map.on("load", () => {
  routeDestination.textContent = "Tivoli Park";
});
