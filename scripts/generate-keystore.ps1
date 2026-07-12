# Run this script to generate a release keystore for Android signing.
# Prerequisite: Java JDK (keytool) must be installed and on your PATH.
#
# IMPORTANT: Passwords are read from environment variables for security.
# Set these before running:
#   $env:KEYSTORE_PASSWORD = "your-secure-password"
#   $env:KEY_PASSWORD = "your-secure-password"
# Or edit this file and replace the $env: references with your values.

$keystorePath = Join-Path $PSScriptRoot "..\android\release-keystore.jks"
$alias = "ironbook"
$storepass = $env:KEYSTORE_PASSWORD
$keypass = $env:KEY_PASSWORD
$dname = "CN=IronBook, OU=Dev, O=IronBook, L=City, ST=State, C=IN"

if (-not $storepass -or -not $keypass) {
  Write-Host "ERROR: Set KEYSTORE_PASSWORD and KEY_PASSWORD environment variables first." -ForegroundColor Red
  Write-Host "Example:" -ForegroundColor Yellow
  Write-Host '  $env:KEYSTORE_PASSWORD = "your-secure-password"' -ForegroundColor Yellow
  Write-Host '  $env:KEY_PASSWORD = "your-secure-password"' -ForegroundColor Yellow
  exit 1
}

& keytool -genkey -v `
  -keystore $keystorePath `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias $alias `
  -storepass $storepass -keypass $keypass `
  -dname $dname

if ($?) {
  Write-Host "Keystore generated at: $keystorePath" -ForegroundColor Green
  Write-Host ""
  Write-Host "NEXT: Create android/key.properties with:" -ForegroundColor Cyan
  Write-Host "  storePassword=$storepass" -ForegroundColor White
  Write-Host "  keyPassword=$keypass" -ForegroundColor White
  Write-Host "  keyAlias=$alias" -ForegroundColor White
  Write-Host "  storeFile=release-keystore.jks" -ForegroundColor White
  Write-Host ""
  Write-Host "WARNING: key.properties is in .gitignore -- keep it secret!" -ForegroundColor Red
} else {
  Write-Host "Failed to generate keystore. Make sure Java JDK is installed." -ForegroundColor Red
}
