using System;
using System.Windows.Media;
using ContrastChecker.Models;
using Xunit;

namespace ContrastChecker.Tests
{
    public class ColorModelTests
    {
        [Fact]
        public void Test1_DefaultInitialization_BlackVsWhite()
        {
            var model = new ColorModel();
            Assert.Equal("#000000", model.BgHex);
            Assert.Equal("#FFFFFF", model.FgHex);
            Assert.Equal(21.0, model.ContrastRatio, 2);
            Assert.Equal("21.00:1", model.ContrastRatioString);
        }

        [Fact]
        public void Test2_IdenticalColors_ShouldBeOneToOne()
        {
            var white = Color.FromRgb(255, 255, 255);
            var model = new ColorModel(white, white);
            Assert.Equal(1.0, model.ContrastRatio, 2);
            Assert.Equal("1.00:1", model.ContrastRatioString);
        }

        [Fact]
        public void Test3_ReferencePair_ShouldMatch()
        {
            var bgRef = ColorModel.ParseHex("#101631")!.Value;
            var fgRef = ColorModel.ParseHex("#FFFFFF")!.Value;
            var model = new ColorModel(bgRef, fgRef);

            Assert.Equal("#101631", model.BgHex);
            Assert.Equal("#FFFFFF", model.FgHex);
            Assert.Equal(17.78, model.ContrastRatio, 2);
            Assert.Equal("17.78", model.ContrastRatioValueOnly);
            Assert.Equal("17.78:1", model.ContrastRatioString);
        }

        [Fact]
        public void Test4_Symmetry_InvertedOrderYieldsIdenticalRatio()
        {
            var bgRef = ColorModel.ParseHex("#101631")!.Value;
            var fgRef = ColorModel.ParseHex("#FFFFFF")!.Value;

            var model1 = new ColorModel(bgRef, fgRef);
            var model2 = new ColorModel(fgRef, bgRef);

            Assert.Equal(model1.ContrastRatio, model2.ContrastRatio, 4);
        }

        [Fact]
        public void Test5_HexParsingAndFormatting()
        {
            var white = Color.FromRgb(255, 255, 255);
            var black = Color.FromRgb(0, 0, 0);
            var custom = Color.FromRgb(0x10, 0x16, 0x31);

            Assert.Equal("#FFFFFF", ColorModel.ColorToHex(white));
            Assert.Equal("#000000", ColorModel.ColorToHex(black));
            Assert.Equal("#101631", ColorModel.ColorToHex(custom));

            // 3-character shorthand
            var shortHex = ColorModel.ParseHex("#FFF");
            Assert.NotNull(shortHex);
            Assert.Equal("#FFFFFF", ColorModel.ColorToHex(shortHex.Value));

            // Invalid hex handling
            Assert.Null(ColorModel.ParseHex("invalid"));
            Assert.Null(ColorModel.ParseHex("#12"));
            Assert.Null(ColorModel.ParseHex(""));
        }
    }
}
