/**
 * ColorModel for Contrast Checker (Web / Chromebook PWA).
 * Calculates WCAG 2.2 relative luminance and contrast ratios with full parity
 * to the macOS, Windows, and Linux native implementations.
 */
(function (root, factory) {
  if (typeof module === "object" && module.exports) {
    module.exports = factory();
  } else {
    root.ColorModel = factory();
  }
})(typeof globalThis !== "undefined" ? globalThis : this, function () {
  "use strict";

  class ColorModel {
    /**
     * @param {[number, number, number]} [background=[0, 0, 0]]
     * @param {[number, number, number]} [foreground=[255, 255, 255]]
     */
    constructor(background = [0, 0, 0], foreground = [255, 255, 255]) {
      this._bgR = ColorModel._clampByte(background[0]);
      this._bgG = ColorModel._clampByte(background[1]);
      this._bgB = ColorModel._clampByte(background[2]);

      this._fgR = ColorModel._clampByte(foreground[0]);
      this._fgG = ColorModel._clampByte(foreground[1]);
      this._fgB = ColorModel._clampByte(foreground[2]);

      /** @type {string | null} */
      this.copiedMessage = null;
      /** @type {Array<() => void>} */
      this._listeners = [];
    }

    /**
     * Register a callback for model state changes.
     * @param {() => void} listener
     */
    addListener(listener) {
      if (typeof listener === "function") {
        this._listeners.push(listener);
      }
    }

    _notify() {
      for (const listener of this._listeners) {
        listener();
      }
    }

    static _clampByte(val) {
      const n = Math.trunc(Number(val));
      if (Number.isNaN(n)) return 0;
      return Math.max(0, Math.min(255, n));
    }

    /** @returns {[number, number, number]} */
    get backgroundColor() {
      return [this._bgR, this._bgG, this._bgB];
    }

    /** @returns {[number, number, number]} */
    get foregroundColor() {
      return [this._fgR, this._fgG, this._fgB];
    }

    /** @returns {string} */
    get bgHex() {
      return ColorModel.hexStringFromRgb(this._bgR, this._bgG, this._bgB);
    }

    /** @returns {string} */
    get fgHex() {
      return ColorModel.hexStringFromRgb(this._fgR, this._fgG, this._fgB);
    }

    /**
     * @param {number} r
     * @param {number} g
     * @param {number} b
     */
    setBackgroundColor(r, g, b) {
      this._bgR = ColorModel._clampByte(r);
      this._bgG = ColorModel._clampByte(g);
      this._bgB = ColorModel._clampByte(b);
      this._notify();
    }

    /**
     * @param {number} r
     * @param {number} g
     * @param {number} b
     */
    setForegroundColor(r, g, b) {
      this._fgR = ColorModel._clampByte(r);
      this._fgG = ColorModel._clampByte(g);
      this._fgB = ColorModel._clampByte(b);
      this._notify();
    }

    /**
     * @param {string} hexCode
     * @returns {boolean}
     */
    setBackgroundHex(hexCode) {
      const rgb = ColorModel.colorFromHex(hexCode);
      if (rgb !== null) {
        this.setBackgroundColor(rgb[0], rgb[1], rgb[2]);
        return true;
      }
      return false;
    }

    /**
     * @param {string} hexCode
     * @returns {boolean}
     */
    setForegroundHex(hexCode) {
      const rgb = ColorModel.colorFromHex(hexCode);
      if (rgb !== null) {
        this.setForegroundColor(rgb[0], rgb[1], rgb[2]);
        return true;
      }
      return false;
    }

    /**
     * Math.floor with precision (from cstrobbe/contrast-ratio).
     * Truncates a number to the specified decimal places without rounding up.
     * @param {number} number
     * @param {number} [decimals=0]
     * @returns {number}
     */
    static floor(number, decimals = 0) {
      decimals = +decimals || 0;
      const multiplier = Math.pow(10, decimals);
      return Math.floor(number * multiplier) / multiplier;
    }

    /**
     * Unrounded WCAG contrast ratio ((L1 + 0.05) / (L2 + 0.05))
     * matching cstrobbe/contrast-ratio color.js.
     * @returns {number}
     */
    get preciseContrastRatio() {
      const l1 = ColorModel.relativeLuminance(this._bgR, this._bgG, this._bgB) + 0.05;
      const l2 = ColorModel.relativeLuminance(this._fgR, this._fgG, this._fgB) + 0.05;
      let ratio = l1 / l2;
      if (l2 > l1) {
        ratio = 1 / ratio;
      }
      return ratio;
    }

    /**
     * WCAG Contrast Ratio floored to 2 decimal places (matching cstrobbe/contrast-ratio).
     * @returns {number}
     */
    get contrastRatio() {
      return ColorModel.floor(this.preciseContrastRatio, 2);
    }

    /** @returns {string} */
    get contrastRatioString() {
      return `${this.contrastRatioValueOnly}:1`;
    }

    /** @returns {string} */
    get contrastRatioValueOnly() {
      return String(this.contrastRatio);
    }

    /**
     * Converts an sRGB component (0.0 to 1.0) to linear light
     * (matching cstrobbe/contrast-ratio color.js).
     * @param {number} val
     * @returns {number}
     */
    static srgbToLinear(val) {
      const clamped = Math.max(0.0, Math.min(1.0, val));
      return clamped < 0.03928
        ? clamped / 12.92
        : Math.pow((clamped + 0.055) / 1.055, 2.4);
    }

    /**
     * Computes relative luminance L in accordance with WCAG 2.2.
     * @param {number} r
     * @param {number} g
     * @param {number} b
     * @returns {number}
     */
    static relativeLuminance(r, g, b) {
      const rLin = ColorModel.srgbToLinear(r / 255.0);
      const gLin = ColorModel.srgbToLinear(g / 255.0);
      const bLin = ColorModel.srgbToLinear(b / 255.0);
      return 0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin;
    }

    /**
     * Formats RGB components (0-255) as an uppercase #RRGGBB string.
     * @param {number} r
     * @param {number} g
     * @param {number} b
     * @returns {string}
     */
    static hexStringFromRgb(r, g, b) {
      const toHex = (n) => ColorModel._clampByte(n).toString(16).toUpperCase().padStart(2, "0");
      return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
    }

    /**
     * Parses a 3-digit or 6-digit hex string (with or without leading '#') into [r, g, b].
     * Returns null if invalid.
     * @param {string} hexStr
     * @returns {[number, number, number] | null}
     */
    static colorFromHex(hexStr) {
      if (typeof hexStr !== "string") {
        return null;
      }
      const cleaned = hexStr.trim().replace(/^#+/, "");
      if (/^[0-9a-fA-F]{3}$/.test(cleaned)) {
        const r = parseInt(cleaned[0] + cleaned[0], 16);
        const g = parseInt(cleaned[1] + cleaned[1], 16);
        const b = parseInt(cleaned[2] + cleaned[2], 16);
        return [r, g, b];
      }
      if (/^[0-9a-fA-F]{6}$/.test(cleaned)) {
        const r = parseInt(cleaned.slice(0, 2), 16);
        const g = parseInt(cleaned.slice(2, 4), 16);
        const b = parseInt(cleaned.slice(4, 6), 16);
        return [r, g, b];
      }
      return null;
    }

    /**
     * Sets the transient copied feedback message.
     * @param {string} value
     * @param {string} label
     */
    copyValue(value, label) {
      this.copiedMessage = `Copied ${label}`;
      this._notify();
    }

    clearCopiedMessage() {
      if (this.copiedMessage !== null) {
        this.copiedMessage = null;
        this._notify();
      }
    }
  }

  return ColorModel;
});
