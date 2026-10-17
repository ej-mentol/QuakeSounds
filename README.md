# Quake Sounds for Sven Co-op

Server-side AngelScript plugin. Announces kill events (First Blood, multikills, streaks and others) with a sound,
an on-screen text line and a line in the top-left kill feed. Built for co-op: killers are mostly monsters,
players are the victims. A PvP mode is available.

## Author

mentol - https://github.com/ej-mentol/

## Credits

Event set, sound names and general behaviour are based on
[Advanced Quake Sounds v5.0 [ALL GAMES] & Optional Sounds Pack](https://forums.alliedmods.net/showthread.php?t=152034)
(AlliedModders, AMX Mod X). The sound files are taken from the Optional Sounds Pack of that project.
Check the original thread for the distribution terms of the sounds.

## Requirements

- Sven Co-op with AngelScript plugin support. The script was written against the 5.26 API documentation.
- Sound files in `sound/quake_sounds/` (list below). The plugin precaches them; clients download them on connect.

## Installation

```
svencoop_addon/
  scripts/plugins/quake_sounds.as
  scripts/plugins/store/qs_*.txt        (files from this repository's store/ folder)
  sound/quake_sounds/*.wav
```

Register the plugin in the `default_plugins.txt` your server uses (script path is relative to `scripts/plugins`, no extension):

```
"plugin"
{
    "name"   "QuakeSounds"
    "script" "quake_sounds"
}
```

Updating: do not overwrite `store/qs_off_*.txt` and `store/qs_seen.txt` on a running server, they hold player settings.

## Events

| Event | Trigger |
|---|---|
| First Blood | First death on the map, any killer. Once per map. |
| Double / Triple / Quadra / Penta / Hexa Kill | Consecutive kills by the same killer (2 to 6 in a chain). |
| Streak tiers (Multi Kill ... Beyond Godlike) | Total kills of one killer reach 3, 4, ... 15 (`CFG_STREAK_MIN_KILLS` and up). |
| Humiliation | Victim killed by a direct melee attack (slash / club damage, inflictor is the attacker). |
| Pancake | Crush damage or killed by a door, train, pendulum, rotating brush. |
| Headshot | Victim's last hit group is the head. |
| Assassin | Killed by `monster_human_assassin` or `monster_male_assassin`. |
| Blast | Killed by explosion damage. |
| Suicide / world death | Killer is the victim, `worldspawn` or `trigger_hurt`. Plays the laugh with a probability. |
| Teamkiller | A player kills a player while PvP mode is inactive. |
| Shutdown | A player kills a monster that had at least `SHUTDOWN_MIN_KILLS` kills. |
| Payback | A player kills a monster that previously killed that player. |
| Last Man Standing | One player is left alive with at least `CFG_LASTMAN_MIN_PLAYERS` players connected. |

Only one of Pancake / Humiliation / Headshot / Assassin / Blast is chosen per kill (priority in that order).
Each of them has a per-killer cooldown (`CFG_FLAVOR_COOLDOWN`).

## Behaviour

- **Chains.** A monster's chain never expires and ends when the monster dies. A player's chain expires after
  `MULTIKILL_WINDOW` seconds and ends when the player dies (PvP mode only).
  Chains are counted per killer entity, not per classname.
- **Bursts.** If the victim differs from the killer's previous victim, announcements wait `CFG_BURST_DEBOUNCE`
  seconds so simultaneous kills produce one announcement. Repeated kills of the same victim are announced immediately.
- **Priority per burst.** Multikill, then streak tier. A flavor event (Humiliation etc.) follows `CFG_FLAVOR_OFFSET`
  seconds after the multikill / streak / First Blood announcement. With `CFG_FLAVOR_WITH_STREAK = false` it is skipped instead.
- **Sound queue.** Per listener, sounds are spaced by `CFG_EVENT_DELAY`; at most `CFG_MAX_QUEUE` wait, the rest are dropped.
- **Display.** Big text: bottom left, typewriter effect, white flash into blue. A flavor event uses a second line below it.
  Kill feed: the same sentence in the top-left notify area. Chat output is available but off by default.
- **PvP mode.** `pvp0` off: player kills are announced as Teamkiller. `pvp1` on: player kills use the same chains and events as monster kills.
  `pvp2` auto: on while `mp_friendlyfire` is greater than 0.
- **Entities excluded from chains.** Doors, trains, lasers, explosions, breakables and similar (built-in list, extendable in `qs_blacklist.txt`).
- **Admin assist.** When a barrel or explosive kills a player and a player recently damaged it, admins get a line
  `shooter -> source -> victim` in the kill feed, with a distance tag. Switchable.

## Player commands

| Command | Effect |
|---|---|
| `!qs` | Settings menu |
| `!qs 0` / `!qs 1` | All output off / on |
| `!qs snd` / `!qs hud` / `!qs feed` | Toggle sound / big text / kill feed |
| `!qs admin` | Server settings menu (admins only) |
| `quake` (as a chat message) | Prints a short help |

`/qs` and `.qs` work as well as `!qs`.

## Disabling things

| What | Scope | How |
|---|---|---|
| Everything | one player | `!qs 0` |
| Sounds, big text, kill feed | one player | `!qs snd`, `!qs hud`, `!qs feed` (saved in `qs_off_snd.txt`, `qs_off_hud.txt`, `qs_off_feed.txt`) |
| Big text, kill feed, chat lines, admin assist, suicide laugh, last man, tips | server | remove the token from `qs_config.txt` or use `!qs admin` |
| Who hears events (admins / victim + admins / everyone) | server | `aud0` / `aud1` / `aud2` in `qs_config.txt` |
| PvP behaviour | server | `pvp0` / `pvp1` / `pvp2` in `qs_config.txt` |
| Chains and streaks for specific classnames | server | `qs_blacklist.txt` |
| Humiliation for specific classnames | server | `qs_melee_blacklist.txt` |
| A single event type (for example Headshot) | server | no switch; edit the matching branch in `OnPlayerKilled` |
| Timings, chances, thresholds | server | constants at the top of the script |

## store/ files

All files are optional. Without `qs_config.txt` the defaults from the script header apply.
Lines starting with `//` or `#` are ignored in every file.

| File | Written by plugin | Content |
|---|---|---|
| `qs_config.txt` | yes (`!qs admin`) | Global settings as tokens. A feature is ON only if its token is listed. Tokens: `hud notify chat assist suicide lastman tips aud0 aud1 aud2 pvp0 pvp1 pvp2`. Once this file exists it overrides the matching defaults in the script. |
| `qs_blacklist.txt` | no | Extra classnames excluded from chains. |
| `qs_melee_blacklist.txt` | no | Classnames that never get Humiliation. |
| `qs_off_snd.txt`, `qs_off_hud.txt`, `qs_off_feed.txt` | yes | SteamIDs (netname on LAN) with the matching output disabled. |
| `qs_seen.txt` | yes | SteamIDs that already used `!qs` (no periodic tip for them). |

Files written by the plugin keep their header comment. `quakesounds_disabled.txt` from earlier versions is imported once and emptied.

## Tuning

Edit the constants at the top of `quake_sounds.as`.

| Constant | Default | Meaning |
|---|---|---|
| `SND_PREFIX` | `quake_sounds/` | Sound folder below `sound/` |
| `HUD_CHANNEL`, `HUD_X`, `HUD_Y` | 3, 0.06, 0.68 | Big text channel and position. The flavor line uses `HUD_CHANNEL + 1` and `HUD_Y + HUD_FLAVOR_DY` (default 0.04, negative = above, 0 = same spot and channel, the flavor text replaces the main text). |
| `CFG_EVENT_DELAY` | 0.45 | Seconds between queued sounds per listener |
| `CFG_MAX_QUEUE` | 3 | Maximum queued sounds per listener |
| `CFG_BURST_DEBOUNCE` | 0.4 | Seconds that merge kills of different victims into one announcement |
| `CFG_STREAK_MIN_KILLS` | 3 | Streak tiers below this are not announced |
| `CFG_FLAVOR_COOLDOWN` | 5.0 | Per-killer cooldown of Humiliation / Pancake / Headshot / Assassin / Blast |
| `CFG_FLAVOR_WITH_STREAK` | true | Play a flavor event after a multikill / streak (false: either one) |
| `CFG_FLAVOR_OFFSET` | 1.0 | Delay of that flavor event in seconds, roughly the length of the multikill sound |
| `CFG_SUICIDE_CHANCE` | 35 | Percent of suicide / world deaths that play the laugh |
| `CFG_SUICIDE_COOLDOWN` | 6.0 | Global cooldown of the laugh in seconds |
| `CFG_MELEE_CHANCE` | 100 | Default percent of melee kills that play Humiliation; per-class values in `BuildChances()` (headcrab 15, babycrab 15, barnacle 10) |
| `MULTIKILL_WINDOW` | 3.5 | Chain gap limit for player killers, seconds |
| `SHUTDOWN_MIN_KILLS` | 3 | Minimum monster kills for Shutdown |
| `CFG_LASTMAN_MIN_PLAYERS` | 2 | Minimum connected players for Last Man Standing |
| `ASSIST_EXPIRE`, `TROLL_RADIUS` | 4.0, 350 | Admin assist: memory time of the shooter, distance for the CLOSE tag |
| `CFG_DMG_STALE` | 0.5 | Damage info older than this (seconds) is ignored when classifying a kill |
| `CFG_DEBUG` | false | Timeline log, see below |

The runtime settings (audience, big text, kill feed, chat, assist, PvP, suicide laugh, last man, tips) are also set by `qs_config.txt`.

## Debugging

`CFG_DEBUG = true` prints a timeline with game time to the server console and to the console of every admin:
kills, chain state, burst timers, announcements, queued and played sounds, skipped events.
It also enables `!qs test`, which prints the current settings and sends one test line through each output channel.

## Limitations

- Entity names come from the `g_PrettyNames` table; unknown classnames are formatted from the classname.
  The mapper's `displayname` is not read.
- Shutdown and Payback exist only for monsters killed by players.
- On LAN servers players are identified by netname.
- Reloading the plugin resets the First Blood flag; chain counters stay on the entities until they die or the map changes.

## Required sound files

`sound/quake_sounds/`

```
assassin.wav
bullseye.wav
comboking.wav
dominating.wav
dominating2.wav
doublekill.wav
doublekill2.wav
doublekill3.wav
eagleeye.wav
eagleeye2.wav
excellent.wav
firstblood.wav
firstblood2.wav
firstblood3.wav
firstblood4.wav
godlike.wav
godlike2.wav
headhunter.wav
headhunter2.wav
headshot.wav
headshot2.wav
headshot3.wav
headshot4.wav
hexakill.wav
holyshit.wav
humiliating.wav
humiliatingdefeat.wav
humiliation.wav
iamtheoneandonly.wav
impressive.wav
killingmachine.wav
killingspree.wav
killingspree2.wav
laughs.wav
laughs2.wav
laughs3.wav
laughs4.wav
ludicrouskill.wav
maniac.wav
massacre.wav
megakill.wav
megakill2.wav
monsterkill.wav
monsterkill2.wav
multikill.wav
multikill2.wav
outstanding.wav
ownage.wav
pancake.wav
payback.wav
pentakill.wav
quadrakill.wav
rampage.wav
rampage2.wav
retribution.wav
shutdown.wav
teamkiller.wav
triplekill.wav
ultrakill.wav
ultrakill2.wav
unreal.wav
unstoppable.wav
unstoppable2.wav
vengeance.wav
whickedsick.wav
youarethelastmanstanding.wav
yourefunny.wav
```
