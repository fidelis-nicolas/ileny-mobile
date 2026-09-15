/**
 * iOS app icon + launch mark generator — ileny.
 *
 * The iOS target shipped with the stock Flutter template icons. This renders
 * the real brand mark into every slot `Assets.xcassets` asks for, from the same
 * SVG the app itself draws (`assets/icons/ileny_favicon.svg` — the heavier of
 * the two marks, which is the one that survives being scaled down to 20pt).
 *
 * Two rules the App Store enforces that this bakes in:
 *   - the icon must be fully opaque, so it is flattened onto the background
 *     colour rather than left with an alpha channel;
 *   - no rounded corners of our own — iOS applies the mask, and pre-rounding
 *     produces a visible double corner.
 *
 * The launch mark is the opposite: transparent, because LaunchScreen.storyboard
 * paints the background from the LaunchBackground colour set so it can follow
 * light/dark. It gets a dark variant where the deep green is lifted to
 * primary300, exactly as AppColors.dark does for the same reason — the 600 is
 * unreadable against the ink background.
 *
 * Run from the repo root (sharp lives in the marketing front end, as it does
 * for the Play Store scripts here):
 *   node store/ios/generate-ios-icons.js
 */
const fs = require("fs");
const path = require("path");

const sharp = (() => {
  try {
    return require("sharp");
  } catch {
    // Same source the store/play generators use; nothing in the Flutter app
    // depends on node, so there is no package.json here to install into.
    return require("C:/Users/fidel/Desktop/mypeople/front-end/marketing/node_modules/sharp");
  }
})();

const ROOT = path.resolve(__dirname, "..", "..");
const SVG = path.join(ROOT, "assets", "icons", "ileny_favicon.svg");
const ICONSET = path.join(ROOT, "ios/Runner/Assets.xcassets/AppIcon.appiconset");
const LAUNCHSET = path.join(ROOT, "ios/Runner/Assets.xcassets/LaunchImage.imageset");

// AppColors: light/dark background, primary600 arc, primary300 arc in the dark.
const ICON_BG = "#F7F5F0"; // matches android ic_launcher_background
const PRIMARY_600 = "#22483A";
const PRIMARY_300 = "#7FA695";

/** The mark, optionally recoloured for a dark background. */
function markSvg(dark) {
  const svg = fs.readFileSync(SVG, "utf8");
  return dark ? svg.split(PRIMARY_600).join(PRIMARY_300) : svg;
}

/**
 * Renders the mark `width` px wide, trimmed to the ink.
 *
 * The trim is the point: inside its 64-unit viewBox the mark's drawn area runs
 * y 12.5–56.5, so its optical centre sits 4% below the box centre. Composited
 * by the box it lands visibly low in the icon and, because a fifth of the box
 * is empty, several sizes smaller than it looks. Cropping to the ink first
 * makes "centred" and "62% of the canvas" mean what they say.
 */
async function renderMark({ width, dark = false }) {
  return sharp(Buffer.from(markSvg(dark)), { density: 1200 })
    .trim({ threshold: 0 })
    .resize({ width, fit: "inside", withoutEnlargement: false })
    .png()
    .toBuffer();
}

/**
 * App icon: mark at 62% of the canvas width, centred, flattened onto the
 * background.
 *
 * 62% reads as the same weight as the Android adaptive icon, whose 108dp canvas
 * reserves a 72dp safe zone (66%) that the launcher then crops further into.
 * Nothing rounds the corners here — iOS applies its own mask, and a pre-rounded
 * icon shows a double corner on the home screen.
 */
async function appIcon(size) {
  const mark = await renderMark({ width: Math.round(size * 0.62) });
  return sharp({
    create: {
      width: size,
      height: size,
      channels: 4,
      background: ICON_BG,
    },
  })
    .composite([{ input: mark, gravity: "centre" }])
    .flatten({ background: ICON_BG }) // App Store: no alpha channel
    .png({ compressionLevel: 9 })
    .toBuffer();
}

// Every slot listed in AppIcon.appiconset/Contents.json, keyed by file name so
// the two cannot drift apart silently.
const ICONS = {
  "Icon-App-20x20@1x.png": 20,
  "Icon-App-20x20@2x.png": 40,
  "Icon-App-20x20@3x.png": 60,
  "Icon-App-29x29@1x.png": 29,
  "Icon-App-29x29@2x.png": 58,
  "Icon-App-29x29@3x.png": 87,
  "Icon-App-40x40@1x.png": 40,
  "Icon-App-40x40@2x.png": 80,
  "Icon-App-40x40@3x.png": 120,
  "Icon-App-60x60@2x.png": 120,
  "Icon-App-60x60@3x.png": 180,
  "Icon-App-76x76@1x.png": 76,
  "Icon-App-76x76@2x.png": 152,
  "Icon-App-83.5x83.5@2x.png": 167,
  "Icon-App-1024x1024@1x.png": 1024,
};

// 96pt wide, which the storyboard centres. Big enough to read on the smallest
// iPhone, small enough not to look stranded on an iPad. It is not sized to match
// the sign-in screen's mark: that one sits near the top of the screen, so the
// handover moves it whatever size it is.
const LAUNCH_PT = 96;
const LAUNCH = {
  "LaunchImage.png": { scale: 1, dark: false },
  "LaunchImage@2x.png": { scale: 2, dark: false },
  "LaunchImage@3x.png": { scale: 3, dark: false },
  "LaunchImage-Dark.png": { scale: 1, dark: true },
  "LaunchImage-Dark@2x.png": { scale: 2, dark: true },
  "LaunchImage-Dark@3x.png": { scale: 3, dark: true },
};

async function main() {
  for (const [name, size] of Object.entries(ICONS)) {
    fs.writeFileSync(path.join(ICONSET, name), await appIcon(size));
    console.log(`icon  ${name.padEnd(30)} ${size}x${size}`);
  }
  for (const [name, { scale, dark }] of Object.entries(LAUNCH)) {
    const size = LAUNCH_PT * scale;
    fs.writeFileSync(path.join(LAUNCHSET, name), await renderMark({ width: size, dark }));
    console.log(`launch ${name.padEnd(29)} ${size}x${size}`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
