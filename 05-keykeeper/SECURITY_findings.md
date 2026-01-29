# Security Findings – KeyKeeper 

## Finding 1: JWT Revocation Missing 

**Severity:** High
Critical/High/Medium/Low

**Where:**
server/lib/jwt.js
server/middleware/auth.js

**Steps to Reproduce:**

**Impact:**
The application issues time-limited JWTs (expiresIn: '2h') but does not implement any mechanism for token revocation or session invalidation.
If a JWT is stolen, an attacker retains access to the secrets vault for up to two hours.

**Fix:**
Describe how to fix it (logic, validation, encryption, access checks, etc.)

**Verification of Fix:**
Tokens should be rejected immediately after user role changes or revocation.
Application should fail to start if JWT_SECRET is not configured.

## Finding 2: Secrets Exposed via Page Load API Requests 
**Severity:** High

**Where:**
server/models/items.js

**Impact:**
Secrets can be exposed through browser inspection tools even if they appear masked in the UI. Sensitive information is returned as part of page-load API responses and can be viewed through browser developer tools without any explicit user action.

**Fix:**
Do not return secret values in page-load API responses.
Return only non-sensitive metadata (name, environment, status, expiration).
Implement a dedicated “reveal secret” endpoint that:
requires explicit user action
enforces authorization checks
logs access events

**Verification of Fix:**
Page-load API responses should not contain secret values.
Secret values should only be returned after an explicit reveal request and proper authorization.
