try {
    Write-Host 'Cleaning Flutter project...'
    flutter clean
    Write-Host 'Cleaning complete!'
    
    Write-Host 'Getting dependencies...'
    flutter pub get
    Write-Host 'Getting complete!'
    
    Write-Host 'Running Flutter app...'
    flutter run -d chrome --profile
} catch {
    Write-Host 'Error: ' + $_.Exception.Message
    exit 1
}