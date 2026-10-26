# Stand-ins for missing original assets

Some original Empires & Allies assets were never recovered (they are listed in
`gameSettings.xml`'s `assetIndex` but exist in no asset folder). When the game
requests one it gets a 404, which can leave a dialog half-open. The folders here
hold source for minimal stand-ins written from scratch (no Zynga content). They
only reproduce the structure the game client expects; texts and icons are still
supplied by the game.

## PU_OutOfResources

`assets/displays/dialogs/PU_OutOfResources.swf`, used by `RequirementsPopup`
(population cap reached, e.g. finishing a house would exceed the worker cap) and
`OutOfUnitsPopup`. Without it the screen stays dimmed until the page is reloaded.

Build (needs [Haxe](https://haxe.org/) 4.x, e.g. `sudo dnf install haxe`):

```bash
cd build-tools/missing-assets/PU_OutOfResources
haxe build.hxml
```

This writes `assets/sol_assets_octdict/assets/displays/dialogs/PU_OutOfResources.swf`,
the path the server serves `/nullassets/displays/dialogs/PU_OutOfResources.swf` from.

Contract with the game client (exported class and child names it looks up):

```
MainScreen_mc
├── frame_mc                         width/height used to size and center the popup
├── accept_bt  └── generic_tf        ZGameButton; label set by the game
├── exit_bt                          close (hidden by OutOfUnitsPopup)
├── title_tf, bubble_tf, desc_tf     texts set by the game
├── steps_2_mc └── icon0_mc, icon1_mc            fl.containers.UILoader instances
└── steps_3_mc └── icon0_mc, icon1_mc, icon2_mc
```

Asset SWFs are loaded into the game's `ApplicationDomain`, so class names here
must not clash with the game's own classes.
