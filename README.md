# Quake Sounds for Sven Co-op

Server-side AngelScript plugin. Announces kill events (First Blood, multikills, streaks and others) with a sound,
an on-screen text line and a line in the top-left kill feed. Built for co-op: killers are mostly monsters,
players are the victims. A PvP mode is available.

## Credits

* Concept, event set and sound names: [Advanced Quake Sounds](https://forums.alliedmods.net/showthread.php?t=152034) (AlliedModders, AMX Mod X).
The sound files in `sound/quake\_sounds/` come from its Optional Sounds Pack and are kept in this repository so they stay available if the forum link dies.
* On-screen presentation (typewriter HUD text, announcement phrasing such as "drew the First Blood!"): modelled on the announcer of [GameSwitch](https://gameswitch.org) servers.

## Requirements

* Sven Co-op with AngelScript plugin support. The script was written against the 5.26 API documentation.
* Sound files in `sound/quake\_sounds/`, included in this repository (list at the end, source in Credits). The plugin precaches them; clients download them on connect.

## Installation

```
svencoop\_addon/
  scripts/plugins/quake\_sounds.as
  scripts/plugins/store/qs\_\*.txt        (files from this repository's store/ folder)
  sound/quake\_sounds/\*.wav
```

Register the plugin in the `default\_plugins.txt` your server uses (script path is relative to `scripts/plugins`, no extension):

```
"plugin"
{
    "name"   "QuakeSounds"
    "script" "quake\_sounds"
}
```

Updating: do not overwrite `store/qs\_off\_\*.txt` and `store/qs\_seen.txt` on a running server, they hold player settings.

## Events

|Event|Trigger|
|-|-|
|First Blood|First death on the map, any killer. Once per map.|
|Double / Triple / Quadra / Penta / Hexa Kill|Consecutive kills by the same killer (2 to 6 in a chain).|
|Streak tiers (Multi Kill ... Beyond Godlike)|Total kills of one killer reach 7, 8, ... 19, continuing after Hexa Kill.|
|Humiliation|Victim killed by a direct melee attack (slash / club damage, inflictor is the attacker).|
|Pancake|Crush damage or killed by a door, train, pendulum, rotating brush.|
|Headshot|Victim's last hit group is the head.|
|Assassin|Killed by `monster\_human\_assassin` or `monster\_male\_assassin`.|
|Blast|Killed by explosion damage.|
|Suicide / world death|Killer is the victim, `worldspawn` or `trigger\_hurt`. Plays the laugh with a probability.|
|Teamkiller|A player kills a player while PvP mode is inactive.|
|Shutdown|A player kills a monster that had at least `SHUTDOWN\_MIN\_KILLS` kills.|
|Payback|A player kills a monster that previously killed that player.|
|Last Man Standing|One player is left alive with at least `CFG\_LASTMAN\_MIN\_PLAYERS` players connected.|

Only one of Pancake / Humiliation / Headshot / Assassin / Blast is chosen per kill (priority in that order).
Each of them has a per-killer cooldown (`CFG\_FLAVOR\_COOLDOWN`).

## Behaviour

* **Chains.** A monster's chain never expires and ends when the monster dies. A player's chain expires after
`MULTIKILL\_WINDOW` seconds and ends when the player dies (PvP mode only).
Chains are counted per killer entity, not per classname.
* **Bursts.** If the victim differs from the killer's previous victim, announcements wait `CFG\_BURST\_DEBOUNCE`
seconds so simultaneous kills produce one announcement. Repeated kills of the same victim are announced immediately.
* **Priority per burst.** Multikill, then streak tier. A flavor event (Humiliation etc.) follows `CFG\_FLAVOR\_OFFSET`
seconds after the multikill / streak / First Blood announcement. With `CFG\_FLAVOR\_WITH\_STREAK = false` it is skipped instead.
* **Sound queue.** Per listener, sounds are spaced by `CFG\_EVENT\_DELAY`; at most `CFG\_MAX\_QUEUE` wait, the rest are dropped.
* **Display.** Big text: bottom left, typewriter effect, white flash into blue. A flavor event uses a second line below it.
Kill feed: the same sentence in the top-left notify area. Chat output is available but off by default.
* **PvP mode.** `pvp0` off: player kills are announced as Teamkiller. `pvp1` on: player kills use the same chains and events as monster kills.
`pvp2` auto: on while `mp\_friendlyfire` is greater than 0.
* **Entities excluded from chains.** Doors, trains, lasers, explosions, breakables and similar (built-in list, extendable in `qs\_blacklist.txt`).
* **Admin assist.** When a barrel or explosive kills a player and a player recently damaged it, admins get a line
`shooter -> source -> victim` in the kill feed, with a distance tag. Switchable.

## Configuration layers

Where to change what, in the order to decide:

1. **`store/` files** - no script edit, read on every map start.

   * `qs\_config.txt`: server-wide switches (big text, kill feed, chat, admin assist, suicide laugh, last man, tips), global audience, PvP mode.
   * `qs\_blacklist.txt`, `qs\_melee\_blacklist.txt`: classnames excluded from chains / from Humiliation.
   * `qs\_off\_snd.txt`, `qs\_off\_hud.txt`, `qs\_off\_feed.txt`: per-player mutes, written by `!qs`.
2. **Script constants** - audience per event type (`AUD\_\*`), timings, chances, thresholds, HUD position.
3. **Script code** - event classification and priorities (`OnPlayerKilled`).

Who receives an event is decided per listener in three steps:

|Step|Source|Meaning|
|-|-|-|
|1|`AUD\_\*` of the event type (script constants)|-1 nobody, 0 admins only, 1 the player concerned (+ admins), 2 everyone|
|2|Global audience: `aud0/1/2` in `qs\_config.txt` or `!qs admin`|Ceiling. The effective value is the smaller of step 1 and step 2.|
|3|Player's own settings: `!qs snd/hud/feed/0`, stored in `qs\_off\_\*.txt`|The listener's mute, applied after steps 1 and 2. Sound, big text and kill feed are muted separately.|

* Steps 1 and 2 apply to sound, big text, kill feed and chat line of an event together. Only step 3 can separate sound from text.
* Global switches (`hud`, `notify`, `chat` in `qs\_config.txt`) turn an output off for everyone, regardless of the steps above.
* "The player concerned" is the victim for events where a monster kills a player (First Blood, multikills, streaks, Humiliation and the other flavor events, suicide, Teamkiller), the killing player for Shutdown and Payback, and the survivor for Last Man Standing.
* In PvP mode the victim, not the killer, counts as the player concerned. Keep `AUD\_\*` at 2 there.

## Player commands

|Command|Effect|
|-|-|
|`!qs`|Settings menu|
|`!qs 0` / `!qs 1`|All output off / on|
|`!qs snd` / `!qs hud` / `!qs feed`|Toggle sound / big text / kill feed|
|`!qs admin`|Server settings menu (admins only)|
|`quake` (as a chat message)|Prints a short help|

`/qs` and `.qs` work as well as `!qs`.

## Disabling things

|What|Scope|How|
|-|-|-|
|Everything|one player|`!qs 0`|
|Sounds, big text, kill feed|one player|`!qs snd`, `!qs hud`, `!qs feed` (saved in `qs\_off\_snd.txt`, `qs\_off\_hud.txt`, `qs\_off\_feed.txt`)|
|Big text, kill feed, chat lines, admin assist, suicide laugh, last man, tips|server|remove the token from `qs\_config.txt` or use `!qs admin`|
|Who hears events, all events at once (admins / victim + admins / everyone)|server|`aud0` / `aud1` / `aud2` in `qs\_config.txt`|
|Who hears one event type|server|`AUD\_\*` constants in the script, see Configuration layers|
|PvP behaviour|server|`pvp0` / `pvp1` / `pvp2` in `qs\_config.txt`|
|Chains and streaks for specific classnames|server|`qs\_blacklist.txt`|
|Humiliation for specific classnames|server|`qs\_melee\_blacklist.txt`|
|A single event type (for example Headshot)|server|no switch; edit the matching branch in `OnPlayerKilled`|
|Timings, chances, thresholds|server|constants at the top of the script|

## store/ files

All files are optional. Without `qs\_config.txt` the defaults from the script header apply.
Lines starting with `//` or `#` are ignored in every file.

|File|Written by plugin|Content|
|-|-|-|
|`qs\_config.txt`|yes (`!qs admin`)|Global settings as tokens. A feature is ON only if its token is listed. Tokens: `hud notify chat assist suicide lastman tips aud0 aud1 aud2 pvp0 pvp1 pvp2`. Once this file exists it overrides the matching defaults in the script.|
|`qs\_blacklist.txt`|no|Extra classnames excluded from chains.|
|`qs\_melee\_blacklist.txt`|no|Classnames that never get Humiliation.|
|`qs\_off\_snd.txt`, `qs\_off\_hud.txt`, `qs\_off\_feed.txt`|yes|SteamIDs (netname on LAN) with the matching output disabled.|
|`qs\_seen.txt`|yes|SteamIDs that already used `!qs` (no periodic tip for them).|

Files written by the plugin keep their header comment. `quakesounds\_disabled.txt` from earlier versions is imported once and emptied.

## Tuning

Edit the constants at the top of `quake\_sounds.as`.

|Constant|Default|Meaning|
|-|-|-|
|`SND\_PREFIX`|`quake\_sounds/`|Sound folder below `sound/`|
|`HUD\_CHANNEL`, `HUD\_X`, `HUD\_Y`|3, 0.06, 0.68|Big text channel and position. The flavor line uses `HUD\_CHANNEL + 1` and `HUD\_Y + HUD\_FLAVOR\_DY` (default 0.04, negative = above, 0 = same spot and channel, the flavor text replaces the main text).|
|`CFG\_EVENT\_DELAY`|0.45|Seconds between queued sounds per listener|
|`CFG\_MAX\_QUEUE`|3|Maximum queued sounds per listener|
|`CFG\_BURST\_DEBOUNCE`|0.4|Seconds that merge kills of different victims into one announcement|
|`CFG\_STREAK\_MIN\_KILLS`|3|Streak tiers below this are not announced|
|`AUD\_\*` (13 constants)|2 (`AUD\_PAYBACK` 1)|Audience per event type: -1 nobody, 0 admins only, 1 the player concerned (+ admins), 2 everyone. The effective audience is the smaller of this value and the global audience (`aud0/1/2`, `!qs admin`).|
|`CFG\_FLAVOR\_COOLDOWN`|5.0|Per-killer cooldown of Humiliation / Pancake / Headshot / Assassin / Blast|
|`CFG\_FLAVOR\_WITH\_STREAK`|true|Play a flavor event after a multikill / streak (false: either one)|
|`CFG\_FLAVOR\_AFTER\_SHOUT\_CHANCE`|50|Percent chance that a flavor event follows a multikill / streak / First Blood (a flavor event without a preceding shout is not affected)|
|`CFG\_FLAVOR\_OFFSET`|1.0|Delay of that flavor event in seconds, roughly the length of the multikill sound|
|`CFG\_SUICIDE\_CHANCE`|35|Percent of suicide / world deaths that play the laugh|
|`CFG\_SUICIDE\_COOLDOWN`|6.0|Global cooldown of the laugh in seconds|
|`CFG\_TEAMKILL\_CHANCE`, `CFG\_TEAMKILL\_COOLDOWN`|35, 6.0|Percent of player-kills-player events that get Teamkiller while PvP mode is off, and the global cooldown of that sound in seconds|
|`CFG\_MELEE\_CHANCE`|100|Default percent of melee kills that play Humiliation; per-class values in `BuildChances()` (headcrab 15, babycrab 15, barnacle 10)|
|`MULTIKILL\_WINDOW`|3.5|Chain gap limit for player killers, seconds|
|`SHUTDOWN\_MIN\_KILLS`|3|Minimum monster kills for Shutdown|
|`CFG\_LASTMAN\_MIN\_PLAYERS`|2|Minimum connected players for Last Man Standing|
|`ASSIST\_EXPIRE`, `TROLL\_RADIUS`|4.0, 350|Admin assist: memory time of the shooter, distance for the CLOSE tag|
|`CFG\_DMG\_STALE`|0.5|Damage info older than this (seconds) is ignored when classifying a kill|
|`CFG\_DEBUG`|false|Timeline log, see below|

The runtime settings (audience, big text, kill feed, chat, assist, PvP, suicide laugh, last man, tips) are also set by `qs\_config.txt`.

## Debugging

`CFG\_DEBUG = true` prints a timeline with game time to the server console and to the console of every admin:
kills, chain state, burst timers, announcements, queued and played sounds, skipped events.
It also enables `!qs test`, which prints the current settings and sends one test line through each output channel.

## Limitations

* Entity names come from the `g\_PrettyNames` table; unknown classnames are formatted from the classname.
The mapper's `displayname` is not read.
* Shutdown and Payback exist only for monsters killed by players.
* On LAN servers players are identified by netname.
* Reloading the plugin resets the First Blood flag; chain counters stay on the entities until they die or the map changes.

## Required sound files

Included in `sound/quake\_sounds/` of this repository (source in Credits). The script expects these file names:

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

