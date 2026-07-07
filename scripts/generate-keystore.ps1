# Run this script to generate a release keystore for Android signing.
# Prerequisite: Java JDK (keytool) must be installed and on your PATH.

$keystorePath = Join-Path $PSScriptRoot "..\android\release-keystore.jks"
$alias = "ironbook"
$storepass = "ironbook123"
$keypass = "ironbook123"
$dname = "CN=IronBook, OU=Dev, O=IronBook, L=City, ST=State, C=IN"

& keytool -genkey -v `
  -keystore $keystorePath `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias $alias `
  -storepass $storepass -keypass $keypass `
  -dname $dname

if ($?) {
  Write-Host "Keystore generated at: $keystorePath" -ForegroundColor Green
  Write-Host "StorePassword/KeyPassword: $storepass" -ForegroundColor Yellow
  Write-Host "Alias: $alias" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "IMPORTANT: Change these passwords before production release!" -ForegroundColor Red
} else {
  Write-Host "Failed to generate keystore. Make sure Java JDK is installed." -ForegroundColor Red
}
