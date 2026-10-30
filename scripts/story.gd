class_name Story
extends RefCounted
## Lola's dawn pages from Table 18 and the two endings from 7.3.
## Draft text for the narrative designer to revise.

const PAGES := {
	1: "The day I opened this store, I made my first rule. Every name gets a line in this book. Learn your neighbors by day, child. At night, the book is how you know them.",
	2: "Tonight a neighbor came back wrong. Her voice was right but her words were not. I trusted two signs, never one, and I laid the salt. It held. One sign is a doubt. Two signs are an answer.",
	3: "When the whole street goes quiet at 3 AM, something is already at the grille. Do not trust the silence. And remember this: a debt always comes back to the counter.",
	4: "Another hand has been writing in my book. Some lines are not mine. The fresh ink glows under the lamp. Trust two signs, not the page alone.",
}

const ENDING_GOOD := "The last page of Lola's ledger.\n\nForty years ago, on a night thick with fog, I gave utang to a stranger. He was a kapre. A debt must come back to be paid, so he kept returning to my counter, and others followed him. As long as this store opened at night, they came to the grille and not to my neighbors' doors.\n\nThe debt will be paid when someone of my blood keeps this counter for five nights with a steady mind and knows every neighbor by name.\n\nThe stranger's line is marked PAID. Below it, in fresh ink, is your name."

const ENDING_BITTERSWEET := "The last page of Lola's ledger.\n\nThe bottom half is torn away.\n\nWhat is left reads: The store must open every night. As long as it opens, they come to the grille and not to my neighbors' doors. The debt will be paid when someone of my blood\n\nThe rest is gone. You do not learn whose debt it was, or how it ends."


static func page_for(night: int) -> String:
	return PAGES.get(night, "")
