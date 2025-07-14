# Simple TestFlight Setup Guide

This guide explains how to set up GitHub Actions to automatically deploy your iOS app to TestFlight using just Xcode tools (no Ruby/Fastlane).

## Prerequisites

1. Apple Developer Account with App Store Connect access
2. App created in App Store Connect
3. GitHub repository with admin access

## Setup Steps

### 1. Create App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to Users and Access → Keys
3. Click "+" to create a new key
4. Give it a name (e.g., "GitHub Actions CI")
5. Select "Admin" access
6. Download the `.p8` file (you can only download it once!)
7. Note down:
   - Key ID (shown in the list)
   - Issuer ID (shown at the top of the API Keys page)

### 2. Export Certificates and Provisioning Profiles

#### Export Distribution Certificate:
1. Open Keychain Access on your Mac
2. Find your "Apple Distribution" certificate
3. Right-click → Export → Save as .p12 file
4. Set a password (save this password!)

#### Download Provisioning Profile:
1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to Certificates, Identifiers & Profiles
3. Go to Profiles → Distribution
4. Find/create an App Store profile for your app
5. Download the .mobileprovision file

### 3. Create App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Go to App-Specific Passwords
4. Create a new password for "GitHub Actions"
5. Save this password!

### 4. Configure GitHub Secrets

Go to your repository Settings → Secrets and variables → Actions, and add these secrets:

#### Required Secrets:

1. **APPLE_ID**: Your Apple Developer account email
   - Example: `developer@example.com`

2. **APP_SPECIFIC_PASSWORD**: The password from step 3
   - Example: `abcd-efgh-ijkl-mnop`

3. **APP_STORE_CONNECT_KEY_ID**: The Key ID from step 1
   - Example: `D4K3Y1D123`

4. **APP_STORE_CONNECT_ISSUER_ID**: The Issuer ID from step 1
   - Example: `69a6de7e-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

5. **APP_STORE_CONNECT_KEY_CONTENT**: Base64 encoded content of the .p8 file
   - Encode it: `base64 -i AuthKey_XXXXXXXXXX.p8 | tr -d '\n'`
   - Copy the entire output

6. **CERTIFICATES_P12**: Base64 encoded .p12 certificate file
   - Encode it: `base64 -i certificate.p12 | tr -d '\n'`
   - Copy the entire output

7. **CERTIFICATES_PASSWORD**: The password for your .p12 file

### 5. Update Xcode Project Settings

1. Open your project in Xcode
2. Select the project in the navigator
3. Select your app target
4. Go to "Signing & Capabilities"
5. Ensure "Automatically manage signing" is UNCHECKED
6. Select your team
7. Ensure the bundle identifier matches: `com.pleaseclapapps.mobile.CorePatch`

### 6. Create Shared Scheme

1. In Xcode, go to Product → Scheme → Manage Schemes
2. Select your "CorePatch" scheme
3. Check "Shared" checkbox
4. Click "Edit"
5. Ensure "Archive" uses Release configuration
6. Close and commit the changes

### 7. Enable Build Number Updates

1. In Xcode, select your project
2. Go to the target's Build Settings
3. Search for "Versioning System"
4. Set it to "Apple Generic"
5. This allows `agvtool` to work in CI

## Usage

### Single Workflow - Multiple Ways to Deploy:

#### 1. Manual Deployment (Recommended)
Go to Actions → Deploy to TestFlight → Run workflow:

**For Preview:**
- Environment: `preview`
- Version: (optional, defaults to 1.0.0)
- Release notes: (optional)

**For Production:**
- Environment: `production` 
- Version: (required, e.g., 1.0.1)
- Release notes: (required)

#### 2. Automatic Deployments

**Preview via PR:** Opens a PR to main branch with iOS changes
- Automatically deploys to preview environment
- Version: `1.0.0-pr{number}`
- Internal testers only

**Production via Git Tag:**
```bash
git tag v1.0.0
git push origin v1.0.0
```
- Automatically deploys to production
- External testers included

## How It Works

The GitHub Actions workflow:
1. Downloads your certificate and provisioning profile
2. Installs them in the CI environment
3. Builds your app using `xcodebuild`
4. Exports an IPA file
5. Uploads to TestFlight using `altool`

## Build Numbers

- Build numbers auto-increment using GitHub run number
- Version numbers specified manually or via git tags
- Format: `MAJOR.MINOR.PATCH` (e.g., 1.0.0)

## Troubleshooting

### Common Issues:

1. **"No matching provisioning profile"**: Check your bundle ID and certificate
2. **"Invalid API Key"**: Verify the .p8 file is properly base64 encoded
3. **"Upload failed"**: Check app-specific password is correct
4. **"agvtool failed"**: Ensure versioning system is set to "Apple Generic"

### Testing Locally:

```bash
# Test certificate export
security find-identity -v -p codesigning

# Test build
xcodebuild -project CorePatch.xcodeproj -scheme CorePatch archive

# Test agvtool
agvtool what-version
```

## Security Notes

- All sensitive data stored in GitHub Secrets
- Certificates/profiles downloaded fresh each build
- No Ruby dependencies to maintain
- Uses official Apple tools only

## Next Steps

1. Set up all GitHub secrets
2. Test with a preview build first
3. Verify the app appears in TestFlight
4. Test installation on a device
5. Then proceed with production builds

This setup is much simpler than Fastlane - just Xcode tools and GitHub Actions!