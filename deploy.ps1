Write-Host "Running flutter clean..."
flutter clean
Write-Host "Running flutter pub get..."
flutter pub get
Write-Host "Building APK..."
flutter build apk
Write-Host "Building Web..."
flutter build web
Write-Host "Deploying Firebase rules and indexes..."
firebase deploy --only firestore:rules,firestore:indexes
Write-Host "Deploying Web App to Firebase Hosting..."
firebase deploy --only hosting
Write-Host "Deployment completed successfully!"
