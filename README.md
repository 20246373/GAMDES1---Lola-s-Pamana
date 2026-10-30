# Tindahan: Lola's Pamana

A 2D first-person Filipino horror game built in Godot 4.7 by Ben & Beni for GAMDES1, BSCS IAC1, University of Baguio.

By day you buy supplies and chat with the regulars to fill Lola's ledger. By night you serve customers through the iron grille and use the ledger and a UV lamp to tell neighbors from the aswang, tiktik, kapre, and manananggal. Survive five nights until 6 AM.

The Game Design Document is the source of truth for every rule and number in this build. This README maps the build to GDD Sections I to VIII.

## Run it

1. Install Godot 4.7.
2. Open the repository root folder in Godot. The project file is `project.godot` at the root.
3. Press F5.

The renderer is GL Compatibility and the window is 1280 x 720, scaled to fill any 16:9 screen. The Lab 3 prototype in `lola-s-pamana-lab3/` is kept as submitted. Godot skips that folder because it has its own `project.godot`.

## Controls, Table 21

Every action goes through a named Input Map action in Project Settings. No script checks a key directly.

| Action | Input Map action | Mouse | Keyboard |
|---|---|---|---|
| Aim and use the UV lamp | `uv_lamp` | Hold the right button, or click and hold on a face, cash, or the open ledger | Hold Space |
| Open or close the ledger | `ledger` | Click the ledger | L |
| Serve | `serve` | Click the cash drawer | S |
| Serve on utang | `serve_utang` | Click the pen on the utang page | U |
| Refuse | `refuse` | Click the shutter rope twice, or drag it down | R |
| Banish | `banish` | Click the salt jar | B |
| Radio on or off | `radio` | Click the radio | T |
| Pause | `pause` | | Esc or P |
| Buy Salt, battery pack, salabat | `buy_1`, `buy_2`, `buy_3` | Click the item | 1, 2, 3 |
| Chat with a regular | `chat` | Click the regular | Tab to choose, then Enter |
| Press a menu button, Retry, or Next | `confirm` | Click the button | Tab to choose, then Enter |
| Click a counter object | `interact` | Left button | |

At 6 PM the shutter is down. Click the shutter rope, or press R, to open the store and start the night clock.

Every clickable counter object glows and shows its name on hover, and the decision objects glow softly while a customer waits. The UV lamp shows a box around the spot being scanned, a ring that fills over 2 seconds, and the result. The UV scan list at the top right keeps each result for the current customer, so no clue depends on sound.

How to Play in the main menu and the pause menu explains the goal, the tells, and the four choices. With Control hints on in Settings, short hints and key labels show on screen. Turn them off to play the way GDD 5.4 describes, with the level teaching every mechanic.

## Performance

The game is split into small scenes. `main.tscn` holds only Main and the pause menu. Each screen is its own scene file that Main loads when it is shown and frees when the player leaves it, so only one screen is ever in memory. The counter tools are their own scenes in `scenes/tools/`.

Low graphics in Settings is on by default. It turns off the two 2D lights and the street fog and draws a cheap glow instead, which keeps the night smooth on Chromebooks. Turn it off on a strong PC for full lighting. If frames start to lag with full lighting, the night switches back to low graphics by itself. The game is capped at 60 frames per second, and each night loads its customers' art at 6 PM before the shutter opens.

Only the part of the street behind the window is drawn, by night and by day, so slow GPUs do less work. The game uses resized copies of the art in `art/`. The originals in `Gamedes Game Assets/` stay at full size for the artists, and Godot skips that folder, so the first import is fast.

## Scene tree, Figure 8

| Scene | Root | Notes |
|---|---|---|
| `scenes/main.tscn` | Main, Node | Runs first. Holds only the pause menu and loads one screen scene at a time. |
| `scenes/main_menu.tscn` | MainMenu, Control | Play, Continue, How to Play, Settings, Credits, Exit |
| `scenes/day_phase.tscn` | DayPhase, Control | Catalogue GridContainer and Visitors HBoxContainer |
| `scenes/counter.tscn` | Counter, Node2D | The night scene. Assembles the store, the customer, the ledger, the HUD, and the tool scenes. |
| `scenes/tools/desk_lamp.tscn` | DeskLamp, PointLight2D | The dim desk lamp |
| `scenes/tools/uv_lamp.tscn` | UVLamp, PointLight2D | The UV lamp and its Beam, Area2D |
| `scenes/tools/cash_drawer.tscn` | CashDrawer, Area2D | Serve |
| `scenes/tools/salt_jar.tscn` | SaltJar, Area2D | Banish |
| `scenes/tools/shutter_rope.tscn` | ShutterRope, Area2D | Refuse, and the shutter |
| `scenes/tools/radio.tscn` | Radio, Area2D | The radio and its Music player |
| `scenes/customer.tscn` | Customer, Node2D | Body, SignLayer, Cash, Voice, Anim. One instance, rebuilt from each data row. |
| `scenes/ledger.tscn` | Ledger, Control | Page, Entry, Smear, UtangPen |
| `scenes/hud.tscn` | HUD, CanvasLayer | Pesos, Sanity, Battery, SaltCount, Caption |
| `scenes/dawn_report.tscn` | DawnReport, Control | CallList, LolaPage, NextButton |
| `scenes/end_screen.tscn` | EndScreen, Control | Good, bittersweet, Breakdown, and Breach screens |
| `scenes/pause_menu.tscn` | PauseMenu, CanvasLayer | Resume, How to Play, Settings, Main Menu |
| `scenes/how_to_play.tscn` | HowToPlay, PanelContainer | Used by the main menu and the pause menu |

Autoloads:

- `GameState`, in `scripts/game_state.gd`. Holds the six resources, the correct calls, and the night number. It is the only node that changes a resource.
- `CustomerData`, in `scripts/customer_data.gd`. Loads the 30 customer rows from `data/customer_table.tres`.

## Signals, Table 22

All 13 signals are declared on the nodes the GDD names and connected to the same receivers.

| Signal | Emitted by | Connected to |
|---|---|---|
| `day_finished` | DayPhase | Main |
| `customer_arrived` | Counter | Customer, Ledger, HUD |
| `uv_hit` | UVLamp/Beam | Customer, Ledger |
| `radio_toggled` | Radio | GameState, Counter |
| `warning_played` | Counter | DeskLamp, HUD |
| `decision_made` | CashDrawer, UtangPen, ShutterRope, SaltJar | Counter |
| `call_resolved` | Counter | GameState, Customer |
| `resource_changed` | GameState | HUD, UVLamp |
| `presence_changed` | GameState | Silhouettes |
| `night_lost` | GameState | Main |
| `night_survived` | Counter | Main |
| `game_finished` | GameState | Main |
| `pause_toggled` | PauseMenu | Main |

The shutter rope also sends `decision_made` with the value `open` when it raises the shutter at 6 PM. Requests that are not in Table 22, such as buying in the day or draining the UV battery, are calls to GameState, which stays the only node that changes a resource.

## The data table

`data/customer_table.tres` holds the 30 rows from Section II and Table 10: 4, 5, 6, 7, and 8 customers on Nights 1 to 5, with 12 entities split 1, 2, 2, 3, and 4. Each row sets the customer, the order from the nine goods on the price list, the payment, the tells, the warning and decoy pools, the replaceable slot, and the tampered entry. The scripted teaching beats in Table 11 are tagged on the rows.

`CustomerData.make_plan` does the shuffles in 6.4 from the run seed. Warnings and decoys keep their fixed counts per night, and only who gets them is shuffled. A retry replays the same seed. A tester can set a seed in Settings to repeat a run.

## Placeholders to replace

These match the asset gaps the team listed. Each one is drawn in code so it can be swapped for art later.

- Ledger page, utang pen, and smear glow
- UV lamp cursor and beam
- Cash drawer, bills, coins, and leaves
- Salt jar level and the salt line on the sill
- Radio and the roll-down shutter with its rope
- Stranger looks, which tint `maleSprite.png`
- Mang Ador talks with a small bob until his talking sprite exists
- Folklore signs under the UV lamp are drawn over the face. The entity art in `Kapre-Dugang Entities/` shows on a jump scare and on a correct Banish.
- All audio. AI-assisted, created by the team with Python: `tools/make_audio.py` synthesizes every sound and the radio music. Run it with Python 3, numpy, and scipy. Replace the files in `audio/` with chosen audio and list the sources in Table 23.

Lola's dawn pages, the ending text, and the six chat lines are drafts in `scripts/story.gd` and `scripts/customer_data.gd` for the narrative designer to revise.
