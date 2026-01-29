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

**How to Verify FixverityFix:**
Tokens should be rejected immediately after user role changes or revocation.
Application should fail to start if JWT_SECRET is not configured.

## Finding 2: Secrets Exposed via Page Load API Requests 
**Severity:** High

**Where:**
server/models/items.js

**Impact:**
Secrets can be exposed through browser inspection tools even if they appear masked in the UI.

