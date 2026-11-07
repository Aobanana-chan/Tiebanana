@echo off
setlocal

pushd "%~dp0"
if errorlevel 1 exit /b 1

where flutter >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter was not found. Add the Flutter bin directory to PATH.
    popd
    exit /b 1
)

rem Extra arguments are forwarded, for example: --build-name=1.0.0 --build-number=2
call flutter build apk --release --split-per-abi %*
set "BUILD_EXIT_CODE=%ERRORLEVEL%"
if not "%BUILD_EXIT_CODE%"=="0" (
    echo [ERROR] Release APK build failed with exit code %BUILD_EXIT_CODE%.
    popd
    exit /b %BUILD_EXIT_CODE%
)

echo.
echo Release APKs: "%CD%\build\app\outputs\flutter-apk"
echo   app-armeabi-v7a-release.apk
echo   app-arm64-v8a-release.apk
echo   app-x86_64-release.apk

popd
exit /b 0
