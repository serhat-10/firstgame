# Testing Checklist

- Launch project with no network connection.
- Start a new game from the main menu.
- Verify at least 4 territories are visible.
- Verify player, neutral, and AI territories have distinct colors.
- Wait and confirm owned territory population increases.
- Tap the player territory and confirm selection feedback.
- Tap a non-neighbor and confirm the action is rejected.
- Tap a neighboring territory and confirm units move along the connection.
- Confirm source population decreases by about 50%.
- Confirm battle numbers animate instead of resolving instantly.
- Confirm capture changes the owner color and population.
- Pause, resume, and restart the match.
- Pause the match and confirm a save is written.
- Return to menu and continue the saved match.
- Corrupt or delete `user://match_save.json` and confirm the app does not crash.
- Switch language and confirm UI text updates after returning to the menu.
- Disable sound and haptics and confirm settings persist.
- Let AI act and confirm it sends only to connected territories.
- Confirm victory when all territories are player-owned.
- Confirm defeat when the player owns no territories.

