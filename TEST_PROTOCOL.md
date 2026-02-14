# TRACES - MASTER TEST PROTOCOL (Billion-Dollar Death Run)

## 🧠 Section A: The Brain (Backend Automation)
Run via `cd services/backend-api && npm test`

| ID | Test Name | Description | Expected Result | Status |
|----|-----------|-------------|-----------------|--------|
| 01 | **Auth Injection** | Access protected route without headers | 401/403 Error | ✅ Automated |
| 02 | **SQL Injection** | Inject SQL in Search Text | Sanitized, 200 OK (Empty results) | ✅ Automated |
| 03 | **Vector Spam** | Send 10MB text to AI | 400 Payload Too Large | ✅ Automated |
| 04 | **Race Condition** | 5 simultaneous claims | 1 Success, 4 Failures | ✅ Automated |
| 05 | **Data Integrity** | Delete User | User's Traces removed (Cascade) | ✅ Automated |
| 06 | **Rate Limit** | 100 req/min | 429 Too Many Requests | ✅ Automated |
| 07 | **Search Relevance** | Query "Food" | Food traces > Non-food traces | ✅ Automated |
| 08 | **Geo-Fencing** | Unlock @ 21m vs 19m | Fail / Success | ✅ Automated |
| 09 | **Friend Boost** | Search as User A | Friend Trace Score > Stranger Trace Score | ✅ Automated |
| 10 | **Incognito Guard** | Enable Incognito Mode | User disappears from Global Leaderboard | ✅ Automated |

## 📱 Section B: The Body (Frontend & UX)
Manual Verification Required

| ID | Test Name | Description | Status |
|----|-----------|-------------|--------|
| 11 | **Cold Start** | Launch time < 2s (Hive Caching Check) | ⬜ Pending |
| 12 | **GPS Lockout** | Disable GPS -> Check Splash Screen Blocking | ⬜ Pending |
| 13 | **Offline Mode** | Airplane Mode -> Check cached Profile/Settings | ⬜ Pending |
| 14 | **3D Shader** | Magnifier rendering + Chromatic Aberration | ⬜ Pending |
| 15 | **Parallax** | Tilt device -> Background orbs move? | ⬜ Pending |
| 16 | **Haptics** | Verify unique vibrations for Tap, Pan, and Discover | ⬜ Pending |
| 17 | **Tab State** | Scroll Feed -> Switch Tabs -> Context Preserved? | ⬜ Pending |
| 18 | **Hero Morph** | Grid item -> Detail View transition fluidity | ⬜ Pending |
| 19 | **Shimmer UI** | Kill network -> Verify Glass Shimmers appear | ⬜ Pending |
| 20 | **Sound Engine** | Mute System -> Verify Settings toggle overrides | ⬜ Pending |

## 🔄 Section C: Integration & E2E
| ID | Test Name | Description | Status |
|----|-----------|-------------|--------|
| 21 | **Real-time Sink** | Drop trace on Device A -> Appears on B instantly | ⬜ Pending |
| 22 | **Dynamic Island** | Trigger notification -> Stretches from top correctly | ⬜ Pending |
| 23 | **Follow Loop** | Follow User -> Check Connections Leaderboard sync | ⬜ Pending |
| 24 | **Onboarding** | First-time OAuth -> Complete Profile Wizard redirect | ⬜ Pending |

## ⚙️ Section D: Performance & Ops
| ID | Test Name | Description | Status |
|----|-----------|-------------|--------|
| 25 | **Memory Leak** | Spam Tab switching (Stateful Navigator check) | ⬜ Pending |
| 26 | **Battery** | Background GPS usage profiling | ⬜ Pending |
| 27 | **Image Caching** | Scroll Explorer -> verify zero flicker (CachedNetworkImage) | ⬜ Pending |
| 28 | **API Resilience** | 500 Error from server -> Glass Error UI check | ⬜ Pending |

## 🧟 Section E: Insanity (Edge Cases)
| ID | Test Name | Description | Status |
|----|-----------|-------------|--------|
| 29 | **Shader Crash** | Run on old GPU (Android 8) | ⬜ Pending |
| 30 | **Overflow** | Bio = 10,000 characters | ⬜ Pending |
| 31 | **Clock Skew** | Set device time 1 hour back -> Token validity check | ⬜ Pending |
| 32 | **Simultaneous Haptics** | Multiple events triggering feedback at once | ⬜ Pending |
| 33 | **Account Wipe** | Sign Out -> Verify Hive cache cleared | ⬜ Pending |
| 34 | **Billion-Scale** | Simulate 1000 pins in 1km radius | ⬜ Pending |
