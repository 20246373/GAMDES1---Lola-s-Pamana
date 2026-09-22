Tindahan: Lola's Ledger

Game Design Document. GAMDES1, first semester 2026 to 2027.

1. High Concept

Premise. You inherit your late grandmother's sari-sari store, a small neighborhood shop on a foggy road in Baguio, and you keep it open through the night.

Hook. The customers at your iron grille are not all human. Aswang copy your neighbors, but they always get one detail wrong, and the only record of what your neighbors actually buy and owe is Lola's utang ledger.

Player fantasy. You are the one person awake in the barangay, judging every face that comes to the window, with a notebook as your only proof.

2. Formal Elements

Players. One player, single-player and offline. The player is Lola's grandchild, alone in the shop. The opponent is the game system, which controls the customers and the clock.

Objectives. Survive five nights. Reach 6 AM on Night 5 with Sanity above 0. Along the way, earn Pesos and learn which regular buys what, so copies can be caught.

Rules.

Customers arrive one at a time and each waits 30 seconds.
Each customer is a human neighbor or an entity in disguise. The player is never told which.
Lola's ledger records what each regular always buys. An entity copying a regular asks for the wrong item.
Reading the ledger is free and takes the player's eyes off the grille.
Each customer ends with exactly one decision, serve or refuse.
Serving an entity or letting one time out costs 30 Sanity. Refusing a real neighbor costs 10 Sanity.
The night is lost when Sanity reaches 0.

Procedures. The night starts and the first customer steps up to the grille. The player reads the name and the order, opens the ledger to compare the order with what that regular always buys, decides to serve or refuse, sees the result, and waits for the next customer. This repeats until dawn.

Resources.

Resource	Source	Sink	Start
Pesos	Serving a human, 20 each	Supplies bought between nights	150
Sanity	Rest at dawn, 25	Wrong calls and timeouts	100
Patience	Resets with each customer	Runs down while the player thinks	30 s

Conflict. Entities copy neighbors, so the player can never be certain. Patience runs out while the player reads. Refusing a neighbor hurts and serving an entity hurts more, so there is no safe default.

Boundaries. The player never leaves the counter. The world is the counter and the street seen through the iron grille. Play runs from 6 PM to 6 AM across five nights.

Outcome. The player wins by reaching 6 AM on Night 5 with Sanity above 0. A run with 60 or more Sanity and at least 24 of 30 correct calls reveals Lola's secret ledger page in full. The player loses when Sanity reaches 0, and the night restarts.

3. Core Gameplay Loop

The loop is one customer encounter, and it is the loop built in the Lab 3 prototype.

Input. A customer stands at the grille with a name and an order. The player presses L to read the ledger, then S to serve or R to refuse.
Action. Reading the ledger shows what that regular always buys, so the player can see whether the order matches. The serve or refuse decision resolves the encounter against the customer's hidden identity.
Feedback. The ledger line appears on screen, the customer panel changes colour, a result line says what happened, and Pesos, Sanity, and the correct-call count update at once.
Repeat. After a short pause the next customer arrives and the loop starts again from the same state.

One pass takes 30 to 35 seconds of activity, then quiet waiting until the next customer arrives.

Why it is worth repeating. Every pass is a small judgement with a cost on both sides, and the ledger makes the player look down at the exact moment they feel they should be watching the window. As the nights go on the player learns the regulars, which makes each copy easier to catch and each mistake harder to forgive.

What the prototype leaves out. The day phase, the UV lamp and its battery, salt and banishing, utang, the Presence meter, the night clock, sound, and art. The prototype only proves that inspect, decide, and feedback connect.

Revision note

Change made after the peer read-around:

After the peer read-around, It was pointed out that the patience timer felt somewhat unaligned for the slow burn dread the team aimed for. We will remove the patience timer in response.
