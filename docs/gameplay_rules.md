# Gameplay Rules

- Controlled districts with owner IDs greater than `0` generate influence every frame.
- Influence growth is capped by each district's `maximum_population`.
- The player can select only districts owned by the player faction.
- A send action is valid only when the target is listed in the source district's `neighbor_ids`.
- The player can choose 25%, 50%, 75%, or 100% send amounts. The default is 50%.
- Send amount is `floor(source_population * selected_send_fraction)`, clamped so the source never goes negative.
- Friendly targets are reinforced up to their maximum population.
- Enemy targets start a timed numerical battle after the wave reaches the target.
- Defense power is `defender_population * balance.defense_multiplier * territory.defense_modifier`.
- If attacking power is greater than defense power, the attacker captures the district with the remaining power.
- If defense power survives, the defender keeps the district with the remaining defensive population.
- The player wins when every district belongs to the player.
- The player loses when no district belongs to the player.
