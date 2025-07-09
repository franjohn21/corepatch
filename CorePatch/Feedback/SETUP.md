# AI Feedback System Setup

## Overview
The AI feedback system provides local-first, eventual sync feedback generation for journal entries. It queues feedback requests locally and processes them in the background, with automatic retry on failure.

## Setup Instructions

### 1. Enable Background Modes
In Xcode:
1. Select your project target
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "Background Modes"
5. Check "Background fetch" and "Background processing"

### 2. Add Info.plist Entry
Add to your Info.plist:
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.corepatch.feedback-generation</string>
</array>
```

### 3. Configure Your Proxy Endpoint
Update the `apiURL` in `FeedbackNetworkManager` with your actual proxy endpoint:
```swift
private let apiURL = "https://your-proxy.vercel.app/api/feedback"
```

## How It Works

1. **Local First**: All entries are saved locally immediately
2. **Queue Feedback**: When user completes entries, feedback is queued
3. **Background Processing**: System processes queue in background
4. **Retry Logic**: Failed requests retry with exponential backoff
5. **Status Updates**: UI shows pending/generating/completed status

## API Expected Format

Your proxy should accept POST requests with:
```json
{
  "categoryTexts": {
    "career": "Today I made progress on...",
    "relationships": "I connected with..."
  },
  "woundID": "wound-id-string",
  "date": "2025-06-30T00:00:00Z"
}
```

And return:
```json
{
  "feedback": "Today you focused on multiple areas of your life, which shows a beautiful commitment to growth. Your entries reveal a pattern of increasing self-awareness and emotional intelligence...",
  "generatedAt": "2025-06-30T12:00:00Z"
}
```

## Testing
The system includes mock feedback generation for testing. Real API calls are commented out in `FeedbackNetworkManager`.