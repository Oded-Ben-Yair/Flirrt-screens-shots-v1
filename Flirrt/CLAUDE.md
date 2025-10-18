# Vibe8.ai - Personal Wingman iOS App

## Project Overview
Vibe8.ai is a personal wingman iOS application that helps users improve their flirting skills through AI-powered text suggestions and optional voice messages. The app integrates as a keyboard extension with third-party dating apps.

## Architecture
- **iOS App**: Main container with SwiftUI, authentication, voice clone setup
- **Keyboard Extension**: Custom keyboard with "Vibe8 Fresh" and "Let's Analyze It!" features
- **Share Extension**: Screenshot upload functionality for conversation analysis
- **Backend API**: Node.js/Express server with Grok Vision API and ElevenLabs integration
- **Privacy Layer**: End-to-end encryption, minimal data retention, consent management

## Tech Stack
- **Frontend**: iOS (SwiftUI), Keyboard Extension (UIKit)
- **Backend**: Node.js, Express, PostgreSQL, Redis
- **AI/ML**: Grok Vision API (screenshot analysis), ElevenLabs (voice synthesis)
- **Infrastructure**: AWS (ECS Fargate, RDS, S3, API Gateway)
- **Authentication**: Apple/Google OAuth

## Key Features
1. **Vibe8 Fresh**: Personalized opener suggestions bank
2. **Let's Analyze It!**: Screenshot analysis → 3 contextual flirt suggestions
3. **Voice Clone**: Optional ElevenLabs voice synthesis for audio messages
4. **Privacy-First**: Explicit consent, 24-hour screenshot retention, easy data deletion

## Development Phases
- **MVP1**: Basic iOS app + keyboard extension + text suggestions
- **MVP2**: Screenshot analysis + personalization engine
- **MVP3**: Voice cloning + advanced AI features

## Compliance Requirements
- iOS App Store guidelines compliance
- GDPR/CCPA privacy law compliance (17 US states)
- Enhanced safety for users under 18
- No security bypass attempts (Full Access consent required)

## API Endpoints
- `POST /analyze_screenshot` - Conversation context analysis
- `POST /generate_flirts` - Personalized suggestion generation  
- `POST /synthesize_voice` - Voice message creation
- `DELETE /user/{id}/data` - Privacy compliance data deletion

## Subagents Available
- `screenshot-analyzer` - Conversation context analysis specialist
- `personalization-agent` - User preference learning and adaptation
- `flirt-generator` - Suggestion generation with tone templates
- `voice-synthesis` - ElevenLabs orchestration and optimization
- `consent-privacy` - GDPR/CCPA compliance management
- `safety-filter` - Content moderation and harassment prevention

Use subagents with: "Use the [agent-name] subagent to [specific task]"

## Getting Started
1. Review architecture in `deliverables/README_HANDOFF.md`
2. Check API specifications in `deliverables/API/*.json`
3. View user flows in `deliverables/Diagrams/*.mmd`
4. Deploy subagents for specialized tasks from `.claude/agents/`

## Security Notes
- Never bypass iOS security mechanisms
- Explicit user consent required for all data collection
- End-to-end encryption for voice samples and screenshots
- 24-hour maximum retention for conversation screenshots