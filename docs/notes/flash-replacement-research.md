# Flash Replacement Research

_Started: 2026-10-14 (from a conversation with Google AI Mode, cleaned up on 2026-10-20).
Updated 2026-10-20 with findings verified against the code in this repo._

## Goal

Make Empires & Allies (via Raise the Empires) playable in a modern browser
**without Adobe Flash Player**, so players don't need to download and configure
an old Flash Player version or an outdated browser.

## Background

- Empires & Allies was a Zynga Facebook game, shut down on 17 June 2013.
- The original client is a Flash (ActionScript 3) `.swf`. Zynga's server code was
  never released.
- Raise the Empires keeps the original Flash client and replaces Zynga's server
  with a community-written Python (Flask) server emulator that answers the
  client's requests locally. Flask-SocketIO is also used, but only for a debug
  log panel on the web page, not for game traffic.
- So there are two separate layers:
  - **Client**: original Flash `.swf`. This is what still requires Flash Player.
  - **Server**: Python emulator in this repo. Already runs without Flash
    (verified locally: tests pass, server serves the SWF/XML and answers AMF
    requests).

Replacing Flash is therefore a **client-side** problem.

## How the client talks to the server (verified from code)

- **Game traffic is AMF remoting over HTTP POST** to a single endpoint:
  `/files/empire-s.assets.zgncdn.com/assets/109338/127.0.0.1flashservices/gateway.php`.
  The odd path comes from the SWF itself: it contains the literal string
  `127.0.0.1` and appends `flashservices/gateway.php` without a slash, resolved
  relative to the SWF URL.
- Requests are batched: one AMF envelope targeting `BaseService.dispatchBatch`
  with a list of calls (`functionName`, `params`, `sequence`, ...). The server
  (`post_gateway()` in `empires-server.py`) answers with an AMF0 envelope holding
  one result per call. About 200 function names are handled; many return a
  dummy response.
- The client also needs:
  - HTTP GETs for `gameSettings.xml`, `127.0.0.1en_US.xml`,
    `127.0.0.1questSettings.xml` and asset SWFs under `/assets/...`.
  - **ExternalInterface calls to page JavaScript** that must return data:
    `getUserInfo()`, `getFriendData()`, `getAppFriendIds()`, `onGameLoaded()`
    (inline in `templates/home.html`), plus stubs in `templates/js/empires.js`
    (`ZYFrameManager`, `statTracker`, `zynga.ads...`, `hasPermission`, ...).
  - FlashVars: `serverTime`, `is_staging`, `debugMode`, `generateSchema`,
    `sn_app_url`, `stats`.

Any Flash replacement (Ruffle or a rewrite) must support these three things:
AMF over HTTP, the XML/asset loads, and the JS bridge.

## Options

### A. Run the original `.swf` with Ruffle (keep the client as-is)

- Ruffle is an open-source Flash Player emulator written in Rust, compiled to
  WebAssembly. It runs in modern browsers without plugins, either as a browser
  extension or embedded in a web page (self-hosted).
- Idea: serve the game page with Ruffle embedded, pointing at the original `.swf`,
  and keep talking to the Python server as today.
- **Pros**: smallest amount of work; original game logic and visuals unchanged.
- **Cons / risks**: Empires & Allies is a large AS3 game. Ruffle's AS3 support
  has been improving but is not guaranteed to cover everything this game uses
  (rendering, networking, AMF, external interface calls, etc.). Must be tested.
- **Upstream already started this.** Commit `941d79c` ("Ruffle initial work",
  AcidCaos, Sep 2025) added a `/ruffle.html` route and `templates/ruffle.html`.
  It is experimental: not linked from the UI, and `/home.html` still embeds the
  SWF for the Flash plugin. Differences from `home.html`:
  - Loads Ruffle from unpinned `https://unpkg.com/@ruffle-rs/ruffle`.
  - Creates the player with `RufflePlayer.newest().createPlayer()` and passes
    the FlashVars as `parameters` in `player.load()`.
  - Drops the Socket.IO debug panel and hides the loading overlay.
- Likely issues to check first in that page:
  - `allowScriptAccess: false` probably blocks the ExternalInterface calls the
    game depends on (`getUserInfo`, etc.). Try `true`/`"always"`.
  - Config key is written `LogLevel`; Ruffle's documented key is probably
    `logLevel`, so debug logging may not be active.
  - Unpinned CDN version: pin a version (or self-host) so results are
    reproducible.

### B. Rebuild the client in modern web tech (Phaser or PixiJS)

- Extract original assets (sprites, sounds, UI) from the `.swf` with a decompiler
  such as JPEXS Free Flash Decompiler.
- Rewrite the client in JavaScript/TypeScript:
  - **PixiJS**: rendering library; its display-object tree is close to Flash's
    stage/MovieClip model.
  - **Phaser**: full 2D game framework with tilemaps (incl. isometric), loaders,
    audio, input.
- The new client could keep talking to the existing Python server, reusing its
  data and endpoints. The server is client-agnostic apart from the data that
  `home.html` injects for the JS bridge, but a new client would need an AMF
  encoder/decoder in JS (or a new JSON endpoint added to the server).
- **Pros**: no emulator dependency; full control; can run on mobile.
- **Cons**: very large amount of work (essentially rewriting the whole game
  client, including UI, combat, and animation).

### C. Flashpoint Archive (reference only)

- Desktop launcher that preserves Flash games in a sandboxed environment.
- Not a fit for the goal (it's still a Flash runtime outside the browser), but
  worth knowing about.

## Unverified / to check before relying on it

- [~] **Does Ruffle run this game?** Yes, it loads and renders the world as of
      2026-10-20 (branch `ruffle-support`, see the test log). Gameplay is not
      play-tested yet.
- [x] **How the client talks to the server.** AMF remoting over HTTP POST to
      one gateway endpoint, batched calls. Socket.IO is debug-only. See
      "How the client talks to the server" above.
- [x] **Combat mechanics.** Verified in `battle_engine.py`: **turn-based**, one
      attack per `WorldService.resolveBattle` call; the server AI picks the enemy
      move. Hit quality (great/good/poor) comes from `combatChain` in
      `gamesettings-converted.json`, with thresholds in `combatHitValues`
      (glancing ×0.10, critical ×1.5). It is not a simple "Soldiers > Artillery >
      Tanks" triangle: e.g. infantry is great vs antitank and poor vs
      tank/artillery; artillery is great vs tank. Unit types: infantry,
      antitank, artillery, tank, fighter, airsupport, bomber, attackship,
      carrier, battleship, `mega_*` (Titan parts).
- [ ] **Asset rights.** The original art and sounds are Zynga's. Fine for
      personal tinkering; redistribution in a public remake is a separate
      question.

## Ruffle test log

Tested with Ruffle 0.7.1 (unpkg) in Brave/Chromium on Linux, branch `ruffle-support`.

1. **2026-10-20, upstream `ruffle.html` as-is.** SWF and the three XMLs load,
   then init stops with `Error #2067: The ExternalInterface is not available in
   this container` (from `MessageOfTheDayManager` → `ExternalInterface.addCallback`).
   Cause: `allowScriptAccess: false`. Fix: `true`.
2. **2026-10-20, with `allowScriptAccess: true`.** `getUserInfo` /
   `getFriendData` / `getAppFriendIds` are called and the HUD renders, then
   `Error #2126: NetConnection object must be connected` on the first AMF batch
   (`AMFConnection.call`). No request ever reaches `gateway.php`.
   Root cause (verified in Ruffle source and decompiled SWF):
   - `Config.SERVICES_GATEWAY_PATH` defaults to `"127.0.0.1" + "flashservices/gateway.php"`,
     a relative URL (Flash Player resolved it against the SWF URL).
   - Ruffle's `NetConnection.connect()` only connects for `http://`/`https://`
     URLs; anything else is a stub, so `call()` throws #2126.
   - The SWF reads a FlashVar `app_url` (`GlobalEngine.parseFlashVars`,
     `Zlab.parseFlashVars`) that overrides `BASE_PATH`, the gateway,
     `record_stats.php` and `GAME_SETTINGS_PATH`.
   Fix (no SWF change): pass `app_url=<origin>/` from `ruffle.html` and add
   root-level server aliases `/flashservices/gateway.php`, `/record_stats.php`,
   `/en_US.xml`, `/questSettings.xml`.
   Also found: the old `parameters` string had tab characters from JS line
   continuations, so the `serverTime` FlashVar never reached the game; and the
   config key `LogLevel` was ignored (Ruffle expects `logLevel`, default `error`).
3. **2026-10-20, with `app_url`.** The game now POSTs `UserService.initUser`
   to `/flashservices/gateway.php`, but the server returns 500:
   `AttributeError: 'int' object has no attribute 'functionName'`.
   Root cause (verified in Ruffle `core/src/avm2/amf.rs`): Ruffle serializes
   `NetConnection.call()` arguments as **AMF0**, where an AS3 Array becomes an
   ECMA array (pyamf: `MixedArray`, a dict `{0: ..., 1: ...}`) and ints become
   Numbers (floats). Flash Player sent AMF3 (real lists, real ints).
   Fix: `amf0_to_amf3_values()` in `empires-server.py` converts the decoded
   batch back (dense `MixedArray` → list, whole-number float → int) before
   dispatch. Tests: `test_amf0_to_amf3_values`, `test_post_gateway_ruffle_amf0`.
4. **2026-10-20, with `amf0_to_amf3_values()`. Milestone: the game loads in
   Ruffle.** The `Titan_alpha-test` world (level 75) renders with HUD values,
   buildings, units, animations and the neighbour bar. `initUser` round-trips
   (server AMF0 response is decoded fine by Ruffle).
5. **2026-10-20, new empire, tutorial.** Progress is lost on reload; the blue
   "pending" animation in the XP bar never stops. Evidence: `log.txt` shows
   only two gateway POSTs, then none for 21 minutes of play; the save still
   has `tutorialProgress: ''`. The second batch (`setCurrentCampaign`,
   `getRequestFriends`, `getUsersInvaderChallenges`) fails in Ruffle with
   `Deserialization not yet implemented for Reference` and then
   `TypeError #1009 ... (accessing field: uid) at TInitRequestFriends/onComplete()`.
   Root cause: pyamf writes an object that occurs twice in one AMF0 message as
   a reference (`friend_response` puts the same friend dict in several lists);
   Ruffle 0.7.1 can't read AMF0 references and yields null. The exception
   inside `TransactionManager.onAmfBatchComplete` leaves `m_batchedAmfCalls`
   non-empty, and `onAmfBatchSend` only sends when it is empty, so every
   later transaction stays queued client-side forever (and the pending
   indicator, `PlayerStatsUIItem.pending_mc`, keeps spinning).
   Fix: `unshare_amf_values()` copies the response so no object is shared
   before encoding. Test: `test_post_gateway_response_without_amf0_references`.
6. **2026-10-21, memory.** Tab memory grows steadily even while idle
   (~700 MB after load → 1.5 GB and rising). Likely cause: the game relies on
   weak references (1305 `addEventListener(..., false, 0, true)` calls in 404
   files, 17 `new Dictionary(true)`), and Ruffle has no weak GC references yet:
   `useWeakReference` is ignored (`event_dispatcher.rs`: "TODO: If we ever get
   weak GC references, we should respect `useWeakReference`") and weak-key
   Dictionaries are a stub (console: "Encountered stub: AVM2
   flash.utils.Dictionary constructor with weak keys"). Objects Flash Player
   would collect stay alive. Workaround: reload the page now and then
   (progress is server-side). Real fix belongs in Ruffle.
7. **2026-10-21, first battle.** The tutorial battle against Captain Krunsch
   works end to end in Ruffle (turns, Victory popup, XP/coins/Liberty Bond
   reward). The victory popup's villain image is missing:
   `assets/game/villains/defeats/VBossCPD_04A.swf` returns 404 because the
   file is not in any asset folder of this repo (only defeats 03, 05, 07, 08,
   10, 11, 14, 15 exist). Not Ruffle-related; Flash Player would get the same
   404.
8. **2026-10-26, quest Q0805 "Defensive Positions".** The client shows
   "Goal Completed" after moving an army unit, but the quest is back after a
   reload. Not Ruffle-related: the server's quest engine never implemented the
   `move` task action (only listed in a comment), so `performAction` `move`
   updated the position without progressing quests. Fix: `progress_move()` in
   `quest_engine.py` (matches optional `_item` / `_subtype`), called from the
   `move` step in `perform_world_response`. Covers Q0805 (`_subtype: army`) and
   QW126 (`_item: AU06`). Tests: `test_progress_move`,
   `test_perform_world_response_move_progresses_quest`.
9. **2026-10-26, black screen while building Small Cottages (Q3030).** The
   third cottage would have taken population from 270 to 310, over the
   population cap of 300. `SimpleClickState.onClick` then refuses the click
   (`checkWorkers()`: `maxWorkers + item.workers > maxWorkersCap`) and pushes
   `RequirementsPopup(RequirementsPopupInfoPopCap)`. That popup (and
   `OutOfUnitsPopup`) uses `assets/displays/dialogs/PU_OutOfResources.swf`,
   which returns 404: it is listed in the `assetIndex` (hash
   `a1892aee9288742cc954d2ddd4ed117b`) but exists in no asset folder of this
   repo. The screen dims for the popup and stays dark. Not Ruffle- or
   server-related; Flash Player would hit the same 404. The refused click was
   never sent, so the server's Q3030 progress (2/3) was correct.
   Workaround: reload, then raise the cap with a government building
   (`yield -workersCap`: Parliament +100, Executive Mansion +150 at level 5,
   Federal Courthouse +200 at level 7, ...) before building more houses.
   Possible fix later: a stand-in SWF with the instance names the popup class
   expects, or the original from another archive.
10. **2026-10-27, quest Q0810 "Invasion Protection".** Declaring neutrality at
   the World Embassy sends `PVPService.immunityStart`, which the server answered
   with a dummy response, so the quest's only task (`_action: startImmunity`)
   never progressed. The neutrality timer was also lost on reload: the client
   computes immunity locally (`PVPManager.startImmunity`: `expTS` = now +
   `PVPImmunityBaseDurations[immunityTimeVariant]`, `hIDs` = [player uid]) and
   only restores it from `user_object.pvp.immunity` in initUser, which the
   server always sent as `[]`. Not Ruffle-related. Fix:
   `immunity_start_response()` stores `{expTS, hIDs}` in `pvp.immunity` and
   progresses `startImmunity` quest tasks. Test:
   `test_immunity_start_response_progresses_quest`. Still a stub:
   `PVPService.immunityExtend` (hiring friends to extend neutrality). Same
   pattern as Q0805: the emulator still has many stubbed services, so expect
   more quests like this.
11. Next: keep play-testing (later quests, visiting a neighbour, invasions,
   Hire Friends) and note what breaks.

### Missing original assets (404s seen so far)

Searched without success (2026-10-26): the Wayback Machine has only 10 files
from `empire-s.assets.zgncdn.com` (8 PNG, 2 XML, no SWF), and
`AcidCaos/empires-revision-history` has 32 SWFs but neither of these.

| Asset | Effect | Status |
|---|---|---|
| `assets/game/villains/defeats/VBossCPD_04A.swf` | Victory popup after beating Captain Krunsch has no villain image | Missing (cosmetic) |
| `assets/displays/dialogs/PU_OutOfResources.swf` | Population-cap and out-of-units popups (`RequirementsPopup`, `OutOfUnitsPopup`) never appear; screen stays dimmed until reload | Stand-in built with Haxe, see `build-tools/missing-assets/`; verified 2026-10-27 in Ruffle ("Too Many Houses!" popup shows game texts and icons) |

Dev gotcha: the Werkzeug reloader (`--debug`) can miss a second edit made
within ~1 s of the first, leaving the server on half-updated code. If a fix
seems to have no effect, `touch empires-server.py` or restart the server.

Decompiled AS3 (JPEXS FFDec 26.4.0 CLI, `-export script`) is useful for the
next errors: `java -jar ffdec-cli.jar -export script <outdir> ZGame.swf`
(~30 s, 2178 scripts). Keep the output outside the repo (Zynga code).

## Suggested next steps

1. ~~Get the current repo running as-is.~~ Done 2026-10-20 for the server side:
   venv (Python 3.12), 49 tests pass, server answers on `127.0.0.1:5005`,
   AMF `initUser` works. The Flash-plugin client was not tested (no Flash in
   modern browsers). Setup steps are in `CLAUDE.local.md`.
2. Open `/ruffle.html` in a modern browser with devtools open. Note what breaks
   (console errors, network requests to `gateway.php`, whether `getUserInfo`
   is called).
3. Fix the obvious config issues in a local branch (`allowScriptAccess`,
   `logLevel`, pinned Ruffle version) and retest.
4. Depending on results, either work around Ruffle issues (Option A) or scope a
   small prototype of Option B (e.g., render one base map with extracted
   assets).
