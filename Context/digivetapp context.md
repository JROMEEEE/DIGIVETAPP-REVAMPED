# DIGIVET Mobile — Claude Code Context

Flutter/Dart mobile app for **pet owners** of the Lipa City Veterinary Office (LCVO).
It is a **client of the existing DIGIVET Online backend** (Express + Supabase). It has no
backend of its own and never talks to the database directly.

Sources: `ADET_FINAL_DOCU` (mobile proposal) and `DIGIVET_online_backend_infrastructure.md`.
Where they disagree, the infrastructure doc wins — it reflects what is actually built.

---

## 1. Tech stack

| Layer | Technology | Notes |
|---|---|---|
| Language | Dart | |
| Mobile framework | Flutter (latest stable) | Android first; Android Studio as IDE |
| Backend (consumed, not built here) | Node.js + Express v5 | DIGIVET Online server, port **4001** |
| Database (behind the API) | Supabase PostgreSQL | **Never accessed from the app** — see §4 |
| Web counterpart | React 19 + Vite 8 (port 5174) | Owner web portal with the same features; use it as the reference UI/behaviour |
| Analytics | R (Plumber) | Lives on the **Local** system only. Not relevant to mobile. |

### Recommended Flutter packages (not yet chosen — confirm before adding)

| Need | Package |
|---|---|
| HTTP + cookie session | `dio`, `cookie_jar`, `dio_cookie_manager` (use `PersistCookieJar` so the session survives app restarts) |
| QR scanning (claim code) | `mobile_scanner` |
| QR display | `qr_flutter` |
| Local reminders | `flutter_local_notifications` + `timezone` |
| Path for persisted cookies | `path_provider` |

---

## 2. System requirements

### Dev machine
- Flutter SDK (stable) + Android Studio (includes Android SDK and JDK)
- Node.js **>= 18** to run the Online server (`cd server && npm run dev`)
- The Online repo's `.env` with a valid Supabase `DATABASE_URL` (Session pooler, port 5432)

### Reaching the API during development
- Base URL on **Android emulator**: `http://10.0.2.2:4001/api`
- Base URL on a **physical phone**: `http://<dev-machine-LAN-IP>:4001/api` (same Wi-Fi; the server must listen on all interfaces)
- Keep the base URL in one config constant — never hard-code it across files.
- The server is **plain HTTP** in dev (no deployment, no HTTPS yet). Android blocks cleartext by
  default: enable `android:usesCleartextTraffic="true"` for **debug builds only**.
- CORS does not apply to a native app, so the server's localhost-only CORS list is not a blocker.

### Target
- Android phones used by Lipa City pet owners. Requires internet — the mobile app has **no offline mode**
  (offline encoding exists only on the Local system, for staff).

---

## 3. API contract the app uses

All owner routes need a valid session cookie. Always read the actual route/model files in the
Online repo to confirm request/response JSON shapes before writing models — do not guess fields.

| Feature | Endpoint | Notes |
|---|---|---|
| Owner login | `POST /api/auth/owner-login` | Sets `digivet_online_session` cookie (HttpOnly, 12 h TTL) |
| Current user | `GET /api/auth/me` | Use on app start to check if the stored session is still valid |
| Logout | `POST /api/auth/logout` | Clear the cookie jar afterwards |
| Claim code — preview | `POST /api/auth/claim/verify` | Returns a **masked** confirmation of owner + pets |
| Claim code — register | `POST /api/auth/claim/redeem` | Creates the owner account and logs them in |
| Pets + vaccination history | `GET /api/owner/pets` | Pets with nested vaccination history, scoped to the session |
| List correction requests | `GET /api/owner/requests` | |
| Submit correction request | `POST /api/owner/requests` | Only `pet_name`, `breed`, `color_markings`, `sex`, `birth_date` are accepted |
| Profile | `GET /api/owner/profile` · `PATCH /api/owner/profile` | |
| Change password | `PATCH /api/owner/password` | |

### Error behaviour to handle in the UI
- **Login failures are deliberately generic.** Wrong password, unknown user and wrong portal all
  return the same error — show one generic message, don't try to tell them apart.
- **Lockout:** 5 failed logins lock the account for 15 minutes.
- **Claim endpoints are rate-limited** (`verify` 10 / 15 min, `redeem` 5 / 15 min) and return
  `429` with `Retry-After`. Show a wait message using that header.
- **Invalid claim codes are indistinguishable** (expired / used / revoked / nonexistent all look
  the same). Don't promise a specific reason.
- `401` on any owner route → session expired → route back to login.

---

## 4. Hard rules (do not break)

1. **Never use `supabase_flutter` or any Supabase client/keys in the app.** Supabase RLS is
   enabled with zero policies on purpose; the Data API is locked out. All data goes through
   the Express API.
2. **Never send an owner id / person id to identify the user.** The server scopes every owner
   query by the session. The app only sends the cookie.
3. **Owners cannot edit records directly.** Changes go through correction requests, which staff
   approve or reject. Approved changes sync back down to the Local system automatically.
4. **No staff features in the mobile app.** No encoding, no approving requests, no analytics,
   no sync. Those belong to the Local system and the Online staff console.
5. **Data privacy (RA 10173):** don't log personal data, don't store it outside the app sandbox,
   and don't cache pet/owner data in plain shared storage.

---

## 5. Feature status vs. the ADET proposal

| Proposed feature | Backend support | What to do |
|---|---|---|
| Pet Owner Login | ✅ Built | Use `/auth/owner-login` |
| QR Login Scanner | ✅ Claim-code routes exist | Scan the QR on the printed card → feed the code into `/claim/verify` then `/claim/redeem`. **Confirm with the team** that the Local system prints the claim code as a QR — if it only prints text, also allow manual entry. |
| Pet Profile | ✅ Built | From `/owner/pets` |
| Vaccination History | ✅ Built | Nested inside `/owner/pets` |
| Request updates | ✅ Built | `/owner/requests` |
| Profile / settings | ✅ Built | `/owner/profile`, `/owner/password` |
| Pet Care Reminders | ✅ No backend needed | Compute from each pet's next due date and schedule **local** notifications on-device |
| QR Generation (per pet/owner) | ⚠️ Undefined | Nothing on the server verifies a pet QR. Decide what it encodes and who scans it before building. |
| Push Notifications | ❌ Not built | No FCM, no device-token table, no push route. Needs new backend work. |
| Notification scheduling | ❌ Not built | Same as above |
| Email sending | ❌ Not built | Server has no mail library (deps are only `cors`, `dotenv`, `express`, `pg`) |

Build the ✅ rows first. The ❌ rows require changes to the Online backend and should be agreed
with the team before any mobile code depends on them.

---

## 6. Reference behaviour from the web owner portal

Match these so web and mobile feel like the same product:
- Dashboard opens on the **most urgent pet** (overdue first, then due soon).
- A "protection" indicator shows days remaining until the next dose, or days overdue.
- Show skeleton placeholders while the first request loads.
- Owner screens on web: Dashboard, My Pets, Pet Care, Settings.
