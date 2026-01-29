# Security Findings – KeyKeeper 

## Finding 1: JWT Revocation Missing 

**Severity:** High
Critical/High/Medium/Low

**Where:**
server/lib/jwt.js
server/middleware/auth.js
server/routes/auth.js

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

**Steps to Reproduce:**
Log in to the application.
Open the browser developer tools and navigate to the Network tab.
Reload the page.
Inspect API responses triggered during page load.
Observe that secret data is included in responses without clicking a “Reveal” action.

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

## Finding 3: Broken Access Control – Any User Can Access Any Secret (IDOR)

**Severity:** High

**Where:**
server/routes/items.js
Endpoint: `GET /items/:id/reveal'

**Impact:**
The `reveal` endpoint records access attempts but **does not validate authorization**.  
Specifically, it does **not** verify that the requesting user:
- owns the secret **or**
- has been granted access via `sharedWith`

**Steps to Reproduce:**


**Fix:**
Add ownership verification before allowing rotation.
Restrict rotation to owner, admins, or users with explicit manage permission.
Consider requiring re-authentication for sensitive operations.

**Verification of Fix:**
Users should only reveal secrets they own or are shared with.
Unauthorized reveal attempts should return 403 Forbidden.
Access logs should distinguish between authorized and denied attempts.

## Finding 4: Broken Access Control – Any User Can Rotate Any Secret

**Severity:** 
High

**Where:** 
server/routes/items.js — 
Endpoint: 'POST /items/:id/rotate'

server/routes/items.js — POST /items/:id/rotate endpoint

**Impact:**
Any authenticated user can rotate (replace) the secret value of any secret in the system. An attacker could replace production API keys or database passwords with values they control, causing service outages or enabling further attacks.

**Fix:**
Add ownership verification before allowing rotation.
Restrict rotation to owner, admins, or users with explicit manage permission.
Consider requiring re-authentication for sensitive operations.

**Verification of Fix:**
Only owners/admins should be able to rotate secrets.
Unauthorized rotation attempts should return 403 Forbidden.

