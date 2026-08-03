# Alpha Status — Code Reality Audit

> **Purpose:** A *truthful* snapshot of where the codebase actually stands against
> [`Alpha_roadmap.md`](Alpha_roadmap.md), based on reading the C# + CloudScript — **not** what
> the roadmap checkboxes hope. Where the roadmap and the code disagree, **the code wins** and
> it's flagged here. This exists to answer one question: *"What is the literal next task?"*
>
> Audited: 2026-06-24 (Coplay). Scope: α0, α1, α2 (the path to a persistent economic loop).
> Method: direct source inspection of `Assets/Scripts/Networking`, `Assets/Scripts/Diagnostics`,
> `Assets/Scripts/Macro`, and the `cloudscript/` bundle.

---

## Legend
- ✅ **DONE** — implemented on the live path (real server / persisted), works end-to-end.
- 🟡 **PARTIAL** — exists, but client-attested / stubbed / not server-authoritative / not wired through.
- ⬜ **NOT STARTED** — no meaningful implementation found.

The single most important column is **"Server-authoritative?"** — alpha's whole point is *persistence
across re-login and agreement across two clients*. A client-attested write looks done in single-player
and falls apart the moment a second tester or a modded client shows up.

---

## α0 — Production Foundation

| Item | Status | Evidence / Note |
|---|---|---|
| α0.1 Real PlayFab auth (email reg + login + auto-relogin) | ✅ **DONE** | `PlayFabManager.cs` — `RegisterPlayFabUser`, `LoginWithEmailAddress`, hardware `LinkCustomID`, `DeviceLinkedPref` auto-relogin. This is genuinely finished. |
| α0.2 CloudScript deploy automation (editor menu push) | ✅ **DONE** (built 2026-06-24) | `Assets/Editor/PlayFab/CloudScriptDeployer.cs` — menu `Apex Outlaw → CloudScript → Push Revision (Rebuild + Publish Live)` rebuilds `_deploy_bundle.js` then POSTs it to `/Admin/UpdateCloudScript` via `PlayFabAdminRest.UpdateCloudScript`. A Draft variant uploads without publishing. The bundle *rebuilder* (`Assets/Editor/Debug/RebuildCloudScriptBundle.cs`) already existed; the missing piece was the programmatic upload, now added. |
| α0.3 Title-data export pipeline | ✅ **DONE** (pre-existing) | **Audit correction:** this WAS already done — `Assets/Editor/PlayFab/TitleDataCatalogExporter.cs` (menu `Push All Catalogs`, dry-run, drift check) + `PlayFabAdminRest.SetTitleData`. The first pass missed it by searching only `Assets/Scripts/Editor`; the tooling lives under `Assets/Editor/`. |
| α0.4 Build pipeline doc | ⬜ **NOT STARTED** | No build doc found. |
| α0.5 Crash + log capture | ✅ **DONE** | `Diagnostics/CrashReporter.cs` + `LogRingBuffer.cs` — exception hook, dedupe, local file + Discord webhook. |
| α0.6 Bug-submit UI (F8) | ✅ **DONE** | `Diagnostics/BugReporter.cs` — F8 form, screenshot + last-200-log attach, Discord multipart POST, local fallback. |

**α0 verdict (revised):** α0 is **functionally complete** for development — auth, diagnostics, CloudScript
deploy automation, and title-data export all exist on the live path. Only α0.4 (a written build doc) and
the rolling α6-style production-polish items remain. **The server-tooling gap I flagged in the first pass
was wrong** — the catalog exporter (α0.3) existed, and α0.2 is now built. This frees the next focus to move
straight to α1.

> **Audit-method lesson:** the editor tooling lives under `Assets/Editor/`, not `Assets/Scripts/Editor`.
> Always search both. The first-pass "NOT STARTED" on α0.2/α0.3 was a false negative from a too-narrow
> search path — the kind of doc-vs-reality error this very document exists to catch.

---

## α1 — Persistent Macro Loop

| Item | Status | Server-authoritative? | Evidence / Note |
|---|---|---|---|
| α1.1 Gate-jump CloudScript handler | 🟡 **PARTIAL** | ❌ **No** | **No `handlers.GateJump` in cloudscript.** `PlayFabManager.SetCurrentSector()` writes `currentSectorID` *client-side* — the code comment literally says *"Client-attested for now; CloudScript should own this write."* Travel works visually but isn't validated or server-owned. |
| α1.2 Resume-at-last-sector | 🟡 **PARTIAL** | n/a | `PlayerProfile.currentSectorID` persists, and `LoginScreenUI` reads it — but because the write is client-attested (α1.1), the resume point is whatever the client last claimed. |
| α1.3 Fleet state authoritative | 🟡 **PARTIAL** | ❌ **No** | Fleet lives in the persisted `PlayerProfile` JSON, but mutations are client-side `SavePlayerProfile()` pushes. No server validation of position/cargo/durability. |
| α1.4 Logout auto-travel to safe spot | ⬜ **NOT STARTED** | — | No logout auto-travel logic found. |
| α1.5 Sector-view fleet roster bar | 🟡 **PARTIAL** | n/a | Fleet visualization exists (`MacroFleet*`); the dedicated bottom roster bar wasn't confirmed wired. Needs a focused check. |
| α1.6 Top-bar live credits + name | 🟡 **PARTIAL** | n/a | Partly built per roadmap; PlayFab subscription refresh not confirmed end-to-end. |

**α1 verdict:** The *data model* (persisted profile with sector/fleet) exists and the *visuals* work,
but **nothing in α1 is server-authoritative.** Every write is the client telling PlayFab what
happened. For single-player testing that's invisible; for "two clients agree" (the α1 exit criterion)
it's the core gap.

---

## α2 — Economic Loop MVP

| Item | Status | Server-authoritative? | Evidence / Note |
|---|---|---|---|
| α2.1 Mining loop closure (ore → cargo) | 🟡 **PARTIAL** | ❌ **No** | `MacroMiningBridge.cs` runs the 5-min session **but its own header says: *"No Fusion runner, no PlayFab write, no real yield resolution. Purely a single-client visual scaffold."*** The roadmap's "[x] cloudscript/mining.js" is **STALE — that file does not exist.** Mining produces *nothing* persisted. |
| α2.2 Hub buy/sell (`HubStockLevel`) | ⬜ **NOT STARTED** | ❌ | No `HubStockLevel`, no buy/sell handler in cloudscript or C#. The "sell ore → credits up" half of the loop doesn't exist. |
| α2.3 Cargo capacity enforcement | 🟡 **PARTIAL** | partial | Container mass math exists in `inventory.js` (`payloadMassKg`); ship `cargoCapacityKg` UI rejection not confirmed. |
| α2.4 Module fitting writeback (`EquipModule`) | 🟡 **PARTIAL** | ❌ **No** | Shipyard drag/drop exists (UI ~60%), but **no `EquipModule` CloudScript handler** — fitting mutates the client profile, not server-validated. |
| α2.5 Resource Scanner Toggle | ✅ **DONE** | ✅ | `scanning.js` handlers live (`ResolveMaterialAnchors`, fat-tail RNG). Scanner UX shipped. |
| α2.6 Starter credits + fleet (`OnPlayerCreated`) | 🟡 **PARTIAL** | ❌ **No** | Starter fleet is seeded by **client-side `PlayFabManager.EnsureFleetSeeded()`** (a tracked bridge), not a server `OnPlayerCreated` handler. Works, but the client decides what you start with. |

**α2 verdict:** This is where the roadmap is **most over-optimistic vs. reality.** The economic loop's
two anchor verbs — *mine something real* and *sell it for credits* — are **not implemented on the
live path.** Mining is a visual-only scaffold by its own admission; hub trade doesn't exist.

---

## The headline (the honest summary)

What you suspected — "doc drift, half-finished features" — is **confirmed and specific**:

1. **The genuinely-done work is the production shell + read-side:** real auth, crash/bug capture,
   the inventory/recipe/scanning CloudScript handlers, the celestial registry, the sector-map visuals.
   This is real, valuable, and worth keeping. **You are not starting over.**

2. **The gap is uniform and has one shape:** almost everything in the *player action* loop
   (travel, mine, trade, fit) is **client-attested or visual-only**, not server-authoritative.
   The systems *look* finished in single-player and aren't actually persisted/validated.

3. **Two infrastructure pieces gate everything else:** α0.2 (CloudScript deploy) and α0.3
   (title-data export). You cannot make travel/mining/trade server-authoritative without a
   reliable way to push handlers and seed catalogs.

4. **One roadmap checkbox is provably false:** Phase 3.4 claims `cloudscript/mining.js` exists.
   **It does not.** Mining writes nothing. (Fix the checkbox in the same pass that builds it.)

---

## The literal next task (do this, nothing else, until it's green)

> **✅ DONE — α0.2 CloudScript deploy automation** was the previous "next task" and is now built
> (`CloudScriptDeployer.cs`). With α0.3 confirmed already-done, **α0 infrastructure is complete.**
>
> **NEW next task: α1.1 — `GateJump` CloudScript handler.** Author `cloudscript/gate_jump.js`
> with `handlers.GateJump(args = { sourceGateId, targetGateId })`: server validates bubble
> reachability via the canonical `JumpGateNetwork` rules, writes `PlayerProfile.currentSectorID`
> + position server-side, returns the target scene id. Then replace the client-attested
> `PlayFabManager.SetCurrentSector()` write with a call to it, and deploy via the new
> `Push Revision` menu.

**Why this is now the front line:**
- It's the **first real server-authoritative write** — the thing that makes "two clients agree"
  (the α1 exit criterion) actually true. Right now travel is the client telling PlayFab where it went.
- It's small and self-contained — one handler + one client call swap. A clean win.
- It exercises the brand-new deploy pipeline end-to-end (authoring a handler → `Push Revision` → live),
  proving α0.2 works on a real handler.

**After α1.1, the path is unambiguous and strictly ordered:**
1. **α2.1 mining writeback** — author `cloudscript/mining.js`, wire `MacroMiningBridge` to call it
   (its header admits it writes nothing today), fix the stale Phase 3.4 checkbox.
2. **α2.2 hub buy/sell** — `HubStockLevel` title-data + a buy/sell handler. *Now the economic loop closes.*
3. **α2.4 `EquipModule`** — server-validated fitting.

Every one of those is now a "write the handler → `Push Revision`" task on the pipeline we just finished —
turning the existing visual scaffolds into a real, persistent, two-client-safe loop without building a
single system that isn't on the alpha path.

---

## What to explicitly NOT touch (re-confirmed from the DEFER list)

Surface base building (the power/battery work included), alliances, the DOM exchange, NPC arbitrage,
multiple star systems, capital ships. All post-alpha. If a task doesn't make one of the nine
"testable alpha" verbs work, it's deferred.
