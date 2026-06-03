# EatMap — API Reference

> Auto-derived from the Flutter data layer (`lib/features/**/data/repositories/*.dart`).
> Keep this file in sync whenever a repository implementation changes an endpoint.

## Conventions

| | |
|---|---|
| **Base URL** | `https://dev.gixbot.online/api/v1` |
| **Auth** | `Authorization: Bearer <JWT>` on every request except sign-in. The token comes from the active Supabase session first, then falls back to `SecureStorage` (`auth_jwt_token`). |
| **Default headers** | `Content-Type: application/json`, `Accept: application/json` (multipart endpoints override `Content-Type`). |
| **Timeouts** | connect / receive / send — see `ApiConfig` in `lib/core/network/api_config.dart`. |
| **Retries** | `GET`/idempotent calls are retried twice (1s, 2s back-off) by `RetryInterceptor`. |
| **Offline mode** | If the sentinel token `local_mock_token` is stored, or the request fails with a connection error/timeout (and some `422`s), repositories return local mock data instead of surfacing an error. |

### Error model

Non-2xx responses are mapped to a `Failure` by `ErrorHandler`:

| HTTP status | App behaviour |
|---|---|
| `401` | Token cleared, `AuthFailure` ("Session expired"). |
| `422` | On `GET /zones/nearby` treated as "no data" → offline fallback. Otherwise a validation `Failure`. |
| `connectionError` / `connectionTimeout` / `unknown` | Offline fallback (mock data or `Right(unit)`). |
| other | `ErrorHandler.handle(...)` → typed `Failure`. |

Errors are expected to be returned as:

```json
{ "detail": "Human readable error message" }
```

---

## 1. Auth — `/auth`

### `POST /auth/google`
Sign in / sign up via Google. Returns a backend JWT.

Request body (`application/json`):
```json
{
  "google_id": "string (Google account id / id_token)",
  "device_token": "string (FCM push token)",
  "device_id": "string (device fingerprint, 1 account/device)"
}
```
Response `200`:
```json
{ "access_token": "<jwt>", "token_type": "bearer" }
```
> The client immediately follows up with `GET /auth/me`.

---

### `POST /auth/verify-phone`
Verify a phone OTP and sign in.

Request body:
```json
{ "phone": "+91XXXXXXXXXX", "code": "123456" }
```
Response `200`:
```json
{ "access_token": "<jwt>", "token_type": "bearer" }
```

---

### `GET /auth/me`
Returns the authenticated user profile.

Response `200`:
```json
{
  "id": "uuid",
  "supabase_uid": "uuid",
  "username": "street_raider",
  "display_name": "Raider Champion",
  "avatar_url": "https://.../avatar.jpg",
  "city": "Mumbai",
  "trust_score": 100,
  "level": 5,
  "total_points": 2450,
  "wallet_balance": 150.0,
  "device_id": "string",
  "account_age": 12,
  "created_at": "2026-01-01T00:00:00Z"
}
```
> `401` clears the local session.

---

### `PATCH /auth/me`
Partial profile update. Only send the fields being changed.

Request body (any subset):
```json
{
  "username": "new_handle",
  "display_name": "New Name",
  "city": "Jaipur",
  "avatar_url": "https://.../a.jpg"
}
```
Response `200`: same shape as `GET /auth/me`. (The client re-fetches `/auth/me` after the PATCH.)

---

### `POST /auth/me/avatar`
Upload a profile picture. **multipart/form-data.**

| field | type | notes |
|---|---|---|
| `file` | file (jpeg) | filename `avatar.jpg` |

Response `200`:
```json
{ "avatar_url": "https://.../avatar.jpg" }
```
> The client force-merges this `avatar_url` into the subsequent `GET /auth/me` to bypass propagation lag.

---

### `PATCH /auth/me/location`
Fire-and-forget GPS update (no body returned is used).

Request body:
```json
{ "lat": 26.9124, "lng": 75.7873 }
```
Response `200/204`: ignored by the client.

---

## 2. Zones — `/zones`

### `GET /zones/nearby`
Two mutually-exclusive query forms:

| Query | When used |
|---|---|
| `?geohash=te7u6b` | No GPS fix yet (fallback). |
| `?lat=26.96&lng=75.73` | GPS acquired — returns all nearby food/drink POIs. |

Response `200`: array of **Zone** objects:
```json
[
  {
    "id": "uuid",
    "place_id": "google_place_id",
    "name": "The Burger Bastion",
    "lat": 26.9626,
    "lng": 75.7377,
    "geohash": "te7u6b",
    "warlord_id": "uuid | null",
    "warlord_username": "BurgerKing99 | null",
    "warlord_avatar_url": "https://... | null",
    "custom_title": "Burger Warlord | null",
    "custom_colour": "#E53935",
    "custom_icon": "hamburger | pizza | fork",
    "total_raids": 42,
    "warlord_raids": 15,
    "status": "active | uncaptured",
    "updated_at": "2026-06-03T10:00:00Z"
  }
]
```
> `422` here is treated as "no zones" → offline mock list.

---

### `GET /zones/{zoneId}`
Single zone detail. Response `200`: one **Zone** object (shape above).

---

### `PATCH /zones/{zoneId}/customize`
Warlord-only zone customization. **multipart/form-data.**

| field | type | constraints |
|---|---|---|
| `title` | string | max 30 chars |
| `colour` | string | hex, e.g. `#E53935` (palette of 8) |
| `icon` | string | one of `fork`, `hamburger`, `pizza` (icon set TBD) |

Response `200`: the updated **Zone** object.

---

## 3. Raids — `/raids`

### `POST /raids/start`
Begin a raid (starts the 15-min stay timer server-side).

Request body:
```json
{
  "zone_id": "uuid",
  "lat": 26.9626,
  "lng": 75.7377,
  "device_id": "string"
}
```
Response `200`:
```json
{ "raid_id": "uuid" }
```

---

### `POST /raids/{raidId}/verify`
Verify a completed raid with spend proof. **multipart/form-data.**

| field | type | required | notes |
|---|---|---|---|
| `spend_amount` | number | yes | ₹ spent (thresholds: <50 invalid, 50–199 base, 200–499 ×1.5, 500+ ×2) |
| `upi_ref` | string | no | UPI transaction reference for auto-verify |
| `bill_photo` | file | no | bill image; AI date check must match today |

Response `200`:
```json
{ "points": 25.0, "rank": 1, "is_warlord": true }
```

---

## 4. Wallet — `/wallet`

### `GET /wallet/balance`
Response `200`:
```json
{ "balance": 750.0 }
```

### `GET /wallet/transactions`
Response `200`: array of **Transaction** objects (client sorts newest-first):
```json
[
  {
    "id": "tx_001",
    "amount": 150.0,
    "type": "reward | bonus | withdrawal",
    "status": "success | pending | failed",
    "title": "Stronghold Conquest: Burger Bastion",
    "created_at": "2026-06-01T10:00:00Z",
    "upi_id": "raider@paytm"
  }
]
```

### `POST /wallet/withdraw`
Request a UPI payout (min ₹100; client checks balance first in offline mode).

Request body:
```json
{ "amount": 100.0, "upi_id": "raider@paytm" }
```
Response `200`: one **Transaction** object (`type: "withdrawal"`).

---

## 5. Leaderboard — `/leaderboard`

### `GET /leaderboard`
| Query | values |
|---|---|
| `scope` | `city` \| `global` \| `squad` |

Response `200`: array of **LeaderboardUser** objects:
```json
[
  {
    "rank": 1,
    "username": "warlord_alpha",
    "display_name": "Warlord Alpha 🛡️",
    "avatar_url": "https://... | null",
    "total_points": 8500,
    "warlord_count": 12,
    "squad_name": "Bravado | null"
  }
]
```

---

## Endpoint summary

| Method | Path | Auth | Body |
|---|---|---|---|
| POST | `/auth/google` | no | json |
| POST | `/auth/verify-phone` | no | json |
| GET | `/auth/me` | yes | — |
| PATCH | `/auth/me` | yes | json |
| POST | `/auth/me/avatar` | yes | multipart |
| PATCH | `/auth/me/location` | yes | json |
| GET | `/zones/nearby?geohash=` / `?lat=&lng=` | yes | — |
| GET | `/zones/{id}` | yes | — |
| PATCH | `/zones/{id}/customize` | yes | multipart |
| POST | `/raids/start` | yes | json |
| POST | `/raids/{id}/verify` | yes | multipart |
| GET | `/wallet/balance` | yes | — |
| GET | `/wallet/transactions` | yes | — |
| POST | `/wallet/withdraw` | yes | json |
| GET | `/leaderboard?scope=` | yes | — |

---

## Endpoints implied by the PRD but **not yet implemented** in the client

These appear in the product spec / mock data but have no repository call yet:

| Feature (PRD) | Suggested endpoint |
|---|---|
| Notifications feed ("Stronghold under attack") | `GET /notifications`, `PATCH /notifications/{id}/read` |
| Squads (MVP 2) | `GET /squads`, `POST /squads`, `POST /squads/{id}/join` |
| Referrals | `GET /referrals`, `POST /referrals/redeem` |
| Streak / weekly challenges | `GET /challenges`, `POST /challenges/{id}/claim` |
| Premium membership (MVP 3) | `POST /premium/subscribe` |
| Push token registration | `POST /devices/register` |
