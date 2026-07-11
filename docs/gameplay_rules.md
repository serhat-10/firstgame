# Gameplay Rules

- Controlled territories with owner IDs greater than `0` generate population every frame.
- Population growth is capped by each territory's `maximum_population`.
- The player can select only territories owned by the player gang.
- A send action is valid only when the target is listed in the source territory's `neighbor_ids`.
- The default send amount is `floor(source_population * send_fraction)`, clamped so the source never goes negative.
- Friendly targets are reinforced up to their maximum population.
- Enemy targets start a timed numerical battle after the wave reaches the target.
- Defense power is `defender_population * balance.defense_multiplier * territory.defense_modifier`.
- If attacking power is greater than defense power, the attacker captures the territory with the remaining power.
- If defense power survives, the defender keeps the territory with the remaining defensive population.
- The player wins when every territory belongs to the player.
- The player loses when no territory belongs to the player.

