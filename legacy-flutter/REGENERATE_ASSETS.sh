#!/bin/bash
# Cyber-Stealth App Icon & Splash Screen Regeneration Script

echo "🎨 Regenerating App Icons and Splash Screen..."
echo ""

# Step 1: Generate App Icons
echo "📱 Step 1: Generating App Icons (Adaptive Icons)..."
dart run flutter_launcher_icons
echo ""

# Step 2: Generate Native Splash Screen
echo "🚀 Step 2: Generating Native Splash Screen..."
dart run flutter_native_splash:create
echo ""

echo "✅ Done! Icons and splash screen have been regenerated."
echo ""
echo "📋 Next Steps:"
echo "   1. Verify app icon appears correctly (not cropped)"
echo "   2. Test splash screen shows Deep Midnight Blue (#050A14)"
echo "   3. Check that there's no 'double splash' transition"
echo ""
