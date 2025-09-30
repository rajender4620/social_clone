@echo off
echo.
echo ================================================================
echo    🎃 PUMPKIN APP ICON INSTALLER 🎃
echo ================================================================
echo.
echo This script will help you install your new Pumpkin launcher icon.
echo.
echo STEP 1: Generate Icon Files
echo ----------------------------
echo You have 3 options:
echo.
echo Option A) Use the HTML Generator (EASIEST):
echo   1. The file 'icon_generator.html' should have opened in your browser
echo   2. If not, double-click 'icon_generator.html' to open it
echo   3. Click "🎨 Generate All Icons" button
echo   4. Right-click each generated icon and "Save image as..."
echo   5. Save them with the exact names shown
echo.
echo Option B) Use Online Converter:
echo   1. Go to: https://cloudconvert.com/svg-to-png
echo   2. Upload the 'app_icon.svg' file
echo   3. Generate different sizes: 48, 72, 96, 144, 192, 512, 1024
echo   4. Download and rename appropriately
echo.
echo Option C) Manual Creation:
echo   1. Open 'app_icon.svg' in any graphics program
echo   2. Export as PNG at different sizes
echo   3. Follow the naming convention in ICON_SETUP.md
echo.
echo STEP 2: Install Icon Files
echo --------------------------
echo Once you have the PNG files:
echo.
echo For Android:
echo   Copy ic_launcher.png files to:
echo   - android\app\src\main\res\mipmap-mdpi\    (48x48)
echo   - android\app\src\main\res\mipmap-hdpi\    (72x72)  
echo   - android\app\src\main\res\mipmap-xhdpi\   (96x96)
echo   - android\app\src\main\res\mipmap-xxhdpi\  (144x144)
echo   - android\app\src\main\res\mipmap-xxxhdpi\ (192x192)
echo.
echo For Web:
echo   Copy to web\icons\ folder:
echo   - Icon-192.png (192x192)
echo   - Icon-512.png (512x512)
echo   - favicon.png (32x32) goes in web\ folder
echo.
echo STEP 3: Rebuild and Test
echo ------------------------
echo Run these commands:
echo   flutter clean
echo   flutter pub get  
echo   flutter run
echo.
echo ================================================================
echo Your new Pumpkin icon will then appear on your device! 🎃
echo ================================================================
pause
