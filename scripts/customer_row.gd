class_name CustomerRow
extends Resource
## One scripted customer from the data table. The 30 rows live in
## res://data/customer_table.tres and are loaded by CustomerData.

@export var id: String = ""
@export var night: int = 1
@export var slot: int = 1
## "regular" or "stranger".
@export var kind: String = "stranger"
## Key into CustomerData.REGULARS for regulars and for aswang copies.
@export var regular_id: String = ""
@export var is_entity: bool = false
## "", "aswang", "tiktik", "kapre", or "manananggal".
@export var entity_type: String = ""
## Item key into CustomerData.ITEMS.
@export var order: String = ""
## Money put on the counter, in Pesos. 0 means no money down.
@export var payment: int = 0
@export var line: String = ""
## Aswang copies only. Used when the player knows the copied regular's
## personal detail, so the copy gets the detail wrong instead of the order.
@export var known_order: String = ""
@export var known_line: String = ""
## Entity tells that show under the UV lamp: "face", "cash", or both.
@export var uv_tells: PackedStringArray = PackedStringArray()
## Entity rows only. True when one of its two tells is a ledger mismatch.
@export var ledger_tell: bool = false
## 0 = not replaceable. 1 or 2 = order in which a returning entity takes it.
@export var replaceable: int = 0
## "none", "fixed", or "pool". Pool warnings are shuffled per run (6.4).
@export var warn: String = "none"
## "" for no decoy, "order", "face", or "cash" for a fixed decoy,
## or "pool" when the row may receive a shuffled decoy.
@export var decoy: String = ""
## Ledger tampering from Night 4. The smeared entry shows this item as the
## usual order. Empty when the entry is clean.
@export var tampered_usual: String = ""
## Teaching beat tag from Table 11.
@export var teach: String = ""
