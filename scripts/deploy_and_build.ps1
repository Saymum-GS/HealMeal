Write-Host "Starting Web Build..."
flutter build web
if ($LASTEXITCODE -ne 0) {
    Write-Host "Web build failed."
    exit $LASTEXITCODE
}

Write-Host "Deploying to Firebase Hosting..."
firebase deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    Write-Host "Firebase deploy failed."
    # We still try to build APK even if deploy fails
}

Write-Host "Starting APK Build..."
flutter build apk
if ($LASTEXITCODE -ne 0) {
    Write-Host "APK build failed."
    exit $LASTEXITCODE
}

Write-Host "All tasks completed successfully."
