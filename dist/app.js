/* ==========================================================================
   AGRITWIN INTERACTIVE LOGIC CONTROLLER
   Handles Transitions, Mock Data Inputs, Dials, Theme, & Micro-interactions
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {
  // Initialize Lucide Icons
  lucide.createIcons();
  
  // Set system time in status bar
  updateStatusBarTime();
  setInterval(updateStatusBarTime, 60000);

  // Initialize event handlers
  initNavigation();
  initOnboarding();
  initAuthForm();
  initSimulator();
  initThemeToggles();
  initSearch();
  initConnectionTesting();
});

/* ==========================================================================
   TIME & STATUS BAR
   ========================================================================== */
function updateStatusBarTime() {
  const now = new Date();
  let hours = now.getHours();
  let minutes = now.getMinutes();
  hours = hours < 10 ? '0' + hours : hours;
  minutes = minutes < 10 ? '0' + minutes : minutes;
  const timeStr = `${hours}:${minutes}`;
  const element = document.getElementById('statusBarTime');
  if (element) element.innerText = timeStr;
}

/* ==========================================================================
   NAVIGATION SYSTEM (SPA VIEW SWITCHER)
   ========================================================================== */
const screens = ['splash', 'onboarding', 'login', 'home', 'search', 'climate', 'detail', 'profile', 'settings'];
let currentScreen = 'splash';

// Navigation button mappings
function initNavigation() {
  // Desktop control panel buttons
  document.querySelectorAll('.control-btn[data-target]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const target = btn.getAttribute('data-target');
      switchScreen(target);
      
      // Update active state in controller
      document.querySelectorAll('.control-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });

  // Mobile Bottom Navigation Bar buttons
  document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const target = btn.getAttribute('data-screen');
      switchScreen(target);
    });
  });
}

function switchScreen(screenId) {
  if (!screens.includes(screenId)) return;
  
  triggerHapticFeedback();
  
  // Hide all screens
  document.querySelectorAll('.screen-view').forEach(view => {
    view.classList.remove('active');
  });
  
  // Close any overlays
  closeEmptyState();
  closeLoadingState();
  closeErrorState();
  closeScanSimulation();
  
  // Show target screen
  const targetView = document.getElementById(`screen-${screenId}`);
  if (targetView) {
    targetView.classList.add('active');
  }
  
  currentScreen = screenId;

  // Show/Hide bottom navigation bar depending on screen
  const bottomNav = document.getElementById('bottomNavBar');
  if (['home', 'search', 'climate', 'detail', 'profile', 'settings'].includes(screenId)) {
    bottomNav.style.display = 'flex';
  } else {
    bottomNav.style.display = 'none';
  }

  // Update active state in bottom navigation bar
  document.querySelectorAll('.nav-btn').forEach(btn => {
    if (btn.getAttribute('data-screen') === screenId) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  // Update Desktop Controller highlights
  document.querySelectorAll('.control-btn[data-target]').forEach(btn => {
    if (btn.getAttribute('data-target') === screenId) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  // Special autofocus logic
  if (screenId === 'search') {
    setTimeout(() => {
      document.getElementById('searchField').focus();
    }, 300);
  }
}

/* ==========================================================================
   2. ONBOARDING SLIDER CAROUSEL
   ========================================================================== */
let activeSlideIndex = 0;
const totalSlides = 3;

function initOnboarding() {
  const slides = document.querySelectorAll('.onboarding-slide');
  const indicators = document.querySelectorAll('.indicator');

  function showSlide(index) {
    slides.forEach((slide, idx) => {
      if (idx === index) {
        slide.classList.add('active');
      } else {
        slide.classList.remove('active');
      }
    });

    indicators.forEach((ind, idx) => {
      if (idx === index) {
        ind.classList.add('active');
      } else {
        ind.classList.remove('active');
      }
    });
    activeSlideIndex = index;
  }

  // Skip button
  document.getElementById('onboardingSkip').addEventListener('click', () => {
    switchScreen('login');
  });

  // Next button
  document.getElementById('onboardingNext').addEventListener('click', () => {
    if (activeSlideIndex < totalSlides - 1) {
      showSlide(activeSlideIndex + 1);
    } else {
      switchScreen('login');
    }
  });

  // Clickable indicator dots
  indicators.forEach(indicator => {
    indicator.addEventListener('click', () => {
      const targetSlide = parseInt(indicator.getAttribute('data-go'));
      showSlide(targetSlide);
    });
  });
}

/* ==========================================================================
   3. LOGIN / PROFILE FLOW
   ========================================================================== */
function initAuthForm() {
  const form = document.getElementById('authForm');
  const tabLogin = document.getElementById('tabLogin');
  const tabSignUp = document.getElementById('tabSignUp');
  const loginSubmitBtn = document.getElementById('loginSubmitBtn');
  const biometricBtn = document.getElementById('biometricLoginBtn');

  // Tab switching
  tabLogin.addEventListener('click', () => {
    tabSignUp.classList.remove('active');
    tabLogin.classList.add('active');
    loginSubmitBtn.innerText = "Get Started";
  });

  tabSignUp.addEventListener('click', () => {
    tabLogin.classList.remove('active');
    tabSignUp.classList.add('active');
    loginSubmitBtn.innerText = "Register Profile";
  });

  // Form submission
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const name = document.getElementById('farmerName').value.trim() || 'Santhosh';
    
    // Save locally
    document.getElementById('userNameDisplay').innerText = name;
    document.querySelector('.profile-name').innerText = name;
    document.querySelector('.avatar').innerText = name.charAt(0).toUpperCase();
    document.querySelector('.profile-avatar').innerText = name.charAt(0).toUpperCase();

    // Trigger success haptic
    triggerSuccessFeedback();
    
    // Switch to home
    switchScreen('home');
  });

  // Biometric login action
  biometricBtn.addEventListener('click', () => {
    triggerHapticFeedback();
    const isBiometricEnabled = document.getElementById('biometricSettingsToggle').checked;

    if (!isBiometricEnabled) {
      alert("Biometric scanning is disabled in Settings.");
      return;
    }

    biometricBtn.classList.add('active');
    biometricBtn.innerHTML = `<i data-lucide="loader-2" class="bio-icon spin"></i> Scanning fingerprint...`;
    lucide.createIcons();

    setTimeout(() => {
      // Restore button state
      biometricBtn.classList.remove('active');
      biometricBtn.innerHTML = `<i data-lucide="fingerprint" class="bio-icon"></i> Fingerprint Scan`;
      lucide.createIcons();

      // Set user to Santhosh and switch to home
      document.getElementById('userNameDisplay').innerText = "Santhosh Kumar";
      document.querySelector('.profile-name').innerText = "Santhosh Kumar";
      document.querySelector('.avatar').innerText = "S";
      document.querySelector('.profile-avatar').innerText = "S";

      triggerSuccessFeedback();
      switchScreen('home');
    }, 1200);
  });
}

function logoutFlow() {
  triggerHapticFeedback();
  if (confirm("Are you sure you want to log out of your offline profile?")) {
    document.getElementById('farmerName').value = '';
    document.getElementById('phoneNumber').value = '';
    document.getElementById('securityPin').value = '';
    switchScreen('login');
  }
}

/* ==========================================================================
   4. INTERACTIVE HEALTH DIALS & WHAT-IF SIMULATOR
   ========================================================================== */
function initSimulator() {
  const moistureSlider = document.getElementById('simulatorMoistureSlider');
  const moistureVal = document.getElementById('simulatorMoistureVal');
  const npkSlider = document.getElementById('simulatorNpkSlider');
  const npkVal = document.getElementById('simulatorNpkVal');

  const soilNumber = document.getElementById('dialSoilValue');
  const cropNumber = document.getElementById('dialCropValue');
  const detailSoil = document.getElementById('detailSoilScore');
  const detailCrop = document.getElementById('detailCropScore');

  const soilCircle = document.querySelector('.dial-value.soil');
  const cropCircle = document.querySelector('.dial-value.crop');

  // Formula to recalculate scores dynamically based on slider values
  function recalculateTwinScores() {
    const moisture = parseInt(moistureSlider.value);
    const npk = parseInt(npkSlider.value);

    // Calculate simulated Soil Score (ideal moisture is ~60-70%, NPK ~50-60)
    const moistureDiff = Math.abs(moisture - 65);
    const npkDiff = Math.abs(npk - 55);
    
    let soilScore = 100 - (moistureDiff * 0.7) - (npkDiff * 0.5);
    soilScore = Math.min(Math.max(Math.round(soilScore), 15), 100);

    // Calculate Crop Vigor based on soil health and NPK values
    let cropScore = (soilScore * 0.8) + (npk * 0.2) + 2;
    cropScore = Math.min(Math.max(Math.round(cropScore), 20), 100);

    // Update text scores
    if (soilNumber) soilNumber.innerText = soilScore;
    if (cropNumber) cropNumber.innerText = cropScore;
    if (detailSoil) detailSoil.innerText = soilScore;
    if (detailCrop) detailCrop.innerText = cropScore;

    // Update gauge stroke-dashoffset (SVG circumference is 251.2)
    const maxCircumference = 251.2;
    const soilOffset = maxCircumference - (soilScore / 100) * maxCircumference;
    const cropOffset = maxCircumference - (cropScore / 100) * maxCircumference;

    if (soilCircle) soilCircle.style.strokeDashoffset = soilOffset;
    if (cropCircle) cropCircle.style.strokeDashoffset = cropOffset;

    // Modify detail polyline points to simulate real-time interactive charts
    updateChartData(soilScore, cropScore);
  }

  if (moistureSlider && npkSlider) {
    moistureSlider.addEventListener('input', () => {
      moistureVal.innerText = `${moistureSlider.value}%`;
      recalculateTwinScores();
    });

    npkSlider.addEventListener('input', () => {
      npkVal.innerText = `${npkSlider.value} kg/h`;
      recalculateTwinScores();
    });
  }
}

// Dynamically moves points on detail line chart based on what-if slider simulation
function updateChartData(soilVal, cropVal) {
  const soilChart = document.getElementById('soilChartLine');
  const moistureChart = document.getElementById('moistureChartLine');
  
  if (soilChart && moistureChart) {
    // Circumscribe values to fit SVG chart height (150px height, 0 offset is top)
    const newSoilY = 150 - (soilVal * 1.2);
    const newMoistureY = 150 - (cropVal * 1.2);

    // Get current line points
    const soilPoints = ["20,110", "63,95", "106,78", "150,90", "193,60", "236,45", `280,${newSoilY}`];
    const moisturePoints = ["20,95", "63,80", "106,85", "150,70", "193,55", "236,38", `280,${newMoistureY}`];

    soilChart.setAttribute("points", soilPoints.join(" "));
    moistureChart.setAttribute("points", moisturePoints.join(" "));

    // Move circles to active positions
    const dots = document.querySelectorAll('.chart-point');
    if (dots.length >= 2) {
      dots[0].setAttribute('cy', newSoilY);
      dots[1].setAttribute('cy', newMoistureY);
    }
  }
}

/* ==========================================================================
   5. SEARCH FILTER CHIPS
   ========================================================================== */
function initSearch() {
  const searchInput = document.getElementById('searchField');
  const resultsContainer = document.getElementById('searchResultsContainer');

  const defaultResults = [
    { title: "East Cotton Field", desc: "Planted: 42 days ago • Soil: Optimal", score: 85, badge: "high" },
    { title: "West Rice Crop", desc: "Planted: 15 days ago • Soil: Humid", score: 78, badge: "mid" },
    { title: "North Greenhouse", desc: "Planted: 120 days ago • Soil: Low Nitrogen", score: 52, badge: "low" }
  ];

  if (searchInput) {
    searchInput.addEventListener('input', () => {
      const query = searchInput.value.trim().toLowerCase();
      
      if (query === '') {
        renderSearchResults(defaultResults);
        return;
      }

      const filtered = defaultResults.filter(item => 
        item.title.toLowerCase().includes(query) || 
        item.desc.toLowerCase().includes(query)
      );

      renderSearchResults(filtered);
    });
  }

  function renderSearchResults(items) {
    if (!resultsContainer) return;
    resultsContainer.innerHTML = '';

    if (items.length === 0) {
      resultsContainer.innerHTML = `
        <div style="text-align: center; padding: 40px 20px; color: var(--text-secondary);">
          <i data-lucide="info" style="width: 36px; height: 36px; opacity: 0.6; margin-bottom: 8px;"></i>
          <p style="font-size: 13px; font-weight:600;">No matching plots or crop diseases found.</p>
        </div>
      `;
      lucide.createIcons();
      return;
    }

    items.forEach(item => {
      const card = document.createElement('div');
      card.className = "result-card ripple";
      card.onclick = () => switchScreen('detail');
      card.innerHTML = `
        <div class="result-details">
          <h4>${item.title}</h4>
          <p>${item.desc}</p>
        </div>
        <div class="result-health-badge ${item.badge}">${item.score}%</div>
      `;
      resultsContainer.appendChild(card);
    });
  }

  // Filter chips click handling
  document.querySelectorAll('.filter-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('.filter-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      triggerHapticFeedback();
    });
  });
}

/* ==========================================================================
   8. SETTINGS GATEWAY CONNECTION TESTER
   ========================================================================== */
function initConnectionTesting() {
  const testBtn = document.getElementById('testServerBtn');
  const statusBox = document.getElementById('connectionStatusBox');

  if (testBtn) {
    testBtn.addEventListener('click', () => {
      triggerHapticFeedback();
      const ip = document.getElementById('backendIpField').value.trim();

      testBtn.innerText = "Testing handshake...";
      testBtn.disabled = true;
      statusBox.style.display = 'none';

      setTimeout(() => {
        testBtn.innerText = "Test connection";
        testBtn.disabled = false;

        statusBox.style.display = 'block';
        if (ip === "192.168.1.120" || ip.startsWith("192.168")) {
          statusBox.className = "connection-status-msg success";
          statusBox.innerText = "Handshake Successful! Connected to Local Inference Hub.";
          triggerSuccessFeedback();
        } else {
          statusBox.className = "connection-status-msg danger";
          statusBox.innerText = "Connection Failed. Timeout or unreachable router IP.";
          triggerHapticFeedback();
        }
      }, 1500);
    });
  }
}

/* ==========================================================================
   9. NOTIFICATIONS PANEL DROP-DOWN OVERLAY
   ========================================================================== */
function toggleNotificationPanel() {
  triggerHapticFeedback();
  const panel = document.getElementById('notificationsPanel');
  if (panel) {
    panel.classList.toggle('active');
  }
}

/* ==========================================================================
   11. EMPTY STATES OVERLAY CONTROLLER
   ========================================================================== */
function showEmptyState() {
  triggerHapticFeedback();
  const element = document.getElementById('emptyStateOverlay');
  if (element) element.classList.add('active');
}

function closeEmptyState() {
  const element = document.getElementById('emptyStateOverlay');
  if (element) element.classList.remove('active');
}

/* ==========================================================================
   12. SKELETON LOADING CONTROLLER
   ========================================================================== */
function showLoadingState() {
  triggerHapticFeedback();
  const element = document.getElementById('loadingStateOverlay');
  if (element) element.classList.add('active');
}

function closeLoadingState() {
  const element = document.getElementById('loadingStateOverlay');
  if (element) element.classList.remove('active');
}

/* ==========================================================================
   13. ERROR STATE OVERLAY CONTROLLER
   ========================================================================== */
function showErrorState() {
  triggerHapticFeedback();
  const element = document.getElementById('errorStateOverlay');
  if (element) element.classList.add('active');
}

function closeErrorState() {
  const element = document.getElementById('errorStateOverlay');
  if (element) element.classList.remove('active');
}

function retryConnectionSimulation() {
  triggerHapticFeedback();
  const overlay = document.getElementById('errorStateOverlay');
  const card = overlay.querySelector('.error-card');
  
  // Add loading status to error popup
  card.innerHTML = `
    <div class="error-header">
      <i data-lucide="loader-2" class="error-badge-icon spin" style="color: var(--primary-color);"></i>
      <h4>Retrying Handshake...</h4>
    </div>
    <p class="error-msg">Connecting to on-field server logs. Please wait.</p>
  `;
  lucide.createIcons();

  setTimeout(() => {
    // Reset contents
    card.innerHTML = `
      <div class="error-header">
        <i data-lucide="cloud-off" class="error-badge-icon"></i>
        <h4>Connection Failure</h4>
      </div>
      <p class="error-msg">Failed to establish handshake with the Local Inference Hub at 192.168.1.120. Check connection status or router IP.</p>
      <div class="btn-group-row">
        <button class="btn-outlined ripple" onclick="closeErrorState()">Dismiss</button>
        <button class="btn-primary ripple" onclick="retryConnectionSimulation()">Retry Handshake</button>
      </div>
    `;
    lucide.createIcons();
    closeErrorState();
    triggerSuccessFeedback();
    alert("Connection established successfully!");
  }, 1800);
}

/* ==========================================================================
   IMAGE DIAGNOSTICS CAMERA PIPELINE SIMULATOR
   ========================================================================== */
function triggerScanSimulation() {
  triggerHapticFeedback();
  const overlay = document.getElementById('scanPipelineOverlay');
  const loader = document.getElementById('scanLoader');
  const results = document.getElementById('scanResultsCard');

  overlay.classList.add('active');
  loader.classList.remove('active');
  results.classList.remove('active');

  // Trigger auto-scan after 2 seconds
  setTimeout(() => {
    loader.classList.add('active');
    
    // Simulate AI scan processing
    setTimeout(() => {
      loader.classList.remove('active');
      results.classList.add('active');
      triggerSuccessFeedback();
    }, 2000);

  }, 2200);
}

function closeScanSimulation() {
  const overlay = document.getElementById('scanPipelineOverlay');
  if (overlay) overlay.classList.remove('active');
}

/* ==========================================================================
   THEME SYSTEMS (DARK & LIGHT MODE CONTROLS)
   ========================================================================== */
function initThemeToggles() {
  const globalToggleBtn = document.getElementById('themeToggleGlobal');
  const settingsToggleSwitch = document.getElementById('darkModeToggleSwitch');

  function setTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('agri-theme', theme);

    // Sync button and switch UI states
    if (theme === 'dark') {
      if (globalToggleBtn) globalToggleBtn.innerHTML = `<i data-lucide="sun"></i> Toggle Light Mode`;
      if (settingsToggleSwitch) settingsToggleSwitch.checked = true;
    } else {
      if (globalToggleBtn) globalToggleBtn.innerHTML = `<i data-lucide="moon"></i> Toggle Dark Mode`;
      if (settingsToggleSwitch) settingsToggleSwitch.checked = false;
    }
    lucide.createIcons();
  }

  // Check saved theme
  const savedTheme = localStorage.getItem('agri-theme') || 'light';
  setTheme(savedTheme);

  // Global button listener
  if (globalToggleBtn) {
    globalToggleBtn.addEventListener('click', () => {
      const current = document.documentElement.getAttribute('data-theme');
      setTheme(current === 'dark' ? 'light' : 'dark');
    });
  }

  // Settings screen switch listener
  if (settingsToggleSwitch) {
    settingsToggleSwitch.addEventListener('change', () => {
      setTheme(settingsToggleSwitch.checked ? 'dark' : 'light');
    });
  }
}

/* ==========================================================================
   TACTILE MICRO-INTERACTION (HAPTIC SIMULATION)
   ========================================================================== */
function triggerHapticFeedback() {
  const screen = document.getElementById('phoneScreen');
  if (screen) {
    screen.style.animation = 'none';
    // Trigger DOM reflow
    void screen.offsetWidth;
    // Apply quick vertical shake
    screen.style.animation = 'haptic-vibrate 0.1s ease-in-out';
  }
}

function triggerSuccessFeedback() {
  const screen = document.getElementById('phoneScreen');
  if (screen) {
    screen.style.animation = 'none';
    void screen.offsetWidth;
    // Apply double tap bounce
    screen.style.animation = 'haptic-success 0.25s cubic-bezier(.36,.07,.19,.97)';
  }
}

// Add vibration keyframes dynamically to stylesheet
const hapticStyles = document.createElement('style');
hapticStyles.innerHTML = `
  @keyframes haptic-vibrate {
    0%, 100% { transform: translateY(0); }
    33% { transform: translateY(-1.5px); }
    66% { transform: translateY(1.5px); }
  }
  @keyframes haptic-success {
    0%, 100% { transform: scale(1); }
    50% { transform: scale(1.015); border-color: var(--success-color); }
  }
  .spin {
    animation: spin 1.2s linear infinite;
  }
`;
document.head.appendChild(hapticStyles);
