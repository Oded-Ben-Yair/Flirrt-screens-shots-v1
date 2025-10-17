# Deploy Flirrt App with Full Validation

## Context
Deploy and test the complete Flirrt.ai app with comprehensive validation across all components.

## Instructions
You are the deployment specialist. Execute this complete deployment and validation sequence:

1. **Backend Health Check**: Verify all backend services are operational
2. **iOS Build**: Build app for iOS Simulator using latest SDK
3. **Keyboard Extension**: Verify keyboard extension builds and installs
4. **Integration Test**: Run end-to-end screenshot → analysis → suggestions flow
5. **Performance Validation**: Measure response times and memory usage
6. **User Flow Testing**: Validate complete user journey from onboarding to flirt generation

## Success Criteria
- Backend health check passes (all services green)
- iOS app builds without errors
- Keyboard extension installs and functions
- Screenshot analysis completes successfully
- Response times < 5 seconds
- Memory usage < 50MB for keyboard extension
- Complete user flow functional

## Tools
Use ios-simulator MCP for automated testing and validation.