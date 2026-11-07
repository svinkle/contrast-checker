/**
 * Automated Unit Tests for Contrast Checker Web / Chromebook PWA.
 * Verifies WCAG 2.2 luminance, contrast ratio parity, hex parsing,
 * and PWA manifest / asset completeness using Node's built-in assert module.
 */
"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const ColorModel = require("../color-model.js");

let passed = 0;

function runTest(name, fn) {
  fn();
  passed += 1;
  console.log(`  ✓ ${name}`);
}

console.log("Running Contrast Checker Web / PWA unit tests...");

runTest("default initialization (#000000 vs #FFFFFF -> 21:1)", () => {
  const model = new ColorModel();
  assert.equal(model.bgHex, "#000000");
  assert.equal(model.fgHex, "#FFFFFF");
  assert.ok(Math.abs(model.contrastRatio - 21.0) < 0.001);
  assert.equal(model.contrastRatioString, "21:1");
  assert.equal(model.contrastRatioValueOnly, "21");
});

runTest("identical colors yield 1:1", () => {
  const model = new ColorModel([255, 255, 255], [255, 255, 255]);
  assert.ok(Math.abs(model.contrastRatio - 1.0) < 0.001);
  assert.equal(model.contrastRatioString, "1:1");
});

runTest("reference pair (#101631 vs #FFFFFF -> 17.77:1) matches native apps", () => {
  const model = new ColorModel();
  assert.equal(model.setBackgroundHex("#101631"), true);
  assert.equal(model.setForegroundHex("#FFFFFF"), true);
  assert.equal(model.bgHex, "#101631");
  assert.equal(model.fgHex, "#FFFFFF");
  assert.equal(model.contrastRatio, 17.77);
  assert.equal(model.contrastRatioValueOnly, "17.77");
  assert.equal(model.contrastRatioString, "17.77:1");
});

runTest("#D7D7D7 on #FFFFFF floors to 1.43:1 (cstrobbe/contrast-ratio parity)", () => {
  const model = new ColorModel();
  assert.equal(model.setBackgroundHex("#FFFFFF"), true);
  assert.equal(model.setForegroundHex("#D7D7D7"), true);
  assert.equal(model.contrastRatio, 1.43);
  assert.equal(model.contrastRatioValueOnly, "1.43");
  assert.equal(model.contrastRatioString, "1.43:1");
});

runTest("#6F1C96 on #FFFFFF yields 9.2:1 (cstrobbe/contrast-ratio parity)", () => {
  const model = new ColorModel();
  assert.equal(model.setBackgroundHex("#FFFFFF"), true);
  assert.equal(model.setForegroundHex("#6F1C96"), true);
  assert.equal(model.contrastRatio, 9.2);
  assert.equal(model.contrastRatioValueOnly, "9.2");
  assert.equal(model.contrastRatioString, "9.2:1");
});

runTest("symmetry: inverted foreground/background yields identical contrast ratio", () => {
  const model1 = new ColorModel([16, 22, 49], [255, 255, 255]);
  const model2 = new ColorModel([255, 255, 255], [16, 22, 49]);
  assert.ok(Math.abs(model1.contrastRatio - model2.contrastRatio) < 0.0001);
});

runTest("hex parsing and formatting (6-digit, 3-digit shorthand, and invalid)", () => {
  assert.deepEqual(ColorModel.colorFromHex("#FFFFFF"), [255, 255, 255]);
  assert.deepEqual(ColorModel.colorFromHex("#000000"), [0, 0, 0]);
  assert.deepEqual(ColorModel.colorFromHex("#101631"), [16, 22, 49]);
  assert.deepEqual(ColorModel.colorFromHex("101631"), [16, 22, 49]);

  // 3-char shorthand (#FFF -> #FFFFFF)
  assert.deepEqual(ColorModel.colorFromHex("#FFF"), [255, 255, 255]);
  assert.deepEqual(ColorModel.colorFromHex("000"), [0, 0, 0]);
  assert.deepEqual(ColorModel.colorFromHex("#abc"), [170, 187, 204]);

  // Invalid hex
  assert.equal(ColorModel.colorFromHex("invalid"), null);
  assert.equal(ColorModel.colorFromHex("#12"), null);
  assert.equal(ColorModel.colorFromHex("#12345"), null);
  assert.equal(ColorModel.colorFromHex(null), null);
});

runTest("copyValue and clearCopiedMessage notify listeners", () => {
  const model = new ColorModel();
  let notifications = 0;
  model.addListener(() => {
    notifications += 1;
  });

  model.copyValue(model.bgHex, model.bgHex);
  assert.equal(model.copiedMessage, "Copied #000000");
  assert.equal(notifications, 1);

  model.clearCopiedMessage();
  assert.equal(model.copiedMessage, null);
  assert.equal(notifications, 2);
});

runTest("PWA manifest and cached assets exist on disk", () => {
  const webRoot = path.resolve(__dirname, "..");
  const manifestPath = path.join(webRoot, "manifest.webmanifest");
  assert.ok(fs.existsSync(manifestPath), "manifest.webmanifest must exist");

  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  assert.equal(manifest.name, "Contrast Checker");
  assert.equal(manifest.display, "standalone");
  assert.ok(Array.isArray(manifest.icons) && manifest.icons.length >= 8);

  for (const icon of manifest.icons) {
    const iconFile = path.join(webRoot, icon.src);
    assert.ok(fs.existsSync(iconFile), `Missing icon referenced in manifest: ${icon.src}`);
  }
});

console.log(`All ${passed} tests passed!`);
