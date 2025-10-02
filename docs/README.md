# FlirrtAI - AI-Powered Dating Assistant

**Your personal AI wingman for better conversations**

## 🚀 Quick Start

### Backend
```bash
cd Backend
npm install
npm start
# Server runs on http://localhost:3000
```

### iOS App
```bash
cd iOS
open Flirrt.xcodeproj
# Build and run in Xcode (iPhone Simulator recommended)
```

### Enable Keyboard
1. Open iOS Settings
2. General → Keyboard → Keyboards
3. Add New Keyboard → Flirrt
4. Enable "Allow Full Access"

## 📱 What is FlirrtAI?

FlirrtAI is an iOS keyboard extension that helps you craft better messages in dating apps. Take a screenshot of your conversation, and the AI analyzes context to generate personalized flirt suggestions.

### Core Features
- **Screenshot Analysis**: Analyzes conversation screenshots for context
- **Personalized Suggestions**: AI-generated flirts based on your style
- **Voice Cloning**: Record your voice for audio messages
- **Background Sounds**: Add ambient sounds to voice messages
- **Smart Context Detection**: Knows when you need opener vs. response suggestions

## 🎯 Current Status (October 2025)

### ✅ Working
- User authentication (Apple Sign In)
- Onboarding questionnaire (personalization)
- Voice recording UI and flow
- Backend APIs (Grok, Gemini, ElevenLabs)
- App Groups data sharing
- Keyboard extension loads and displays

### ❌ Known Issues
- Screenshot detection not triggering analysis
- Keyboard-Backend API integration incomplete
- Voice synthesis not yet connected

See [KNOWN_ISSUES.md](./KNOWN_ISSUES.md) for details and workarounds.

## 📚 Documentation

- [Setup Guide](./SETUP.md) - Installation and configuration
- [Architecture](./ARCHITECTURE.md) - Technical design and data flow
- [Features](./FEATURES.md) - Detailed feature documentation
- [API Documentation](./API.md) - Backend endpoints and contracts
- [Keyboard Setup](./KEYBOARD_SETUP.md) - User guide for keyboard installation

## 🔧 Tech Stack

- **iOS**: Swift, SwiftUI, iOS 16+
- **Backend**: Node.js, Express, SQLite
- **AI**: Grok (xAI), Gemini Vision (Google), ElevenLabs
- **Architecture**: Keyboard Extension + Main App + Backend API

## 📝 Project Structure

```
FlirrtAI/
├── iOS/                  # Swift iOS Application
│   ├── Flirrt/          # Main app
│   ├── FlirrtKeyboard/  # Keyboard extension
│   └── FlirrtShare/     # Share extension
├── Backend/             # Node.js API Server
│   ├── routes/          # API endpoints
│   ├── services/        # Business logic
│   └── data/            # SQLite database
├── docs/                # Documentation (you are here)
└── .archive/            # Legacy files (ignore)
```

## 🤝 Contributing

This is a personal project. For questions or issues, see documentation in this folder.

## 📄 License

Private project - all rights reserved.

---

**Last Updated**: October 2025
**Version**: 0.1.0 (Pre-Production)
