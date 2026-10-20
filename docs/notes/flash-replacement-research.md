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
5. Next: play-test core actions (collect, build/move, quests, a battle,
   visiting a neighbour, save/reload) and note what breaks.

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
