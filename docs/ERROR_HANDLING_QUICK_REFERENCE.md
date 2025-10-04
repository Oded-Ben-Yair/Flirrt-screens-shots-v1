# Error Handling Quick Reference Guide

**Last Updated**: October 4, 2025
**For**: Flirrt.AI Backend Developers

---

## 🚀 Quick Start

### Import Error Handler
```javascript
const {
    logError,
    sendErrorResponse,
    handleError,
    errorCodes,
    httpStatus
} = require('../utils/errorHandler');
```

---

## 📘 Common Patterns

### 1. Basic Route Error Handling
```javascript
router.post('/endpoint', async (req, res) => {
    try {
        // Your logic here
        const result = await someOperation();

        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        logError('operation_name', error, {
            user_id: req.user?.id,
            // Add relevant context
        });
        return handleError(error, res, 'operation_name', req.id);
    }
});
```

### 2. Service Method Error Handling
```javascript
async function serviceMethod(params) {
    try {
        const result = await externalApiCall(params);
        return { success: true, data: result };
    } catch (error) {
        logger.error('Service method failed', {
            error: error.message,
            params
        });

        // Try fallback if applicable
        try {
            const fallback = await fallbackMethod(params);
            return { success: true, data: fallback, fallback: true };
        } catch (fallbackError) {
            throw new Error('All attempts failed');
        }
    }
}
```

### 3. Promise with Error Handling
```javascript
// Async/await (preferred)
async function operation() {
    try {
        const result = await somePromise();
        return result;
    } catch (error) {
        logError('promise_operation', error);
        throw error;
    }
}

// .catch() method
somePromise()
    .then(result => handleResult(result))
    .catch(error => {
        logError('promise_operation', error);
        // Handle error
    });
```

### 4. Validation Before Processing
```javascript
const {
    validateRequiredFields,
    errorCodes
} = require('../utils/errorHandler');

router.post('/endpoint', async (req, res) => {
    try {
        // Validate required fields
        validateRequiredFields(req.body, ['field1', 'field2', 'field3']);

        // Continue with logic...
    } catch (error) {
        if (error.code === errorCodes.MISSING_REQUIRED_FIELD) {
            return sendErrorResponse(
                res,
                httpStatus.BAD_REQUEST,
                error.code,
                error.message,
                error.details,
                req.id
            );
        }
        return handleError(error, res, 'validation', req.id);
    }
});
```

---

## 🎯 Error Codes Reference

### Validation (400)
- `VALIDATION_ERROR` - General validation failure
- `MISSING_REQUIRED_FIELD` - Required field missing
- `INVALID_FORMAT` - Invalid data format
- `INVALID_INPUT` - Invalid input value

### Authentication (401)
- `AUTHENTICATION_FAILED` - Auth failed
- `INVALID_TOKEN` - Invalid JWT token
- `TOKEN_EXPIRED` - Expired token

### Authorization (403)
- `ACCESS_DENIED` - Access denied
- `INSUFFICIENT_PERMISSIONS` - Not enough permissions

### Not Found (404)
- `RESOURCE_NOT_FOUND` - Generic not found
- `SCREENSHOT_NOT_FOUND` - Screenshot not found
- `SUGGESTION_NOT_FOUND` - Suggestion not found

### Timeout (408, 504)
- `REQUEST_TIMEOUT` - Request timeout
- `API_TIMEOUT` - API call timeout

### Rate Limiting (429)
- `RATE_LIMIT_EXCEEDED` - Rate limit hit
- `QUOTA_EXCEEDED` - API quota exceeded

### Server Errors (500)
- `INTERNAL_SERVER_ERROR` - Generic server error
- `DATABASE_ERROR` - Database operation failed
- `CACHE_ERROR` - Cache operation failed

### External APIs (502, 503)
- `EXTERNAL_API_ERROR` - External API error
- `GROK_API_ERROR` - Grok API specific error
- `ELEVENLABS_API_ERROR` - ElevenLabs API error
- `SERVICE_UNAVAILABLE` - Service unavailable

---

## 📊 HTTP Status Codes

```javascript
httpStatus.OK                     // 200
httpStatus.CREATED                // 201
httpStatus.BAD_REQUEST            // 400
httpStatus.UNAUTHORIZED           // 401
httpStatus.FORBIDDEN              // 403
httpStatus.NOT_FOUND              // 404
httpStatus.REQUEST_TIMEOUT        // 408
httpStatus.TOO_MANY_REQUESTS      // 429
httpStatus.INTERNAL_SERVER_ERROR  // 500
httpStatus.BAD_GATEWAY            // 502
httpStatus.GATEWAY_TIMEOUT        // 504
```

---

## 🛠️ Utility Functions

### logError(context, error, metadata)
Log error with structured format

```javascript
logError('generate_flirts', error, {
    user_id: req.user?.id,
    screenshot_id,
    suggestion_type
});
```

**Output**:
```json
{
    "timestamp": "2025-10-04T12:34:56.789Z",
    "context": "generate_flirts",
    "error": {
        "message": "API timeout",
        "stack": "...",
        "code": "ETIMEDOUT"
    },
    "metadata": {
        "user_id": "user123",
        "screenshot_id": "screenshot456"
    }
}
```

### handleError(error, res, context, requestId)
Intelligent error handler that returns appropriate HTTP response

```javascript
return handleError(error, res, 'operation_name', req.id);
```

**Features**:
- Detects error type (timeout, rate limit, auth, etc.)
- Returns appropriate HTTP status code
- Includes standardized error format
- Logs error with context

### sendErrorResponse(res, statusCode, code, message, details, requestId)
Send standardized error response

```javascript
sendErrorResponse(
    res,
    httpStatus.BAD_REQUEST,
    errorCodes.VALIDATION_ERROR,
    'Invalid input',
    { field: 'email', issue: 'invalid format' },
    req.id
);
```

**Response**:
```json
{
    "success": false,
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Invalid input",
        "details": {
            "field": "email",
            "issue": "invalid format"
        }
    },
    "request_id": "req-123-456"
}
```

### validateRequiredFields(data, requiredFields)
Validate required fields are present

```javascript
validateRequiredFields(req.body, ['email', 'password', 'name']);
// Throws error if fields are missing
```

---

## ⚠️ Common Mistakes to Avoid

### ❌ DON'T: Ignore errors
```javascript
try {
    await operation();
} catch (error) {
    // Empty catch block - BAD!
}
```

### ✅ DO: Log and handle errors
```javascript
try {
    await operation();
} catch (error) {
    logError('operation', error, { context });
    return handleError(error, res, 'operation', req.id);
}
```

---

### ❌ DON'T: Generic error messages
```javascript
res.status(500).json({ error: 'Something went wrong' });
```

### ✅ DO: Use specific error codes
```javascript
sendErrorResponse(
    res,
    httpStatus.INTERNAL_SERVER_ERROR,
    errorCodes.DATABASE_ERROR,
    'Failed to save record',
    null,
    req.id
);
```

---

### ❌ DON'T: Expose sensitive information
```javascript
res.status(500).json({
    error: error.message,
    stack: error.stack,  // NEVER in production!
    config: process.env  // NEVER!
});
```

### ✅ DO: Return safe error details
```javascript
return handleError(error, res, 'operation', req.id);
// Only exposes safe error info in production
```

---

### ❌ DON'T: Unhandled promise rejections
```javascript
someAsyncFunction(); // No .catch() or await
```

### ✅ DO: Handle all promises
```javascript
// Option 1: await with try-catch
try {
    await someAsyncFunction();
} catch (error) {
    logError('async_operation', error);
}

// Option 2: .catch()
someAsyncFunction()
    .catch(error => logError('async_operation', error));
```

---

## 📋 Checklist for New Endpoints

When creating a new endpoint, ensure:

- [ ] Wrapped in try-catch block
- [ ] Errors logged with `logError()` including context
- [ ] Uses `handleError()` for response
- [ ] Validates required fields
- [ ] Handles specific error types (auth, validation, etc.)
- [ ] Includes request ID in error responses
- [ ] All promises have error handling
- [ ] Database operations have error handling
- [ ] External API calls have timeout handling
- [ ] Success responses use consistent format

---

## 🔍 Debugging Tips

### View Error Logs
All errors are logged with full context in structured JSON format:
```bash
# View error logs
tail -f logs/error.log | jq .

# Filter by context
tail -f logs/error.log | jq 'select(.context == "generate_flirts")'

# Filter by user
tail -f logs/error.log | jq 'select(.metadata.user_id == "user123")'
```

### Test Error Scenarios
```bash
# Test timeout (1 second timeout)
curl -X POST http://localhost:3000/api/endpoint \
  --max-time 1

# Test missing fields
curl -X POST http://localhost:3000/api/endpoint \
  -H "Content-Type: application/json" \
  -d '{}'

# Test invalid auth
curl -X GET http://localhost:3000/api/endpoint \
  -H "Authorization: Bearer invalid_token"
```

---

## 📚 Additional Resources

- **Full Documentation**: `/docs/ERROR_HANDLING_IMPLEMENTATION.md`
- **Error Handler Source**: `/Backend/utils/errorHandler.js`
- **Code Review Report**: `/docs/CODE_REVIEW_REPORT_OCT_4_2025.md`
- **API Documentation**: `/docs/API.md`

---

## 🆘 Need Help?

If you encounter issues:

1. Check error logs with full context
2. Verify error is being logged with `logError()`
3. Confirm `handleError()` is being used
4. Check if specific error type needs custom handling
5. Review `/docs/ERROR_HANDLING_IMPLEMENTATION.md` for examples

---

**Remember**: Every async operation should have error handling. No exceptions!
