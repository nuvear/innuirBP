# Deployment Test Session — InnuirBP iPad

**Date:** 2026-03-15  
**Tester:** Deployment Team (automated + manual)  
**Device:** iPad Pro 13-inch (M5) Simulator, iOS 26.1  
**Build:** Debug, clean build

---

## Test Results

| # | Test | Result | Notes |
|---|------|--------|-------|
| 1 | **Clean build succeeds** | ✅ Pass | No errors, no new warnings. iOS device + simulator both build. |
| 2 | **App launches on iPad** | ✅ Pass | App installed and launched (PID 96255). No crash at launch. |
| 3 | **Tap Sync without HealthKit entitlement** | ⏸️ N/A | Simulator: HealthKit unavailable. Physical device required. |
| 4 | **Enable HealthKit, tap Sync** | ⏸️ Manual | Requires physical iPad + Developer Portal entitlement. |
| 5 | **Grant permission, tap Sync again** | ⏸️ Manual | Requires physical device with Health data. |
| 6 | **Manual entry via + button** | ⏸️ Manual | UI verification — requires human interaction. |
| 7 | **Widget displays on Home Screen** | ⏸️ Manual | Add widget to simulator Home Screen and verify. |

---

## Automated Verification (Completed)

- **Clean build (Shift+Cmd+K, Cmd+B):** Succeeded for `generic/platform=iOS` and `platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.1`
- **App launch:** InnuirBP launches on iPad Pro 13-inch simulator without crash
- **Entitlements:** `com.apple.developer.healthkit.access = []` present in InnuirBP.entitlements; widget has App Group

---

## Manual Verification Required

The following tests require a **physical iPad** (e.g., iPad16,6) and/or human interaction:

1. **Sync flow (Tests 3–5):** Tap Sync → HealthKit permission sheet → Grant → Readings import. HealthKit is limited in the simulator.
2. **Manual entry (Test 6):** Tap + on BP Detail screen, enter reading, confirm it saves and appears in chart.
3. **Widget (Test 7):** Add InnuirBP widget to Home Screen, confirm it shows latest reading after sync or manual entry.

---

## Recommendation

**Build and launch:** ✅ Ready for deployment.

**Full sync validation:** Run Tests 3–7 on a physical iPad with:
- HealthKit enabled for App ID `com.innuir.bp` in Developer Portal
- Provisioning profile regenerated (clean build, reinstall)
- Blood pressure data in Apple Health (or add via manual entry first)

---

## Sign-off

| Role | Status |
|------|--------|
| Build verification | ✅ Pass |
| Simulator launch | ✅ Pass |
| Physical device + Sync | Pending manual run |
