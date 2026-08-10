# App-specific R8 rules for the release build.
#
# Flutter, and each plugin that needs them, ship their own consumer rules, so
# this file is deliberately near-empty. Add keeps here only when a release
# build misbehaves in a way a debug build does not.

# mobile_scanner leans on ML Kit, whose optional model classes are resolved
# reflectively. Without this, R8 warns about missing text-recognition classes
# that the barcode-only dependency never bundles.
-dontwarn com.google.mlkit.vision.text.**
