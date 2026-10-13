# Tindahan: Lola's Pamana

**Game Design Document: Lab 4 draft (High Concept, Formal Elements, Core Loop)**

## Development Team

| No. | Member Name (Surname, First Name) |
| :-- | :-- |
| 1 | Bencila, Adrian Marc C. |
| 2 | Grueso, Angel Mae T. |
| 3 | Noefe, Judah Zoe Athaliah G. |
| 4 | Osting, Nadine Kyla G. |
| 5 | Rivera, Benedict D. |

---

## 1. High Concept

**Guiding concept: every customer is a neighbor until Lola's ledger says otherwise.**

**High-concept statement.** You inherit your late grandmother's sari-sari store in foggy Baguio and keep it open through the night. Aswang come to the iron grille wearing your neighbors' faces, and the only proof of who is real is Lola's utang ledger and a UV lamp. You are the last person awake in the barangay, deciding who gets served and who gets shut out.

| Part | Description |
| :-- | :-- |
| **Premise** | You inherit your late grandmother's sari-sari store, a small neighborhood shop on a foggy road in Baguio, and you keep it open through the night. |
| **Hook** | The customers at your iron grille are not all human. Aswang copy your neighbors, but they always get something wrong, and the only record of what your neighbors actually buy and owe is Lola's utang ledger. |
| **Player fantasy** | You are the one person awake in the barangay, judging every face that comes to the window, with a notebook as your only proof. |

### 1.1 How the concept drives the design

| Concept idea | Mechanic it creates |
| :-- | :-- |
| **"Every customer is a neighbor"** | No customer is labeled. The player judges each one at the grille, and every decision has a cost on both sides. |
| **"Lola's ledger"** | The ledger records each regular's usual order and debt, plus a personal detail learned in day chats. A mismatch is a tell. |
| **"Until the ledger says otherwise"** | One clue is never proof. Two tells confirm an entity, and from Night 4 the ledger itself can be tampered with. |
| **"The last person awake"** | One fixed view behind the counter. Darkness, silence, and the desk lamp shape the fear. |
| **"Utang" (Lola's legacy)** | Serving on credit buys safety tonight, but an entity served this way comes back tomorrow. |

### 1.2 Audience and novel angle

**Audience.** Players aged 15 to 30, mainly Filipino, who grew up with the corner sari-sari store, buying on utang, and aswang stories. The familiar setting becomes the source of fear.

**Novel angle.** Inspection games such as Papers, Please check documents from a government booth. Our evidence is a hand-written credit ledger, built from day chats the player chooses, and it can lie. Utang adds a second layer, because a kind act tonight can invite danger back tomorrow.

---

## 2. Formal Elements

### Players

One player, single-player and offline. The player is Lola's grandchild, alone behind the counter. The opposing side is the game system, which sends the customers and decides which are entities.

### Objectives

- **Main goal:** survive five nights by reaching 6 AM on Night 5 with Sanity above 0 and Presence below 3.
- **Supporting goals:** earn Pesos for supplies, learn each regular's habits, and make enough correct calls to read Lola's secret ledger page in full.

### Rules

1. **Days and nights.** Five of each. A day takes 60 to 90 seconds. A night runs from 6 PM to 6 AM, and 6 AM arrives when the last customer leaves.
2. **Day phase.** Buy Salt, UV battery packs, or salabat, and chat with up to two of three visiting regulars. Each chat adds that regular's personal detail to the ledger.
3. **Customers.** Nights 1 to 5 bring 4, 5, 6, 7, and 8 customers (30 total, 12 of them entities). The next customer arrives after a quiet gap that shrinks from 45 seconds on Night 1 to 10 seconds on Night 5.
4. **No customer timer.** A customer waits until the player decides.
5. **Hidden identity.** Each customer is a human or an entity. Aswang mimics copy a regular. Shadow entities arrive as strangers. The game never says which is which.
6. **Tells are visual.** The ledger shows a wrong order, debt, or personal detail. The UV lamp shows marks on a face or cash after about 2 seconds of light.
7. **Rule of two.** An entity always shows two tells. Strangers have no ledger entry, so both of their tells show under the UV lamp. From Night 2, one in three humans shows one decoy tell, so one tell only raises suspicion.
8. **Ledger tampering.** From Night 4, one entry per night is smeared and does not count as a tell.
9. **Radio.** Radio off drains 1 Sanity every 30 seconds but plays warning sounds, which are hints, never proof. Radio on means no drain and no warnings.
10. **One decision per customer.** Serve, Serve on utang, Refuse, or Banish (Table 1). Each refused entity lingers outside as 1 Presence, and 3 Presence is a Breach.

### Procedures

**Setup:** six regulars in the ledger, 150 Pesos, 100% UV battery, 3 Salt, 100 Sanity, 0 Presence, 0 Utang.

1. Day: buy supplies and chat with up to two regulars.
2. 6 PM: the checkpoint saves. Choose radio on or off.
3. A customer gives a name, an order, and a payment.
4. Inspect for as long as needed: ledger, UV lamp, listening.
5. Make one decision and apply its result from Table 1.
6. If Sanity is 0 or Presence is 3, retry the night. Otherwise wait for the next customer.
7. 6 AM: collect repaid utang, reset Presence, add 25 Sanity, read the dawn report and Lola's page. Stop after Night 5.

### Resources

Pesos, Sanity, UV battery, Salt, Presence, and Utang (Table 2).

### Conflict

- **Doubt:** entities copy neighbors, humans can show decoys, warnings can be wrong, and the ledger can lie.
- **No safe default:** refusing a neighbor costs Sanity, serving an entity costs more, and refusing every entity fills Presence.
- **Limited tools:** battery and Salt cost Pesos, and listening costs Sanity.
- **Rising pressure:** more customers, more entities, and shorter gaps each night.

### Boundaries

The player never leaves the counter. The world is the counter, the shelf, and the street through the iron grille. Five days and five nights. No combat, walking, or exploration.

### Outcome

- **Good ending:** reach 6 AM on Night 5 with 60 or more Sanity and at least 24 of 30 correct calls. Lola's secret page is shown in full.
- **Bittersweet ending:** reach 6 AM on Night 5 with less Sanity or fewer correct calls. The page is torn.
- **Loss:** Sanity reaches 0 (Breakdown) or Presence reaches 3 (Breach). Retry the night from 6 PM.

A call is correct when the player serves a human, or refuses or banishes an entity.

**Table 1.** Decision outcomes.

| Decision | Customer is human | Customer is an entity | Limit |
| :-- | :-- | :-- | :-- |
| **Serve** | Earn the item price | Lose 30 Sanity and a jump scare | None |
| **Serve on utang** | Pays the price plus PHP 5 at dawn | No loss now, but it returns next night with both tells under the UV lamp | 2 per night, none on Night 5 |
| **Refuse (shutter)** | Lose 10 Sanity and the sale | Gain 1 Presence | None |
| **Banish (salt)** | Lose 20 Sanity and the sale | Gain 5 Sanity, gone for good | Uses 1 Salt |

**Table 2.** Resources.

| Resource | Start value | Gained from | Lost to | Cap |
| :-- | :-- | :-- | :-- | :-- |
| **Pesos** | 150 | Sales to humans (PHP 5 to 20), repaid utang | Salt PHP 15, battery PHP 25, salabat PHP 20 | None |
| **Sanity** | 100 | Dawn +25, salabat +10, correct Banish +5 | Serving an entity -30, wrong Banish -20, wrong Refuse -10, radio off -1 per 30 s | 100 |
| **UV battery** | 100% | Battery pack +50% | 2% per second of use | 100% |
| **Salt** | 3 | Bought by day | 1 per Banish | 6 |
| **Presence** | 0 | +1 per refused entity | Reset at 6 AM | 3 = Breach |
| **Utang** | 0 | +1 per Serve on utang | Repaid at dawn, or cleared when an entity returns | 2 per night |

### 2.1 Story, aesthetics, technical constraints, and scope

| Area | Description |
| :-- | :-- |
| **Story** | The player keeps Lola's store open after her death. Each dawn reveals one page of her writing, and after Night 5 the player reads her secret ledger page, in full or torn depending on how well they played. No cutscenes. |
| **Aesthetics** | Main kinds of fun: Challenge, Fantasy, and Discovery. Supporting: Sensation and Narrative. Target feeling: creeping paranoia that lifts only at dawn. Dark 2D art, a dim desk lamp, fog, a violet UV beam, and captioned folklore sounds such as the tik-tik bird. |
| **Technical constraints** | Godot 4 on Windows PC. One fixed 2D scene at 1280 x 720 or larger. The final game is mouse first with optional keys. The Lab 3 build uses the L, S, and R keys. Built with class skills only (scenes, Control UI, signals, Timers, Tweens, Resources). Customers are data rows, not AI. |
| **Scope** | In: one counter scene, five nights, 30 customers, 6 regulars, six counter tools (UV lamp, ledger, radio, salt bowl, shutter rope, cash drawer), two endings, and accessibility settings. Cut: 3D, free movement, shop management, branching dialogue, voice acting, and multiplayer. If behind, cut day chats first, then ledger tampering, then salabat. |

---

## 3. Core Gameplay Loop

The core loop is one customer encounter: inspect, decide, see the result, and face the next customer. It repeats 30 times across five nights. This is the loop built in the Lab 3 prototype.

**Figure 1.** The core loop as built in `lola-s-pamana-lab3`.

```
[1. Customer at the grille] --> [2. Inspect]          --> [3. Decide]         --> [4. Feedback]                         --> [5. Pause]
 name and order shown            press L to read           S serve or R refuse     result line, Pesos, Sanity,              2 seconds
                                 Lola's ledger                                     correct calls
        ^                                                                                                                       |
        +---------------------------- next customer arrives, loop returns to step 1 -----------------------------------------+
```

### 3.1 Input, action, and feedback in the Lab 3 build

| Step | What happens |
| :-- | :-- |
| **Input** | A customer's request appears, such as "Aling Nena asks for sinigang mix". The player presses L to read the ledger, then S to serve or R to refuse. |
| **Action** | L compares the order with what that regular always buys. S or R resolves the encounter against the customer's hidden identity. |
| **Feedback** | After L, the ledger line appears ("The order matches" or "This one asked for coffee sachet") and the customer pops up with a warm tint. After S or R, a result line appears, the customer drops out of view, and Pesos, Sanity, and Correct calls update at once. Deciding without reading the ledger adds "You never opened the ledger." |
| **Repeat** | After a 2 second pause the next customer arrives. There is no countdown. |

**Table 3.** Decision results in the Lab 3 build.

| Decision | Customer is human | Customer is an entity |
| :-- | :-- | :-- |
| **Serve (S)** | +20 Pesos, correct call | -30 Sanity, "It took the item and smiled with too many teeth." |
| **Refuse (R)** | -10 Sanity, "You shut out a real neighbor." | Correct call, "The shutter drops." |

The build runs six scripted customers in a fixed order, two of them entities copying Aling Nena and Mang Ador. At 0 Sanity the run resets to 150 Pesos and 100 Sanity.

### 3.2 Why it is worth repeating

- **Every pass is a real judgement.** Both decisions have a cost, so no choice is automatic.
- **Rewards.** Correct calls earn Pesos or protect Sanity. In the final game a correct Banish restores 5 Sanity, and each dawn shows the correct-call count and a new page of Lola's story.
- **Mastery.** The player learns each regular, so copies get easier to spot and mistakes feel personal.
- **Escalation.** Decoys, warnings, utang, and tampering arrive night by night, so the same loop keeps asking new questions.

### 3.3 From the prototype to the finals project

| Loop step | Lab 3 build | Finals project |
| :-- | :-- | :-- |
| **Inspect** | L reads the ledger order | Ledger (order, debt, personal detail), UV lamp, and radio |
| **Decide** | Serve or Refuse | Serve, Serve on utang, Refuse, or Banish |
| **Feedback** | Result line and stats | Plus jump scares, silhouettes for Presence, and the dawn report |
| **Repeat** | 6 customers, 2 second pause | 30 customers over five nights, shrinking quiet gaps |

**Figure 2.** The macro loop.

```
[DAY]                            --> [NIGHT]                             --> [DAWN]
 buy supplies, chat with              4 to 8 customers, each one              report and Lola's page
 up to 2 regulars                     a pass of the core loop
   ^                                                                            |
   +---------- after dawn, the next day starts (after Night 5, the ending) ----+

A lost night is retried from 6 PM.
```

---

## 4. Revision Note (Peer Read-Around)

**Feedback received.** We swapped drafts with a classmate during the read-around and asked for one concrete piece of feedback. They pointed out that the 30 second patience timer did not fit the slow-burn dread the game aims for. A visible clock rewards quick reflexes, while our concept is about careful doubt.

**Our response.** We agreed and removed the timer from the build and the document. Our playtests of the earlier Lab 3 build had shown the same problem.

**Table 4.** What changed.

| Section | Before (first Lab 4 draft) | After |
| :-- | :-- | :-- |
| **Rules** | Each customer waits 30 seconds. Letting an entity time out costs 30 Sanity. | No customer timer and no timeout outcome. The customer waits until the player decides. |
| **Rules** | No rule for spacing customers, because the 30 second wait set the pace | A quiet gap before each customer, 45 seconds on Night 1 down to 10 on Night 5 |
| **Resources** | Patience (30 seconds per customer) | Removed. UV battery and the radio's Sanity drain now carry the time cost. |
| **Conflict** | "Patience runs out while the player reads." | Pressure comes from doubt, limited tools, and shrinking gaps. |
| **Core loop** | One pass takes 30 to 35 seconds | No countdown, matching the Lab 3 build |

**What we kept.** The radio's Sanity drain stays, so waiting still costs something when the player chooses to listen. Removing the timer took out a reflex test without making the game risk-free. Waiting with the radio on costs nothing, and we allow this slow play on purpose. The concept rewards careful doubt, not speed, so a player may study the ledger and the customer for as long as they like. That care still has a price: the UV lamp drains battery while it is on, and a wrong call costs Sanity or a sale no matter how long the player took.

---

## 5. Reflection

**Does the high concept promise something the core loop delivers? Where is the gap?**

Mostly. The Lab 3 loop delivers the ledger check and the cost of both decisions. The gap is doubt: in the build, a ledger mismatch always means an entity, so the player never weighs one clue against another. The next build adds the UV lamp and decoy tells to test the rule of two.

**Which formal element was hardest to pin down, and why?**

Conflict. With the timer, pressure was easy to explain. Without it, we had to name where tension comes from: the rule of two, limited battery and Salt, and the Sanity cost of listening.

**What did the peer read-around make us see that we had missed?**

The timer contradicted our own concept. It felt normal for a shop game, so we never questioned it. Now we test every mechanic against the guiding concept before keeping it.
