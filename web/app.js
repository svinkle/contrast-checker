/**
 * Contrast Checker — Web & Chromebook PWA Application Controller.
 * Connects ColorModel to DOM, system-wide Chromium EyeDropper API,
 * Clipboard API, keyboard shortcuts, and Service Worker registration.
 */
(function () {
  "use strict";

  const STORAGE_KEY_BG = "contrast_checker_bg_hex";
  const STORAGE_KEY_FG = "contrast_checker_fg_hex";

  const model = new window.ColorModel([0, 0, 0], [255, 255, 255]);

  // Restore last used colors if stored locally
  try {
    const savedBg = localStorage.getItem(STORAGE_KEY_BG);
    const savedFg = localStorage.getItem(STORAGE_KEY_FG);
    if (savedBg) model.setBackgroundHex(savedBg);
    if (savedFg) model.setForegroundHex(savedFg);
  } catch (_) {
    // Ignore storage errors in restricted contexts
  }

  // DOM Elements
  const rootStyle = document.documentElement.style;
  const themeColorMeta = document.getElementById("theme-color-meta");
  const closeBtn = document.getElementById("close-btn");
  const copyRatioBtn = document.getElementById("copy-ratio-btn");
  const ratioText = document.getElementById("ratio-text");
  const pickBgBtn = document.getElementById("pick-bg-btn");
  const pickFgBtn = document.getElementById("pick-fg-btn");
  const bgColorInput = document.getElementById("bg-color-input");
  const fgColorInput = document.getElementById("fg-color-input");
  const copyBgBtn = document.getElementById("copy-bg-btn");
  const copyFgBtn = document.getElementById("copy-fg-btn");
  const bgHexText = document.getElementById("bg-hex-text");
  const fgHexText = document.getElementById("fg-hex-text");
  const toastOverlay = document.getElementById("toast-overlay");
  const toastText = document.getElementById("toast-text");
  const installBanner = document.getElementById("pwa-install-banner");
  const installBtn = document.getElementById("install-pwa-btn");

  let toastTimerId = null;
  let activeEyeDropperAbort = null;
  let deferredInstallPrompt = null;

  /**
   * Updates the UI to reflect current ColorModel state.
   */
  function updateDisplay() {
    const bgHex = model.bgHex;
    const fgHex = model.fgHex;
    const ratioStr = model.contrastRatioString;

    rootStyle.setProperty("--bg-color", bgHex);
    rootStyle.setProperty("--fg-color", fgHex);

    if (themeColorMeta) {
      themeColorMeta.setAttribute("content", bgHex);
    }

    ratioText.textContent = ratioStr;
    copyRatioBtn.setAttribute(
      "aria-label",
      `Contrast ratio ${ratioStr}. Click to copy contrast ratio`
    );
    copyRatioBtn.setAttribute("title", `Click to copy contrast ratio (${ratioStr})`);

    bgHexText.textContent = bgHex;
    copyBgBtn.setAttribute("aria-label", `Background HEX ${bgHex}. Click to copy`);
    copyBgBtn.setAttribute("title", `Click to copy background HEX (${bgHex})`);
    bgColorInput.value = bgHex.toLowerCase();

    fgHexText.textContent = fgHex;
    copyFgBtn.setAttribute("aria-label", `Foreground HEX ${fgHex}. Click to copy`);
    copyFgBtn.setAttribute("title", `Click to copy foreground HEX (${fgHex})`);
    fgColorInput.value = fgHex.toLowerCase();

    try {
      localStorage.setItem(STORAGE_KEY_BG, bgHex);
      localStorage.setItem(STORAGE_KEY_FG, fgHex);
    } catch (_) {
      // Ignore storage errors
    }

    if (model.copiedMessage) {
      toastText.textContent = model.copiedMessage;
      toastOverlay.hidden = false;

      if (toastTimerId !== null) {
        clearTimeout(toastTimerId);
      }
      toastTimerId = setTimeout(() => {
        toastOverlay.hidden = true;
        toastTimerId = null;
        model.copiedMessage = null;
      }, 1500);
    } else {
      toastOverlay.hidden = true;
    }
  }

  /**
   * Copies text to the system clipboard with fallback support.
   * @param {string} text
   * @param {string} label
   */
  async function copyToClipboard(text, label) {
    try {
      if (navigator.clipboard && typeof navigator.clipboard.writeText === "function") {
        await navigator.clipboard.writeText(text);
      } else {
        const textarea = document.createElement("textarea");
        textarea.value = text;
        textarea.setAttribute("readonly", "");
        textarea.style.position = "fixed";
        textarea.style.opacity = "0";
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand("copy");
        document.body.removeChild(textarea);
      }
    } catch (_) {
      // Proceed to display feedback even if clipboard permission is restricted
    }
    model.copyValue(text, label);
  }

  /**
   * Samples a color from anywhere on screen using the Chromium EyeDropper API,
   * falling back to the native <input type="color"> picker on non-Chromium browsers.
   * @param {"bg" | "fg"} target
   */
  async function pickColor(target) {
    if ("EyeDropper" in window) {
      try {
        if (activeEyeDropperAbort) {
          activeEyeDropperAbort.abort();
        }
        const abortController = new AbortController();
        activeEyeDropperAbort = abortController;

        const eyeDropper = new window.EyeDropper();
        const result = await eyeDropper.open({ signal: abortController.signal });
        activeEyeDropperAbort = null;

        if (result && result.sRGBHex) {
          if (target === "bg") {
            model.setBackgroundHex(result.sRGBHex);
          } else {
            model.setForegroundHex(result.sRGBHex);
          }
        }
      } catch (_) {
        // User pressed Esc or canceled sampling
        activeEyeDropperAbort = null;
      }
      return;
    }

    // Fallback for browsers without EyeDropper API (Firefox / Safari)
    const fallbackInput = target === "bg" ? bgColorInput : fgColorInput;
    if (typeof fallbackInput.showPicker === "function") {
      try {
        fallbackInput.showPicker();
        return;
      } catch (_) {
        // Fall through to .click()
      }
    }
    fallbackInput.click();
  }

  /**
   * Closes standalone PWA window or resets colors to default black/white in a browser tab.
   */
  function handleCloseOrReset() {
    const isStandalone =
      window.matchMedia("(display-mode: standalone)").matches ||
      window.matchMedia("(display-mode: window-controls-overlay)").matches ||
      window.navigator.standalone === true;

    if (isStandalone) {
      window.close();
    }
    model.setBackgroundColor(0, 0, 0);
    model.setForegroundColor(255, 255, 255);
  }

  // Event Listeners
  model.addListener(updateDisplay);

  closeBtn.addEventListener("click", handleCloseOrReset);

  copyRatioBtn.addEventListener("click", () => {
    copyToClipboard(model.contrastRatioString, model.contrastRatioString);
  });

  copyBgBtn.addEventListener("click", () => {
    copyToClipboard(model.bgHex, model.bgHex);
  });

  copyFgBtn.addEventListener("click", () => {
    copyToClipboard(model.fgHex, model.fgHex);
  });

  pickBgBtn.addEventListener("click", () => {
    pickColor("bg");
  });

  pickFgBtn.addEventListener("click", () => {
    pickColor("fg");
  });

  bgColorInput.addEventListener("input", (event) => {
    model.setBackgroundHex(event.target.value);
  });

  fgColorInput.addEventListener("input", (event) => {
    model.setForegroundHex(event.target.value);
  });

  // Keyboard Shortcuts (matching macOS, Windows, and Linux)
  window.addEventListener("keydown", (event) => {
    const key = event.key.toLowerCase();
    const ctrlOrMeta = event.ctrlKey || event.metaKey;
    const alt = event.altKey;

    // Pick Background: Ctrl+Alt+B or Alt+B
    if (key === "b" && (alt || (ctrlOrMeta && alt))) {
      event.preventDefault();
      pickColor("bg");
      return;
    }

    // Pick Foreground: Ctrl+Alt+F or Alt+F
    if (key === "f" && (alt || (ctrlOrMeta && alt))) {
      event.preventDefault();
      pickColor("fg");
      return;
    }

    // Escape: Cancel active eyedropper or clear focus / close standalone window
    if (event.key === "Escape") {
      if (activeEyeDropperAbort) {
        activeEyeDropperAbort.abort();
        activeEyeDropperAbort = null;
        return;
      }
      if (document.activeElement && document.activeElement !== document.body) {
        document.activeElement.blur();
        return;
      }
      handleCloseOrReset();
    }
  });

  // Support pasting a HEX color code directly into the window (Ctrl+V / Cmd+V)
  window.addEventListener("paste", (event) => {
    const text = event.clipboardData ? event.clipboardData.getData("text") : "";
    const rgb = window.ColorModel.colorFromHex(text);
    if (rgb !== null) {
      event.preventDefault();
      if (
        document.activeElement === copyFgBtn ||
        document.activeElement === pickFgBtn
      ) {
        model.setForegroundColor(rgb[0], rgb[1], rgb[2]);
      } else {
        model.setBackgroundColor(rgb[0], rgb[1], rgb[2]);
      }
    }
  });

  // Size standalone PWA window compactly on launch if permitted by browser
  if (
    window.matchMedia("(display-mode: standalone)").matches ||
    window.matchMedia("(display-mode: window-controls-overlay)").matches
  ) {
    try {
      if (window.outerWidth > 420 || window.outerHeight > 360) {
        window.resizeTo(340, 288);
      }
    } catch (_) {
      // Ignore if window resizing is restricted
    }
  }

  // Handle PWA Install Prompt (shown in browser tabs when installable)
  window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault();
    deferredInstallPrompt = event;
    if (installBanner) {
      installBanner.hidden = false;
    }
  });

  if (installBtn) {
    installBtn.addEventListener("click", async () => {
      if (!deferredInstallPrompt) return;
      deferredInstallPrompt.prompt();
      try {
        await deferredInstallPrompt.userChoice;
      } catch (_) {
        // Ignore prompt dismissal
      }
      deferredInstallPrompt = null;
      installBanner.hidden = true;
    });
  }

  window.addEventListener("appinstalled", () => {
    deferredInstallPrompt = null;
    if (installBanner) {
      installBanner.hidden = true;
    }
  });

  // Register Service Worker for offline Chromebook PWA support
  if ("serviceWorker" in navigator) {
    window.addEventListener("load", () => {
      navigator.serviceWorker.register("./sw.js").catch(() => {
        // Service worker registration may fail on file:// protocol during local file opening
      });
    });
  }

  // Initial render
  updateDisplay();

  // Handle PWA launcher shortcuts (?pick=bg or ?pick=fg)
  try {
    const params = new URLSearchParams(window.location.search);
    const pickTarget = params.get("pick");
    if (pickTarget === "bg" && pickBgBtn) {
      pickBgBtn.focus();
    } else if (pickTarget === "fg" && pickFgBtn) {
      pickFgBtn.focus();
    }
  } catch (_) {
    // Ignore URL parsing errors
  }
})();
