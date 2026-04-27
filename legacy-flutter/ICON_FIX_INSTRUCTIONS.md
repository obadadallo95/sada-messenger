# App Icon & Splash Screen Fix Instructions

## ⚠️ Important: Source Image Requirements

**The current `logo.png` may need padding adjustments for Adaptive Icons.**

### Adaptive Icon Safe Zone
- Android Adaptive Icons require a **safe zone** of **66%** of the image size
- The outer **17%** on each side can be cropped by the system
- **Recommendation:** Ensure your logo is centered and has at least **30% transparent padding** around it

### Current Status
- ✅ Configuration files updated
- ⚠️ **Action Required:** Check if `assets/images/logo.png` has proper padding

## Step 1: Verify Logo Padding

**Option A: If logo has NO padding (fills entire canvas)**
1. Open `assets/images/logo.png` in an image editor
2. Resize canvas to add **30% transparent padding** on all sides
3. Example: If logo is 512x512, resize canvas to ~730x730 (512 * 1.3)
4. Center the logo in the new canvas
5. Save as `assets/images/logo.png`

**Option B: If logo already has padding**
- ✅ You're good to go! Proceed to Step 2

## Step 2: Generate Icons

Run the following commands:

```bash
# Generate app icons (Adaptive Icons for Android)
flutter pub run flutter_launcher_icons

# Generate native splash screen
flutter pub run flutter_native_splash:create
```

## Step 3: Verify Results

1. **Check Adaptive Icon:**
   - Navigate to `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
   - Verify background color is `#050A14` (Deep Midnight Blue)
   - Check that foreground image is properly centered

2. **Check Splash Screen:**
   - Navigate to `android/app/src/main/res/drawable/launch_background.xml`
   - Verify background color is `#050A14`
   - Check that logo is centered

3. **Test on Device:**
   - Build and run the app
   - Verify app icon appears correctly (not cropped)
   - Verify splash screen shows Deep Midnight Blue background with centered logo
   - Check that there's no "double splash" (black -> teal transition)

## Configuration Summary

### App Icon (`flutter_launcher_icons`)
- **Background:** `#050A14` (Deep Midnight Blue)
- **Foreground:** `assets/images/logo.png`
- **Adaptive Icon:** Enabled
- **Min SDK:** 23 (Android 6.0+)

### Splash Screen (`flutter_native_splash`)
- **Color:** `#050A14` (Deep Midnight Blue)
- **Image:** `assets/images/logo.png`
- **Fullscreen:** Enabled
- **Android 12+:** Supported with matching background color

## Troubleshooting

### Issue: Logo still gets cropped
**Solution:** Add more padding to the source image (increase to 40% if needed)

### Issue: Double splash screen
**Solution:** The native splash screen should now match the Flutter splash screen color. If you still see a transition, ensure `SplashScreen` widget also uses `#050A14` background.

### Issue: Icon background is wrong color
**Solution:** Run `flutter clean` then regenerate icons:
```bash
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons
```

## Files Modified

1. ✅ `pubspec.yaml` - Updated icon and splash configurations
2. ✅ `android/app/src/main/res/values/colors.xml` - Updated `ic_launcher_background` to `#050A14`
3. ✅ `android/app/src/main/res/drawable/launch_background.xml` - Updated splash background
4. ✅ `android/app/src/main/res/drawable-v21/launch_background.xml` - Updated splash background
5. ✅ `android/app/src/main/res/values/styles.xml` - Updated LaunchTheme
6. ✅ `android/app/src/main/res/values-night/styles.xml` - Updated LaunchTheme

