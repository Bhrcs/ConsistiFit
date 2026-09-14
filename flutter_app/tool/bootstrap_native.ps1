$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

Write-Host 'Generating ConsistiFit Android and iOS platform shells...'
flutter create . --platforms=android,ios --project-name consistifit --org com.consistifit
python tool/configure_native.py
flutter pub get
flutter analyze
flutter test

Write-Host ''
Write-Host 'Native project files are ready.'
Write-Host 'Android: flutter run -d <android-device>'
Write-Host 'iOS: open ios/Runner.xcworkspace on a Mac, select your Apple team, then flutter run -d <iphone-device>'
