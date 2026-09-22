# GAMDES1

## Lab 3: minimal core-loop prototype

**Core mechanic:** inspecting one customer at the store counter and deciding whether to serve or refuse them.

**The loop:** input is a key press, L to read Lola's ledger, S to serve, R to refuse. The action is the decision, which resolves the encounter against the customer's hidden identity. The feedback is on screen at once: the ledger line appears, the customer panel changes colour, a result line says what happened, and Pesos, Sanity, and the correct-call count update. The next customer then arrives and the loop repeats from the same starting state.

**No countdown.** An earlier version timed out a customer after 30 seconds. Playtesting showed a visible clock pushed the game toward reflexes instead of the slow-burn dread the design is aiming for, so the timer is removed. The player can take as long as they want on each customer; tension now comes from doubt and sound, not a number running down.

**Run it:** open the project in Godot 4.x and press F5.

| Key | Action |
|---|---|
| L | Read Lola's ledger for this customer |
| S | Serve the customer |
| R | Refuse the customer |

**Art:** the counter and shutter background is a groupmate's concept sketch, placed as-is for this prototype.

**Left out on purpose:** the day phase, the UV lamp and battery, salt and banishing, utang, the Presence meter, the night clock, sound, and art. This build only proves that inspect, decide, and feedback connect.
