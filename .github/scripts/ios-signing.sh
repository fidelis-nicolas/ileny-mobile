#!/usr/bin/env bash
set -euo pipefail
for name in IOS_CERTIFICATE_BASE64 IOS_CERTIFICATE_PASSWORD IOS_PROFILE_BASE64 IOS_EXPORT_OPTIONS_BASE64 API_BASE_URL BUILD_NUMBER; do
  [[ -n "${!name:-}" ]] || { echo "Missing iOS release setting: $name" >&2; exit 1; }
done
[[ "$API_BASE_URL" =~ ^https://[a-zA-Z0-9.-]+(:[0-9]+)?/api/v1$ ]]
[[ "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]]
umask 077
printf '%s' "$IOS_CERTIFICATE_BASE64" | base64 -D > "$RUNNER_TEMP/certificate.p12"
printf '%s' "$IOS_PROFILE_BASE64" | base64 -D > "$RUNNER_TEMP/profile.mobileprovision"
printf '%s' "$IOS_EXPORT_OPTIONS_BASE64" | base64 -D > "$RUNNER_TEMP/ExportOptions.plist"
keychain="$RUNNER_TEMP/ileny-signing.keychain-db"
password=$(openssl rand -hex 32)
security create-keychain -p "$password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$password" "$keychain"
security import "$RUNNER_TEMP/certificate.p12" -P "$IOS_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k "$keychain"
security set-key-partition-list -S apple-tool:,apple: -k "$password" "$keychain"
security list-keychains -d user -s "$keychain" login.keychain-db
security cms -D -i "$RUNNER_TEMP/profile.mobileprovision" > "$RUNNER_TEMP/profile.plist"
profile_uuid=$(/usr/libexec/PlistBuddy -c 'Print UUID' "$RUNNER_TEMP/profile.plist")
[[ "$profile_uuid" =~ ^[a-fA-F0-9-]+$ ]]
team=$(/usr/libexec/PlistBuddy -c 'Print TeamIdentifier:0' "$RUNNER_TEMP/profile.plist")
profile_name=$(/usr/libexec/PlistBuddy -c 'Print Name' "$RUNNER_TEMP/profile.plist")
app_identifier=$(/usr/libexec/PlistBuddy -c 'Print Entitlements:application-identifier' "$RUNNER_TEMP/profile.plist")
export_team=$(/usr/libexec/PlistBuddy -c 'Print teamID' "$RUNNER_TEMP/ExportOptions.plist")
[[ "$team" =~ ^[A-Z0-9]{10}$ && "$team" == "$export_team" ]]
[[ "$profile_name" =~ ^[a-zA-Z0-9._\ -]+$ ]]
[[ "$app_identifier" == "$team.app.ileny.mobile" ]]
mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
cp "$RUNNER_TEMP/profile.mobileprovision" "$HOME/Library/MobileDevice/Provisioning Profiles/$profile_uuid.mobileprovision"
# These settings apply to the Runner release target, not to dependency pods.
printf '\nDEVELOPMENT_TEAM = %s\nCODE_SIGN_STYLE = Manual\nCODE_SIGN_IDENTITY = Apple Distribution\nPROVISIONING_PROFILE_SPECIFIER = %s\n' \
  "$team" "$profile_name" >> ios/Flutter/Release.xcconfig
echo "IOS_PROFILE_UUID=$profile_uuid" >> "$GITHUB_ENV"
