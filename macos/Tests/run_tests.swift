import AppKit
import Foundation

@main
struct TestRunner {
    static func main() {
        print("==> Running ColorModel Tests...")

        // Test 1: Default initialization (#000000 vs #FFFFFF)
        let defaultModel = ColorModel()
        assertEqual(defaultModel.bgHex, "#000000")
        assertEqual(defaultModel.fgHex, "#FFFFFF")
        assertAlmostEqual(defaultModel.contrastRatio, 21.0, accuracy: 0.01, "Default Black vs White should be 21:1")
        assertEqual(defaultModel.contrastRatioString, "21:1")

        // Test 2: Custom Black vs White
        let black = NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        let white = NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        let modelBW = ColorModel(background: black, foreground: white)
        assertAlmostEqual(modelBW.contrastRatio, 21.0, accuracy: 0.01, "Black vs White should be 21:1")
        assertEqual(modelBW.contrastRatioString, "21:1")

        // Test 2: Identical colors
        let modelSame = ColorModel(background: white, foreground: white)
        assertAlmostEqual(modelSame.contrastRatio, 1.0, accuracy: 0.01, "Identical colors should be 1:1")
        assertEqual(modelSame.contrastRatioString, "1:1")

        // Test 3: Reference Screenshot (#101631 vs #FFFFFF)
        let bgReference = ColorModel.color(fromHex: "#101631")!
        let fgReference = ColorModel.color(fromHex: "#FFFFFF")!
        let modelRef = ColorModel(background: bgReference, foreground: fgReference)
        assertEqual(modelRef.bgHex, "#101631")
        assertEqual(modelRef.fgHex, "#FFFFFF")
        assertAlmostEqual(modelRef.contrastRatio, 17.77, accuracy: 0.001, "Reference colors should match 17.77")
        assertEqual(modelRef.contrastRatioValueOnly, "17.77")
        assertEqual(modelRef.contrastRatioString, "17.77:1")

        // Test 3b: #D7D7D7 on #FFFFFF -> 1.43:1 (cstrobbe/contrast-ratio floor parity)
        let fgD7 = ColorModel.color(fromHex: "#D7D7D7")!
        let modelD7 = ColorModel(background: fgReference, foreground: fgD7)
        assertAlmostEqual(modelD7.contrastRatio, 1.43, accuracy: 0.001, "#D7D7D7 on #FFFFFF should floor to 1.43")
        assertEqual(modelD7.contrastRatioValueOnly, "1.43")
        assertEqual(modelD7.contrastRatioString, "1.43:1")

        // Test 3c: #6F1C96 on #FFFFFF -> 9.2:1 (including unquantized NSColor float components)
        let fgPurple = NSColor(srgbRed: 111.35 / 255.0, green: 28.25 / 255.0, blue: 150.4 / 255.0, alpha: 1.0)
        let bgNearWhite = NSColor(srgbRed: 254.6 / 255.0, green: 254.6 / 255.0, blue: 254.6 / 255.0, alpha: 1.0)
        let modelPurple = ColorModel(background: bgNearWhite, foreground: fgPurple)
        assertEqual(modelPurple.bgHex, "#FFFFFF")
        assertEqual(modelPurple.fgHex, "#6F1C96")
        assertAlmostEqual(modelPurple.contrastRatio, 9.2, accuracy: 0.001, "#6F1C96 on #FFFFFF should be 9.2")
        assertEqual(modelPurple.contrastRatioValueOnly, "9.2")
        assertEqual(modelPurple.contrastRatioString, "9.2:1")

        // Test 4: Inverted order yields identical ratio
        let modelRefInv = ColorModel(background: fgReference, foreground: bgReference)
        assertAlmostEqual(modelRefInv.contrastRatio, 17.77, accuracy: 0.001, "Inverting colors should give same ratio")

        // Test 5: Hex Parsing & Formatting
        assertEqual(ColorModel.hexString(from: white), "#FFFFFF")
        assertEqual(ColorModel.hexString(from: black), "#000000")
        assertEqual(ColorModel.hexString(from: bgReference), "#101631")

        // 3-char shorthand
        let shortHexColor = ColorModel.color(fromHex: "#FFF")
        assertEqual(ColorModel.hexString(from: shortHexColor!), "#FFFFFF")

        // Invalid hex
        assertEqual(ColorModel.color(fromHex: "invalid"), nil)
        assertEqual(ColorModel.color(fromHex: "#12"), nil)

        // Test 6: Direct HEX Editing (#828410 and #9a3776)
        let editModel = ColorModel()
        editModel.setBackgroundHex("#ffffff")
        editModel.setForegroundHex("828410")
        assertEqual(editModel.bgHex, "#FFFFFF")
        assertEqual(editModel.fgHex, "#828410")
        assertEqual(editModel.contrastRatioString, "3.99:1")

        editModel.setForegroundHex("#9a3776")
        assertEqual(editModel.fgHex, "#9A3776")
        assertEqual(editModel.contrastRatioString, "6.59:1")

        print("==> All ColorModel tests PASSED successfully! (7 test suites)")
    }

    static func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "") {
        if actual != expected {
            print("FAIL: Expected \(expected), got \(actual). \(message)")
            exit(1)
        }
    }

    static func assertAlmostEqual(_ actual: Double, _ expected: Double, accuracy: Double = 0.01, _ message: String = "") {
        if abs(actual - expected) > accuracy {
            print("FAIL: Expected \(expected) ± \(accuracy), got \(actual). \(message)")
            exit(1)
        }
    }
}

