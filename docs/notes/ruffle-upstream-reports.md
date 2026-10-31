# Ruffle upstream reports (drafts)

_Drafted 2026-10-31. To be reviewed and posted manually on
https://github.com/ruffle-rs/ruffle from my own account._

Duplicate check done on 2026-10-31 (GitHub search):

| Topic | Existing report | Action |
|---|---|---|
| AMF0 Reference (`0x07`) in remoting replies becomes `undefined` | none found | **new issue** (draft 1) |
| `NetConnection.connect()` with a relative URL is a stub | #23201 (open, 0 comments) | **comment** (draft 2) |
| Remoting always sent as AMF0, ignoring `objectEncoding` | #24697 (open, 0 comments) | **comment** (draft 3) |
| Memory growth (weak refs not implemented) | PR #23897 (open, weak `Dictionary`, weak listeners, `System.gc()`), issue #24864 (per-movie libraries from `Loader`) | **comment on PR #23897** (draft 4) |

Repro files: `docs/notes/ruffle-repro/` (`Repro.hx`, `server.py`, prebuilt `repro.swf`).
Attach `repro.swf` + `server.py` (zipped) to draft 1; GitHub does not accept `.swf` directly.
They contain no game assets, only our own code.

Verified with: Ruffle web 0.7.1 and 0.8.0-nightly.2026.10.31 (wgpu-webgl renderer),
Brave 156.1.98.60 (Chromium), Fedora 43.

---

## Draft 1: new issue

**Title:** AVM2 Flash Remoting: AMF0 object references (type 0x07) in responses deserialize as `undefined`

**Describe the bug**

When a Flash Remoting (`NetConnection.call`) response is AMF0-encoded and the
same object appears more than once, the encoder writes the second occurrence as
an AMF0 Reference (type marker `0x07` + u16 index, AMF0 spec section 2.9).
Flash Player resolves it to the earlier object. Ruffle turns it into
`undefined` and logs:

```
ERROR core/src/avm2/amf.rs:511 Deserialization not yet implemented for Reference: Reference(Reference(1))
```

The relevant branch on master is in `deserialize_value_impl` (`core/src/avm2/amf.rs`):

```rust
AmfValue::Reference(_) => {
    tracing::error!("Deserialization not yet implemented for Reference: {:?}", val);
    Value::Undefined
}
```

`object_map` is already filled for `Object`/`ECMAArray`/`StrictArray`, and
`Amf3ObjectReference` already uses it, so the AMF0 case may only need a lookup
by the reference index in the same table.

This is common in practice: PyAMF/Py3AMF (and other remoting servers)
de-duplicate repeated objects by default. In our case (Empires & Allies, a
Zynga game revived by the [Raise the Empires](https://github.com/AcidCaos/raisetheempires)
server emulator) the `getRequestFriends` reply put the same friend object in
several lists, so later entries became `null`, the game's response handler threw
(`TypeError #1009 ... accessing field: uid`), and its transaction queue stopped
forever (nothing was saved after that). We work around it server-side by deep-copying
the reply before encoding, so no references are written.

**Minimal repro** (attached zip: `repro.swf`, `Repro.hx`, `server.py`)

The server answers `Echo.shared` with `{first: shared, second: shared}`, where
both properties are the same object.

```
pip install py3amf
python server.py 8765
# open: http://127.0.0.1:8765/?gateway=http://127.0.0.1:8765/gateway
# optional: &ruffle=nightly to load another @ruffle-rs/ruffle version from unpkg
```

Output in Ruffle 0.7.1 and 0.8.0-nightly.2026.10.31:

```
result: first.name=shared, second=null
```

<details><summary>Repro.hx</summary>

```haxe
PASTE docs/notes/ruffle-repro/Repro.hx HERE
```
</details>

<details><summary>server.py</summary>

```python
PASTE docs/notes/ruffle-repro/server.py HERE
```
</details>

**Expected behavior**

`second` is the same object as `first` (Flash Player output would be
`result: first.name=shared, second=[object Object], second.name=shared`).

**Content Location**

Minimal repro attached. Real-world content: https://github.com/AcidCaos/raisetheempires
(any reply in which the server repeats an object, e.g. `getRequestFriends`).

**Affected platform**: Self-hosted version

**Operating system**: Fedora 43 (Linux)

**Browser**: Brave 156 (Chromium)

**Additional information**

Not tested on desktop. The AVM1 side was not checked.

---

## Draft 2: comment on #23201

> NetConnection.connect() not resolving relative URLs / dropping HTTP calls

Another real-world case, and I can confirm the diagnosis above. Empires & Allies
(Zynga, revived through the https://github.com/AcidCaos/raisetheempires server
emulator) builds its gateway URL relative to the SWF, so `connect()` gets a
relative path such as `127.0.0.1flashservices/gateway.php`.

Still reproducible with Ruffle web 0.7.1 and 0.8.0-nightly.2026.10.31:

```
WARN core/src/stub.rs:144 Encountered stub: AVM2 flash.net.NetConnection.connect() with non-null, non-http command
ArgumentError: Error #2126: NetConnection object must be connected.
    at flash.net::NetConnection/call()
```

No request is ever sent. Flash Player resolves the URL against the SWF URL and posts to it.

Minimal repro: `connection.connect("gateway"); connection.call("Echo.shared", responder);`
(SWF + 50-line Python server attached in #NNNN, open `/?gateway=gateway`).
Passing an absolute URL (`/?gateway=http://127.0.0.1:8765/gateway`) works.
We work around it by passing an absolute base URL in a FlashVar the game already supports.

_(Replace #NNNN with the number of the issue from draft 1 once it is posted.)_

---

## Draft 3: comment on #24697

> AVM2 NetConnection ignores `objectEncoding` (AMF3 Remoting)

Another case: Empires & Allies (Zynga, AS3) never sets `objectEncoding` at all
(`new NetConnection()` then `connect()`), so Flash Player uses the AS3 default
`ObjectEncoding.AMF3`. Ruffle 0.7.1 and 0.8.0-nightly.2026.10.31 send AMF0
instead, so our PyAMF-based server
(https://github.com/AcidCaos/raisetheempires) received:

- AS3 `Array` arguments as AMF0 ECMA arrays (PyAMF `MixedArray`, dict-like) instead of lists;
- `int` values as AMF0 numbers (floats).

The game's single remoting call, `BaseService.dispatchBatch`, takes an array of
calls, so every batch failed until we converted those values on the server.
This confirms the issue also affects SWFs that rely on the default encoding.

---

## Draft 4: comment on PR #23897

> core: Memory-leak fixes for long-running ActionScript 3 workloads

A data point from a game rather than Flex, in case it helps to prioritise this.

Empires & Allies (Zynga, AS3, revived through https://github.com/AcidCaos/raisetheempires)
leans on exactly the three contracts this PR implements: the decompiled client has
1,309 `addEventListener(..., useWeakReference = true)` calls, 17 `new Dictionary(true)`
and 2 `System.gc()` calls.

In Ruffle web the browser tab grows without bound, even when the game sits idle on
its main map. After a long play session it reached about 3 GB, and the game gets
laggy until the page is reloaded. Measured idle (no input) in headless Chromium,
renderer process RSS, between roughly 100 s and 260 s after load:

| Variant | Ruffle | Growth | Frame rate |
|---|---|---|---|
| default (wgpu-webgl, quality high) | 0.7.1 | 2.7 MB/s | ~12 fps |
| `logLevel: "error"` | 0.7.1 | 2.7 MB/s | ~12 fps |
| default | 0.8.0-nightly.2026.10.31 | 2.6 MB/s | ~11 fps |
| `quality: "low"` | 0.7.1 | 2.7 MB/s | ~17 fps |
| `preferredRenderer: "canvas"` | 0.7.1 | ~1.6 MB/s | ~6 fps |

The JS heap stays at about 6 MB and the DOM node count is flat, so the growth is
inside the wasm instance. The rate is about the same per second whatever the frame
rate, log level or quality, and the current nightly behaves like 0.7.1. GPU process
memory stays flat. I can't prove the weak references are the cause, but the game
registers weak listeners on many short-lived display objects, which matches the
pattern described here.

If there is a web build of this branch I can run the same measurement against it
and report back.
