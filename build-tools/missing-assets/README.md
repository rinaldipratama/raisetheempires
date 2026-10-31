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

## UnitsPurchaseDialog

`assets/displays/screens/UnitsPurchaseDialog.swf`, the "Buy Units" dialog in
battle setup (buy units with cash). Without it the screen stays dimmed.

```bash
cd build-tools/missing-assets/UnitsPurchaseDialog
haxe build.hxml
```

`UnitsPurchaseDialog` hands `MainScreen_mc` to `ChallengePremiumUnitsGrid`, a
5 x 2 `GridScreen` whose cards come from the exported class `PremiumUnitCard`
(`GridSlot.createSlot` uses `new PremiumUnitCard().card_mc`). Contract:

```
MainScreen_mc
├── background_mc                     width/height size and center the dialog
├── caption_tf, header_tf             texts set by the game
├── exit_bt                           close
├── origin_mc                         grid anchor position
├── anchor_mc                         cards are added here; slides a page at a time
├── mask_mc                           clips anchor_mc to 5 x 2 cards
└── arrowLt_bt, arrowRt_bt            paging
PremiumUnitCard
└── card_mc                           cards are placed at index × sizer_mc size
    ├── sizer_mc, selected_mc, highlightSelect_mc
    ├── buy_bt └── generic_tf         ZGameButton "Buy for N"
    └── unitCard_mc
        ├── itemName_tf, strengthValue_tf, energyValue_tf, cost_tf, discount_tf, levelInfo_tf
        ├── icon, strengthIcon_mc, energyIcon_mc, cashIcon_mc   fl.containers.UILoader instances
        └── locked_mc, strengthBar_mc, secondaryCard_mc
```

`card_mc` and `unitCard_mc` are plain `MovieClip`s with their children set as
dynamic properties, because the game also probes optional children
(`tierRating_mc`, `doubleXP_mc`, ...) that would throw on a sealed Haxe class.

## VillainDefeats

Twelve villain defeat clips (seven `assets/game/villains/defeats/VBossCPD_*A.swf`,
five `assets/game/villains/Campaign02_Defeats/*_Defeat.swf`) shown in the victory
popup after beating a campaign villain. Without them the villain spot stays empty.

```bash
cd build-tools/missing-assets/VillainDefeats
python build.py
```

The victory popup (`BattleBasePopup`) loads the SWF and adds its root clip. The
stand-in root draws a round frame and fills it with the villain's portrait
(`Villains01.swf/VP_04.png`, `Campaign02_Villains.swf/ZombiePolaroid_124.png`,
...). No game art is copied into these SWFs.

The game loads asset SWFs with `Loader.loadBytes` and no `LoaderContext`, so each
gets its own child `ApplicationDomain` and the portrait classes are not visible
from the stand-in. It fetches the portrait like the game's `SWFImageLoader`:
`Zlab.resourceManager.load(...)` (cached) and `SWFResource.getAssetClass(...)`.

`build.py` makes a per-villain class the SWF's root via the `SymbolClass` tag, so
the clip draws itself when the game instantiates it.
