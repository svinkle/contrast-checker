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
  const copyRatioBtn = document.getElementById("copy-ratio-btn");
  const ratioText = document.getElementById("ratio-text");
  const pickBgBtn = document.getElementById("pick-bg-btn");
  const pickFgBtn = document.getElementById("pick-fg-btn");
  const editBgBtn = document.getElementById("edit-bg-btn");
  const editFgBtn = document.getElementById("edit-fg-btn");
  const bgColorInput = document.getElementById("bg-color-input");
  const fgColorInput = document.getElementById("fg-color-input");
  const copyBgBtn = document.getElementById("copy-bg-btn");
  const copyFgBtn = document.getElementById("copy-fg-btn");
  const bgHexText = document.getElementById("bg-hex-text");
  const fgHexText = document.getElementById("fg-hex-text");
  const bgHexInput = document.getElementById("bg-hex-input");
  const fgHexInput = document.getElementById("fg-hex-input");
  const toastOverlay = document.getElementById("toast-overlay");
  const toastText = document.getElementById("toast-text");
  const installBanner = document.getElementById("pwa-install-banner");
  const installBtn = document.getElementById("install-pwa-btn");

  let toastTimerId = null;
  let activeEyeDropperAbort = null;
  let deferredInstallPrompt = null;
  let bgInitialHex = "#000000";
  let fgInitialHex = "#FFFFFF";
  let bgEditFinished = false;
  let fgEditFinished = false;

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
    if (editBgBtn) {
      editBgBtn.setAttribute("title", `Click to edit background HEX (${bgHex})`);
    }
    bgColorInput.value = bgHex.toLowerCase();

    fgHexText.textContent = fgHex;
    copyFgBtn.setAttribute("aria-label", `Foreground HEX ${fgHex}. Click to copy`);
    copyFgBtn.setAttribute("title", `Click to copy foreground HEX (${fgHex})`);
    if (editFgBtn) {
      editFgBtn.setAttribute("title", `Click to edit foreground HEX (${fgHex})`);
    }
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

  // Event Listeners
  model.addListener(updateDisplay);

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

  // Inline HEX Editing via Swatch Click
  function startHexEdit(target) {
    if (target === "bg") {
      if (fgHexInput && !fgHexInput.hidden) {
        commitHexEdit("fg");
      }
      bgInitialHex = model.bgHex;
      bgEditFinished = false;
      bgHexInput.value = model.bgHex;
      copyBgBtn.hidden = true;
      bgHexInput.hidden = false;
      bgHexInput.focus();
      bgHexInput.select();
    } else {
      if (bgHexInput && !bgHexInput.hidden) {
        commitHexEdit("bg");
      }
      fgInitialHex = model.fgHex;
      fgEditFinished = false;
      fgHexInput.value = model.fgHex;
      copyFgBtn.hidden = true;
      fgHexInput.hidden = false;
      fgHexInput.focus();
      fgHexInput.select();
    }
  }

  function handleLiveHexInput(target, value) {
    const raw = String(value).trim();
    const cleaned = raw.startsWith("#") ? raw.slice(1) : raw;
    if (cleaned.length === 6 && window.ColorModel.colorFromHex(cleaned) !== null) {
      if (target === "bg") {
        model.setBackgroundHex(cleaned);
      } else {
        model.setForegroundHex(cleaned);
      }
    }
  }

  function commitHexEdit(target) {
    if (target === "bg") {
      if (bgEditFinished || !bgHexInput || bgHexInput.hidden) return;
      bgEditFinished = true;
      const val = bgHexInput.value.trim();
      if (window.ColorModel.colorFromHex(val) !== null) {
        model.setBackgroundHex(val);
      } else {
        model.setBackgroundHex(bgInitialHex);
      }
      bgHexInput.hidden = true;
      copyBgBtn.hidden = false;
    } else {
      if (fgEditFinished || !fgHexInput || fgHexInput.hidden) return;
      fgEditFinished = true;
      const val = fgHexInput.value.trim();
      if (window.ColorModel.colorFromHex(val) !== null) {
        model.setForegroundHex(val);
      } else {
        model.setForegroundHex(fgInitialHex);
      }
      fgHexInput.hidden = true;
      copyFgBtn.hidden = false;
    }
  }

  function cancelHexEdit(target) {
    if (target === "bg") {
      if (bgEditFinished || !bgHexInput || bgHexInput.hidden) return;
      bgEditFinished = true;
      model.setBackgroundHex(bgInitialHex);
      bgHexInput.hidden = true;
      copyBgBtn.hidden = false;
      if (editBgBtn) editBgBtn.focus();
    } else {
      if (fgEditFinished || !fgHexInput || fgHexInput.hidden) return;
      fgEditFinished = true;
      model.setForegroundHex(fgInitialHex);
      fgHexInput.hidden = true;
      copyFgBtn.hidden = false;
      if (editFgBtn) editFgBtn.focus();
    }
  }

  if (editBgBtn) {
    editBgBtn.addEventListener("click", () => startHexEdit("bg"));
  }
  if (editFgBtn) {
    editFgBtn.addEventListener("click", () => startHexEdit("fg"));
  }

  if (bgHexInput) {
    bgHexInput.addEventListener("input", (e) => handleLiveHexInput("bg", e.target.value));
    bgHexInput.addEventListener("blur", () => commitHexEdit("bg"));
    bgHexInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        commitHexEdit("bg");
      } else if (e.key === "Escape") {
        e.preventDefault();
        e.stopPropagation();
        cancelHexEdit("bg");
      }
    });
  }

  if (fgHexInput) {
    fgHexInput.addEventListener("input", (e) => handleLiveHexInput("fg", e.target.value));
    fgHexInput.addEventListener("blur", () => commitHexEdit("fg"));
    fgHexInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        commitHexEdit("fg");
      } else if (e.key === "Escape") {
        e.preventDefault();
        e.stopPropagation();
        cancelHexEdit("fg");
      }
    });
  }

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

    // Escape: Cancel active eyedropper or clear focus
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
    }
  });

  // Support pasting a HEX color code directly into the window (Ctrl+V / Cmd+V)
  window.addEventListener("paste", (event) => {
    if (document.activeElement === bgHexInput || document.activeElement === fgHexInput) {
      return;
    }
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
