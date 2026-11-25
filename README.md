# One Rule Town

Every round, the town announces one absurd rule. Read it, follow it, and survive.

One Rule Town is a server-authoritative Roblox party game built with Luau and Rojo. The repository contains a code-generated MVP: three themed town maps, sixteen survival rules, round flow, persistent progression, cosmetics, responsive UI, and monetization hooks.

## MVP features

- Three voteable town layouts, Sunny Square, Festival Night, and Market Rush, with distinct lighting and landmarks while preserving the rule zones.
- An original 11-second opening with a resident watching a HUSS HUSS phone clip, the Mayor, a town flyover, asset loading, Skip after two seconds, Replay Intro, and automatic camera/control restoration.
- Code-generated town with an entry gate, shopfronts, token sculptures, safe platforms, light zones, and a spectator roof.
- Sixteen modular rules with server-side validation and escalating difficulty.
- Intermission with map voting, rule reveal, active round, playable hunter role after elimination, revive, mini events, special double-token rounds, results, and reward states.
- Town Tokens, wins, streaks, a daily first-win bonus, persistent cosmetics, and leaderstats.
- Expressive resident NPCs with accessories, dance moves, and short speech bubbles; NPCs do not count as real visits.
- Developer product receipt processing with persisted purchase IDs.
- Game pass ownership checks for VIP and Double Tokens.
- Responsive English UI for desktop, mobile, tablet, and console-sized screens.
- Automatic Rojo build validation on GitHub Actions.

## Rules

1. Keep Moving
2. Do Not Jump
3. Do Not Touch Red
4. Stay In The Light
5. Do Not Go Inside
6. Stay Near Someone
7. Freeze When The Bell Rings
8. Hold Something Blue
9. Avoid The Mayor
10. The Floor Is Lava
11. HUSS HUSS! Reach the Court
12. The Blue Court Is Closed
13. Find the Yellow Spot
14. Avoid the Town Center
15. Stay on the Pavement
16. Cross the Town

## Open in Roblox Studio

1. Install [Roblox Studio](https://create.roblox.com/docs/studio/setup).
2. Install the Rojo Studio plugin.
3. Install [Rokit](https://github.com/rojo-rbx/rokit) and run `rokit install`, or download Rojo 7.7.1 directly.
4. From this repository, run `rojo serve`.
5. Open a new Baseplate in Roblox Studio.
6. Open the Rojo plugin and connect to the running server.
7. Press **Play**. The server generates the complete map when the session starts.

You can also create a place file without Studio:

```bash
rojo build default.project.json --output OneRuleTown.rbxlx
```

## Monetization setup

The shop is implemented, but product IDs intentionally default to `0`. This prevents accidental prompts before the Roblox experience and products exist.

Create the following in Creator Dashboard:

| Type | Key | Suggested price |
| --- | --- | ---: |
| Developer Product | Revive | 19 Robux |
| Developer Product | 250 Town Tokens | 39 Robux |
| Developer Product | 750 Town Tokens | 99 Robux |
| Developer Product | 2,000 Town Tokens | 249 Robux |
| Game Pass | VIP Cosmetics | 99 Robux |
| Game Pass | Double Tokens | 149 Robux |

Copy the resulting IDs into `Config.Monetization` in `src/shared/Config.luau`. Products with an ID of `0` appear as unavailable in the shop.

Developer product rewards are granted only through `MarketplaceService.ProcessReceipt`. Receipt IDs are stored with player data to prevent duplicate grants. If a purchased revive cannot be used immediately, it remains in the player's revive balance.

## Data stores

Publish the experience before testing persistence. In Studio, open **File → Experience Settings → Security** and enable **Studio Access to API Services** only for a test experience you control.

Player data is saved on an interval, when the player leaves, and during server shutdown. Failed requests use bounded retries with backoff.

## Development checks

```bash
node scripts/validate.mjs
rojo build default.project.json --output OneRuleTown.rbxlx
```

The structural validator checks the Rojo mapping, required services, rule IDs, and catalog coverage.

## Project structure

```text
src/
├── client/          Responsive interface and client effects
├── server/
│   ├── Rules/       One isolated module per survival rule
│   └── Services/    Map, rounds, data, cosmetics, and monetization
└── shared/          Configuration, rule metadata, and shared types
```

All gameplay decisions, rewards, purchases, and cosmetic ownership checks run on the server. Client remotes are rate-limited and validated before they affect game state.

