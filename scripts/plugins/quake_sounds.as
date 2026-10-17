// ============================================================================
// Quake Sounds for Sven Co-op 5.26 (PvE / monster-attacker edition)
// Settings: !qs (menu) | !qs 0 / 1 | !qs snd / hud / feed | !qs admin | say "quake" for help
// ============================================================================

// ---------------------------- CONFIG (spam control) -------------------------
const string CFG_PREFIX            = "[QS] ";   // prefix of every chat line
const string SND_PREFIX            = "quake_sounds/"; // files live in sound/quake_sounds/, "" if directly in sound/
int    CFG_AUDIENCE   = 2;      // 0 = admins only, 1 = victim + admins, 2 = everyone
bool   CFG_CHAT_TEXT  = false;  // chat lines
bool   CFG_HUD        = true;   // big blue text near the bottom
bool   CFG_NOTIFY     = true;   // who -> whom line in the top-left notify area
bool   CFG_ASSIST     = true;   // admin grey-zone assist line
int    CFG_PVP        = 2;      // PvP mode: 0 = off (co-op, player kills = Teamkiller), 1 = on, 2 = auto (mp_friendlyfire > 0)
int    CFG_TIP_SECS   = 0;      // periodic "!qs" tip in chat for players who never used it, 0 = off
const int HUD_CHANNEL = 3;
const float HUD_X = 0.06f;     // 0 = left edge, -1 = centered
const float HUD_Y = 0.68f;      // 0 = top, 1 = bottom; damage icons sit near 0.8+, chat starts near 0.71
const float HUD_FLAVOR_DY = 0.04f; // second line (Humiliation etc.) offset from HUD_Y, negative = above, 0 = replaces the main text in place

const float  CFG_EVENT_DELAY       = 0.45f;     // spacing between queued sounds per listener
const int    CFG_MAX_QUEUE         = 3;         // max sounds waiting per listener, extra ones are dropped
const float  CFG_BURST_DEBOUNCE    = 0.4f;      // kills closer than this count as one burst (one announcement for the whole burst)
const int    CFG_STREAK_MIN_KILLS  = 3;         // streak tiers below this are never announced
const float  CFG_FLAVOR_COOLDOWN   = 5.0f;      // per-attacker cooldown: pancake/melee/headshot/assassin/blast
const bool   CFG_FLAVOR_WITH_STREAK = true;   // melee/headshot/... also play after a multikill or streak announcement (false = either/or)
const float  CFG_FLAVOR_OFFSET     = 1.0f;      // delay of that second sound in seconds, about the length of the shout
bool   CFG_SUICIDE_SOUND     = true;
const float  CFG_SUICIDE_COOLDOWN  = 6.0f;      // global cooldown for suicide/world death sounds
const int    CFG_SUICIDE_CHANCE    = 35;        // percent of suicide / world deaths that get the laugh
const int    CFG_MELEE_CHANCE      = 100;       // default percent of melee kills that get Humiliation (per-class overrides in BuildChances)
bool   CFG_LASTMAN           = true;
const int    CFG_LASTMAN_MIN_PLAYERS = 2;

const bool   CFG_DEBUG            = false;     // true: timeline log with game time to server console + admin consoles, enables "!qs test"
const float  MULTIKILL_WINDOW      = 3.5f;      // chain gap limit for PLAYER killers in PvP (monsters never expire, their chain ends when they die)
const float  ASSIST_EXPIRE         = 4.0f;      // how long a shot barrel remembers its shooter
const float  TROLL_RADIUS          = 350.0f;    // "CLOSE" tag in admin assist line
const float  CFG_DMG_STALE         = 0.5f;      // last damage info older than this is ignored
const int    SHUTDOWN_MIN_KILLS    = 3;

const string STORE        = "scripts/plugins/store/";
const string F_LEGACY     = STORE + "quakesounds_disabled.txt";
const string F_OFF_SND    = STORE + "qs_off_snd.txt";
const string F_OFF_HUD    = STORE + "qs_off_hud.txt";
const string F_OFF_NOTE   = STORE + "qs_off_feed.txt";
const string F_SEEN       = STORE + "qs_seen.txt";
const string F_CFG        = STORE + "qs_config.txt";
const string F_BLACKLIST  = STORE + "qs_blacklist.txt";
const string F_MELEE_BL   = STORE + "qs_melee_blacklist.txt";

const int64 OFF_SND = 1, OFF_HUD = 2, OFF_NOTE = 4, OFF_ALL = 7, P_SEEN = 8;

const string H_CFG =
    "// Quake Sounds - global settings. Written by '!qs admin', read on every map start.\n" +
    "// A feature is ON only if its token is listed here; a missing token means OFF.\n" +
    "// Tokens: hud notify chat assist suicide lastman tips\n" +
    "//   aud0 = admins only | aud1 = victim + admins | aud2 = everyone\n" +
    "//   pvp0 = off | pvp1 = on | pvp2 = auto (follows mp_friendlyfire)\n" +
    "// Lines starting with // or # are ignored.\n";
const string H_OFF_SND =
    "// Players who turned sounds off ('!qs snd' / '!qs 0'). One SteamID per line (netname on LAN).\n" +
    "// Maintained by the plugin. Lines starting with // or # are ignored.\n";
const string H_OFF_HUD =
    "// Players who turned the big on-screen text off ('!qs hud' / '!qs 0'). One SteamID per line (netname on LAN).\n" +
    "// Maintained by the plugin. Lines starting with // or # are ignored.\n";
const string H_OFF_NOTE =
    "// Players who turned the top-left kill feed off ('!qs feed' / '!qs 0'). One SteamID per line (netname on LAN).\n" +
    "// Maintained by the plugin. Lines starting with // or # are ignored.\n";
const string H_SEEN =
    "// Players who already used '!qs'. They no longer receive the periodic tip (only relevant when tips are enabled).\n" +
    "// One SteamID per line (netname on LAN). Maintained by the plugin. Lines starting with // or # are ignored.\n";


// ---------------------------- TEXT (uniform "TITLE: who -> whom") -----------
const string T_FIRSTBLOOD = "First Blood";
const string T_SUICIDE    = "Suicide";
const string T_TEAMKILL   = "Teamkill";
const string T_PANCAKE    = "Pancake";
const string T_MELEE      = "Humiliation";
const string T_HEADSHOT   = "Headshot";
const string T_ASSASSIN   = "Assassin";
const string T_BLAST      = "Blast";
const string T_SHUTDOWN   = "Shutdown";
const string T_PAYBACK    = "Payback";
const string T_LASTMAN    = "Last Man Standing";

const array<string> MULTI_TITLES = { "", "", "Double Kill", "Triple Kill", "Quadra Kill", "Penta Kill", "Hexa Kill" };

class Ev
{
    string hud;
    string note;
    int slot;
}

bool IsMultiTitle(const string &in t)
{
    for (uint i = 2; i < MULTI_TITLES.length(); i++)
        if (MULTI_TITLES[i] == t) return true;
    return false;
}

string HudText(const string &in t, const string &in a, const string &in v, const string &in x)
{
    if (t == T_FIRSTBLOOD) return a + " drew the First Blood!";
    if (t == T_SUICIDE)    return a + " committed suicide!";
    if (t == T_TEAMKILL)   return a + " killed " + v + "!";
    if (t == T_PANCAKE)    return a + " flattened " + v + "!";
    if (t == T_MELEE)      return a + " humiliated " + v + "!";
    if (t == T_HEADSHOT)   return a + " got a Headshot on " + v + "!";
    if (t == T_ASSASSIN)   return a + " assassinated " + v + "!";
    if (t == T_BLAST)      return a + " blasted " + v + "!";
    if (t == T_SHUTDOWN)   return a + " shut down " + v + "!";
    if (t == T_PAYBACK)    return a + " got Payback on " + v + "!";
    if (t == T_LASTMAN)    return a + " is the Last Man Standing!";
    if (IsMultiTitle(t))   return a + " made a " + t + "!";
    return a + ": " + t + "! (" + x + ")";
}

Ev@ MsgVs(const string &in title, const string &in a, const string &in v, const string &in extra = "")
{
    Ev@ e = Ev();
    e.slot = 0;
    e.hud = HudText(title, a, v, extra);
    e.note = e.hud + "\n";
    return e;
}

Ev@ MsgSolo(const string &in title, const string &in a, const string &in extra = "")
{
    Ev@ e = Ev();
    e.slot = 0;
    e.hud = HudText(title, a, "", extra);
    e.note = e.hud + "\n";
    return e;
}

// ---------------------------- SOUND POOLS -----------------------------------
const array<string> POOL_FIRSTBLOOD = { "firstblood.wav", "firstblood2.wav", "firstblood3.wav", "firstblood4.wav" };
const array<string> POOL_HEADSHOT   = { "headshot.wav", "headshot2.wav", "headshot3.wav", "headshot4.wav", "headhunter.wav", "headhunter2.wav", "bullseye.wav" };
const array<string> POOL_HUMILIATE  = { "humiliation.wav", "humiliating.wav", "humiliatingdefeat.wav" };
const array<string> POOL_SUICIDE    = { "laughs.wav", "laughs2.wav", "laughs3.wav", "laughs4.wav", "yourefunny.wav" };
const array<string> POOL_REVENGE    = { "payback.wav", "vengeance.wav", "retribution.wav" };
const array<string> POOL_ASSASSIN   = { "assassin.wav", "eagleeye.wav", "eagleeye2.wav" };
const array<string> POOL_GRENADE    = { "excellent.wav", "impressive.wav", "outstanding.wav" };
const array<string> POOL_PANCAKE    = { "pancake.wav" };
const array<string> POOL_SHUTDOWN   = { "shutdown.wav" };
const array<string> POOL_TEAMKILL   = { "teamkiller.wav" };
const array<string> POOL_LASTMAN    = { "youarethelastmanstanding.wav", "iamtheoneandonly.wav" };

const array<string> POOL_DOUBLEKILL = { "doublekill.wav", "doublekill2.wav", "doublekill3.wav" };
const array<string> POOL_TRIPLEKILL = { "triplekill.wav" };
const array<string> POOL_QUADRAKILL = { "quadrakill.wav" };
const array<string> POOL_PENTAKILL  = { "pentakill.wav" };
const array<string> POOL_HEXAKILL   = { "hexakill.wav" };

class StreakTier
{
    int kills;
    array<string> sounds;
    string title;

    StreakTier(int k, array<string> s, string t)
    {
        kills = k;
        sounds = s;
        title = t;
    }
}

array<StreakTier@> g_StreakTiers = {
    StreakTier(2,  {"comboking.wav"},                         "Combo King"),
    StreakTier(3,  {"multikill.wav", "multikill2.wav"},       "Multi Kill"),
    StreakTier(4,  {"dominating.wav", "dominating2.wav"},     "Dominating"),
    StreakTier(5,  {"killingspree.wav", "killingspree2.wav"}, "Killing Spree"),
    StreakTier(6,  {"rampage.wav", "rampage2.wav"},           "Rampage"),
    StreakTier(7,  {"megakill.wav", "megakill2.wav"},         "Mega Kill"),
    StreakTier(8,  {"killingmachine.wav", "maniac.wav"},      "Killing Machine"),
    StreakTier(9,  {"ultrakill.wav", "ultrakill2.wav"},       "Ultra Kill"),
    StreakTier(10, {"unstoppable.wav", "unstoppable2.wav"},   "Unstoppable"),
    StreakTier(11, {"monsterkill.wav", "monsterkill2.wav"},   "Monster Kill"),
    StreakTier(12, {"whickedsick.wav", "massacre.wav"},       "Wicked Sick"),
    StreakTier(13, {"ludicrouskill.wav", "ownage.wav"},       "Ludicrous Kill"),
    StreakTier(14, {"godlike.wav", "godlike2.wav"},           "Godlike"),
    StreakTier(15, {"holyshit.wav", "unreal.wav"},            "Beyond Godlike")
};

dictionary g_PrettyNames = {
    {"monster_alien_slave",      "Vortigaunt"},
    {"monster_alien_grunt",      "Alien Grunt"},
    {"monster_alien_controller", "Controller"},
    {"monster_human_grunt",      "HECU Grunt"},
    {"monster_human_assassin",   "Black Ops Assassin"},
    {"monster_male_assassin",    "Black Ops Sniper"},
    {"monster_bullchicken",      "Bullsquid"},
    {"monster_headcrab",         "Headcrab"},
    {"monster_babycrab",         "Baby Headcrab"},
    {"monster_zombie",           "Zombie"},
    {"monster_zombie_barney",    "Zombie Barney"},
    {"monster_zombie_soldier",   "Zombie Soldier"},
    {"monster_gonome",           "Gonome"},
    {"monster_barnacle",         "Barnacle"},
    {"monster_leech",            "Leech"},
    {"monster_sentry",           "Sentry Turret"},
    {"monster_miniturret",       "Mini Turret"},
    {"monster_turret",           "Large Turret"},
    {"monster_houndeye",         "Houndeye"},
    {"monster_gargantua",        "Gargantua"},
    {"monster_bigmomma",         "Gonarch"},
    {"monster_nihilanth",        "Nihilanth"},
    {"monster_apache",           "Apache"},
    {"monster_osprey",           "Osprey"},
    {"monster_ichthyosaur",      "Ichthyosaur"},
    {"monster_pitdrone",         "Pit Drone"},
    {"monster_shocktrooper",     "Shock Trooper"},
    {"monster_voltigore",        "Voltigore"},
    {"monster_hwgrunt",          "Heavy Weapons Grunt"},
    {"monster_robogrunt",        "Robo Grunt"},
    {"monster_kingpin",          "Kingpin"},
    {"func_tank",                "Mounted Gun"},
    {"func_tanklaser",           "Mounted Laser"},
    {"func_tankrocket",          "Mounted Rocket Launcher"},
    {"func_tankmortar",          "Mounted Mortar"},
    {"trigger_hurt",             "the Environment"},
    {"env_explosion",            "Explosion"},
    {"env_laser",                "Laser"},
    {"env_beam",                 "Beam"},
    {"worldspawn",               "world"}
};

// ---------------------------- STATE -----------------------------------------
bool g_bFirstBlood = false;
bool g_bLastManTriggered = false;
float g_NextSuicideTime = 0.0f;

array<int>    g_LastDmgType(33, 0);
array<float>  g_LastDmgTime(33, 0.0f);
array<EHandle> g_LastInflictor(33);
array<float>  g_NextSoundTime(33, 0.0f);

dictionary g_Pref;     // SteamID -> bitmask (OFF_SND / OFF_HUD / OFF_NOTE / P_SEEN)
dictionary g_NoStreak; // classnames that never build streaks / multikills
dictionary g_MeleeChance; // classname -> percent for Humiliation
array<float> g_NextHelp(33, 0.0f);
HUDTextParams g_HudP;
HUDTextParams g_HudP2;   // second line for the delayed melee/headshot event
dictionary g_Bursts;   // monster entindex -> KillBurst

class KillBurst
{
    EHandle hVictim;
    EHandle hAtk;
    string name;
    string fTitle;
    string fSnd;
    string fVictim;
    bool preShout;
    int startKills;
    int multi;
    int total;
    CScheduledFunction@ timer;

    KillBurst()
    {
        preShout = false;
        startKills = 0;
        multi = 0;
        total = 0;
    }
}

// ---------------------------- INIT ------------------------------------------
void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor("mentol");
    g_Module.ScriptInfo.SetContactInfo("https://github.com/ej-mentol/");

    g_Hooks.RegisterHook(Hooks::Player::PlayerTakeDamage, @OnPlayerTakeDamage);
    g_Hooks.RegisterHook(Hooks::Player::PlayerKilled, @OnPlayerKilled);
    g_Hooks.RegisterHook(Hooks::Monster::MonsterKilled, @OnMonsterKilled);
    g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @OnClientDisconnect);
    g_Hooks.RegisterHook(Hooks::Player::ClientSay, @OnClientSay);
    g_Hooks.RegisterHook(Hooks::Weapon::WeaponPrimaryAttack, @OnWeaponFire);
    g_Hooks.RegisterHook(Hooks::Weapon::WeaponSecondaryAttack, @OnWeaponFire);
    g_Hooks.RegisterHook(Hooks::Game::MapChange, @OnMapChange);

    InitHud();
}

void MapInit()
{
    g_bFirstBlood = false;
    g_bLastManTriggered = false;
    g_NextSuicideTime = 0.0f;
    g_Bursts.deleteAll();

    PrecachePool(POOL_FIRSTBLOOD);
    PrecachePool(POOL_HEADSHOT);
    PrecachePool(POOL_HUMILIATE);
    PrecachePool(POOL_SUICIDE);
    PrecachePool(POOL_REVENGE);
    PrecachePool(POOL_ASSASSIN);
    PrecachePool(POOL_GRENADE);
    PrecachePool(POOL_PANCAKE);
    PrecachePool(POOL_SHUTDOWN);
    PrecachePool(POOL_TEAMKILL);
    PrecachePool(POOL_LASTMAN);
    PrecachePool(POOL_DOUBLEKILL);
    PrecachePool(POOL_TRIPLEKILL);
    PrecachePool(POOL_QUADRAKILL);
    PrecachePool(POOL_PENTAKILL);
    PrecachePool(POOL_HEXAKILL);

    for (uint i = 0; i < g_StreakTiers.length(); i++)
        PrecachePool(g_StreakTiers[i].sounds);

    for (int i = 1; i <= 32; i++)
        ResetPlayerSlot(i);

    LoadCfg();
    LoadPrefs();
    BuildBlacklist();
    BuildChances();
    ArmTip();
}

void PrecachePool(const array<string>& in pool)
{
    for (uint i = 0; i < pool.length(); i++)
    {
        string path = SND_PREFIX + pool[i];
        g_SoundSystem.PrecacheSound(path);
        g_Game.PrecacheGeneric("sound/" + path);
    }
}

string PickRandomSound(const array<string>& in pool)
{
    if (pool.length() == 0) return "";
    return SND_PREFIX + pool[Math.RandomLong(0, int(pool.length()) - 1)];
}

void ResetPlayerSlot(int idx)
{
    g_LastDmgType[idx] = 0;
    g_LastDmgTime[idx] = 0.0f;
    g_LastInflictor[idx] = EHandle();
    g_NextSoundTime[idx] = 0.0f;
    g_NextHelp[idx] = 0.0f;
}

HookReturnCode OnClientDisconnect(CBasePlayer@ pPlayer)
{
    if (pPlayer !is null)
        ResetPlayerSlot(pPlayer.entindex());
    return HOOK_CONTINUE;
}

// ---------------------------- PREFS / CONFIG / BLACKLIST --------------------
bool IsComment(const string &in l)
{
    return (l.Find("//") == 0 || l.Find("#") == 0);
}

string GetSteamId(CBasePlayer@ p)
{
    string id = g_EngineFuncs.GetPlayerAuthId(p.edict());
    if (id == "STEAM_ID_LAN") id = string(p.pev.netname);
    return id;
}

int64 PrefMask(CBasePlayer@ p)
{
    int64 m = 0;
    g_Pref.get(GetSteamId(p), m);
    return m;
}

void SetPref(CBasePlayer@ p, int64 m)
{
    g_Pref.set(GetSteamId(p), m);
}

void LoadSet(const string &in path, int64 bit)
{
    File@ f = g_FileSystem.OpenFile(path, OpenFile::READ);
    if (f is null || !f.IsOpen()) return;

    while (!f.EOFReached())
    {
        string line;
        f.ReadLine(line);
        line.Trim();
        if (line.IsEmpty() || IsComment(line)) continue;
        int64 m = 0;
        g_Pref.get(line, m);
        g_Pref.set(line, m | bit);
    }
    f.Close();
}

void SaveSet(const string &in path, int64 bit, const string &in header)
{
    File@ f = g_FileSystem.OpenFile(path, OpenFile::WRITE);
    if (f is null || !f.IsOpen()) return;
    f.Write(header);

    array<string>@ keys = g_Pref.getKeys();
    for (uint i = 0; i < keys.length(); i++)
    {
        int64 m = 0;
        g_Pref.get(keys[i], m);
        if ((m & bit) != 0)
            f.Write(keys[i] + "\n");
    }
    f.Close();
}

void SavePrefs()
{
    SaveSet(F_OFF_SND, OFF_SND, H_OFF_SND);
    SaveSet(F_OFF_HUD, OFF_HUD, H_OFF_HUD);
    SaveSet(F_OFF_NOTE, OFF_NOTE, H_OFF_NOTE);
    SaveSet(F_SEEN, P_SEEN, H_SEEN);
}

void LoadPrefs()
{
    g_Pref.deleteAll();

    // old !disable quakesounds list = everything off for those players (migrated once)
    File@ lf = g_FileSystem.OpenFile(F_LEGACY, OpenFile::READ);
    bool hadLegacy = (lf !is null && lf.IsOpen());
    if (hadLegacy) lf.Close();

    LoadSet(F_LEGACY, OFF_ALL | P_SEEN);
    LoadSet(F_OFF_SND, OFF_SND);
    LoadSet(F_OFF_HUD, OFF_HUD);
    LoadSet(F_OFF_NOTE, OFF_NOTE);
    LoadSet(F_SEEN, P_SEEN);

    if (hadLegacy)
    {
        SavePrefs();
        File@ t = g_FileSystem.OpenFile(F_LEGACY, OpenFile::WRITE);
        if (t !is null && t.IsOpen()) t.Close();
    }
}

void LoadCfg()
{
    File@ f = g_FileSystem.OpenFile(F_CFG, OpenFile::READ);
    if (f is null || !f.IsOpen()) return;

    bool chat = false, hud = false, note = false, assist = false, suic = false, last = false, tips = false;
    int aud = 2;
    int pvpMode = 2;

    while (!f.EOFReached())
    {
        string l;
        f.ReadLine(l);
        l.Trim();
        if (l == "chat") chat = true;
        else if (l == "hud") hud = true;
        else if (l == "notify") note = true;
        else if (l == "assist") assist = true;
        else if (l == "pvp0") pvpMode = 0;
        else if (l == "pvp1") pvpMode = 1;
        else if (l == "pvp2") pvpMode = 2;
        else if (l == "suicide") suic = true;
        else if (l == "lastman") last = true;
        else if (l == "tips") tips = true;
        else if (l == "aud0") aud = 0;
        else if (l == "aud1") aud = 1;
        else if (l == "aud2") aud = 2;
    }
    f.Close();

    CFG_CHAT_TEXT = chat;
    CFG_HUD = hud;
    CFG_NOTIFY = note;
    CFG_ASSIST = assist;
    CFG_PVP = pvpMode;
    CFG_SUICIDE_SOUND = suic;
    CFG_LASTMAN = last;
    CFG_AUDIENCE = aud;
    CFG_TIP_SECS = tips ? 300 : 0;
}

void SaveCfg()
{
    File@ f = g_FileSystem.OpenFile(F_CFG, OpenFile::WRITE);
    if (f is null || !f.IsOpen()) return;
    f.Write(H_CFG);

    if (CFG_CHAT_TEXT) f.Write("chat\n");
    if (CFG_HUD) f.Write("hud\n");
    if (CFG_NOTIFY) f.Write("notify\n");
    if (CFG_ASSIST) f.Write("assist\n");
    f.Write("pvp" + string(CFG_PVP) + "\n");
    if (CFG_SUICIDE_SOUND) f.Write("suicide\n");
    if (CFG_LASTMAN) f.Write("lastman\n");
    if (CFG_TIP_SECS > 0) f.Write("tips\n");
    f.Write("aud" + string(CFG_AUDIENCE) + "\n");
    f.Close();
}

void BuildBlacklist()
{
    g_NoStreak.deleteAll();

    array<string> d = {
        "worldspawn", "trigger_hurt", "trigger_hurt_remote", "trigger_multiple", "trigger_push",
        "func_door", "func_door_rotating", "func_train", "func_tracktrain", "func_pendulum",
        "func_rotating", "func_conveyor", "func_plat", "func_platrot", "func_wall", "func_wall_toggle",
        "func_breakable", "func_pushable", "func_button",
        "env_explosion", "env_laser", "env_beam", "env_shooter", "env_spark"
    };
    for (uint i = 0; i < d.length(); i++)
        g_NoStreak.set(d[i], 1);

    // extra classnames, one per line
    File@ f = g_FileSystem.OpenFile(F_BLACKLIST, OpenFile::READ);
    if (f is null || !f.IsOpen()) return;
    while (!f.EOFReached())
    {
        string line;
        f.ReadLine(line);
        line.Trim();
        if (!line.IsEmpty() && !IsComment(line))
            g_NoStreak.set(line, 1);
    }
    f.Close();
}

void BuildChances()
{
    g_MeleeChance.deleteAll();
    g_MeleeChance.set("monster_headcrab", 15);
    g_MeleeChance.set("monster_babycrab", 15);
    g_MeleeChance.set("monster_barnacle", 10);

    // classnames in this file never get Humiliation (0%), one per line
    File@ f = g_FileSystem.OpenFile(F_MELEE_BL, OpenFile::READ);
    if (f is null || !f.IsOpen()) return;
    while (!f.EOFReached())
    {
        string line;
        f.ReadLine(line);
        line.Trim();
        if (!line.IsEmpty() && !IsComment(line))
            g_MeleeChance.set(line, 0);
    }
    f.Close();
}

int MeleeChance(CBaseEntity@ atk)
{
    int64 v = 0;
    if (atk !is null && g_MeleeChance.get(atk.GetClassname(), v))
        return int(v);
    return CFG_MELEE_CHANCE;
}

bool Roll(int percent)
{
    if (percent >= 100) return true;
    if (percent <= 0) return false;
    return Math.RandomLong(0, 99) < percent;
}

bool IsNoStreak(CBaseEntity@ e)
{
    return (e !is null && g_NoStreak.exists(e.GetClassname()));
}

// ---------------------------- TIPS ------------------------------------------
CScheduledFunction@ g_TipTimer = null;

void ArmTip()
{
    if (g_TipTimer !is null && !g_TipTimer.HasBeenRemoved())
        g_Scheduler.RemoveTimer(g_TipTimer);
    @g_TipTimer = null;

    if (CFG_TIP_SECS > 0)
        @g_TipTimer = g_Scheduler.SetInterval("TipTick", float(CFG_TIP_SECS), g_Scheduler.REPEAT_INFINITE_TIMES);
}

void TipTick()
{
    for (int i = 1; i <= g_Engine.maxClients; i++)
    {
        CBasePlayer@ p = g_PlayerFuncs.FindPlayerByIndex(i);
        if (p is null || !p.IsConnected()) continue;
        if ((PrefMask(p) & P_SEEN) != 0) continue;
        g_PlayerFuncs.ClientPrint(p, HUD_PRINTTALK, CFG_PREFIX + "Quake sounds: say !qs to configure (!qs 0 = off)\n");
    }
}

void SetupHud(HUDTextParams &out p, float y, int channel)
{
    p.x = HUD_X;
    p.y = y;
    p.effect = 2;   // typewriter: each new letter flashes in color 2, then settles to color 1
    p.r1 = 64;  p.g1 = 160; p.b1 = 255; p.a1 = 255;
    p.r2 = 255; p.g2 = 255; p.b2 = 250; p.a2 = 255;
    p.fadeinTime = 0.1f;
    p.fadeoutTime = 0.6f;
    p.holdTime = 3.0f;
    p.fxTime = 0.04f;   // seconds per letter
    p.channel = channel;
}

void InitHud()
{
    SetupHud(g_HudP, HUD_Y, HUD_CHANNEL);
    int flavorChannel = HUD_CHANNEL + 1;
    if (HUD_FLAVOR_DY == 0.0f) flavorChannel = HUD_CHANNEL;   // same spot and channel: the flavor text replaces the main text
    SetupHud(g_HudP2, HUD_Y + HUD_FLAVOR_DY, flavorChannel);
}

// ---------------------------- COMMANDS --------------------------------------
bool IsCmd(const string &in cmd, const string &in name)
{
    return (cmd == "!" + name || cmd == "/" + name || cmd == "." + name);
}

string St(bool on)
{
    if (on) return "ON";
    return "OFF";
}

void SendHelp(CBasePlayer@ p)
{
    g_PlayerFuncs.ClientPrint(p, HUD_PRINTTALK, CFG_PREFIX + "Quake sounds: say !qs for the menu | !qs 0 = all off | !qs 1 = all on\n");
    g_PlayerFuncs.ClientPrint(p, HUD_PRINTTALK, CFG_PREFIX + "!qs snd / !qs hud / !qs feed toggle: sound / big text / kill feed\n");
}

void SendTest(CBasePlayer@ p)
{
    g_PlayerFuncs.ClientPrint(p, HUD_PRINTTALK, CFG_PREFIX + "cfg: text " + St(CFG_HUD) + ", feed " + St(CFG_NOTIFY) +
        ", chat " + St(CFG_CHAT_TEXT) + ", audience: " + AudName(CFG_AUDIENCE) + "\n");
    SendStatus(p, PrefMask(p));
    g_PlayerFuncs.ClientPrint(p, HUD_PRINTNOTIFY, CFG_PREFIX + "test: notify\n");
    g_PlayerFuncs.ClientPrint(p, HUD_PRINTCONSOLE, CFG_PREFIX + "test: console\n");
    g_PlayerFuncs.HudMessage(p, g_HudP, "Test: big text");
}

void SendStatus(CBasePlayer@ p, int64 m)
{
    g_PlayerFuncs.ClientPrint(p, HUD_PRINTTALK, CFG_PREFIX + "sound " + St((m & OFF_SND) == 0) +
        " | text " + St((m & OFF_HUD) == 0) + " | feed " + St((m & OFF_NOTE) == 0) + "\n");
}

HookReturnCode OnClientSay(SayParameters@ pParams)
{
    CBasePlayer@ p = pParams.GetPlayer();
    const CCommand@ args = pParams.GetArguments();
    if (p is null || args.ArgC() < 1) return HOOK_CONTINUE;

    string cmd = args[0].ToLowercase();
    int idx = p.entindex();

    // the bare word "quake" shows help, the message itself stays visible
    if (args.ArgC() == 1 && cmd == "quake")
    {
        if (g_Engine.time >= g_NextHelp[idx])
        {
            g_NextHelp[idx] = g_Engine.time + 20.0f;
            SendHelp(p);
        }
        return HOOK_CONTINUE;
    }

    if (!IsCmd(cmd, "qs") && !IsCmd(cmd, "quake")) return HOOK_CONTINUE;

    pParams.ShouldHide = true;

    string a = "";
    if (args.ArgC() > 1) a = args[1].ToLowercase();

    if (a == "admin")
    {
        if (g_PlayerFuncs.AdminLevel(p) >= ADMIN_YES)
        {
            g_MenuPage[idx] = 0;
            OpenMenu(p, true);
        }
        else g_PlayerFuncs.ClientPrint(p, HUD_PRINTTALK, CFG_PREFIX + "Admins only.\n");
        return HOOK_HANDLED;
    }

    if (a == "test" && CFG_DEBUG)
    {
        SendTest(p);
        return HOOK_HANDLED;
    }

    int64 m = PrefMask(p) | P_SEEN;

    if (a.IsEmpty())
    {
        SetPref(p, m);
        SavePrefs();
        OpenMenu(p, false);
        return HOOK_HANDLED;
    }

    if (a == "0" || a == "off")        m = m | OFF_ALL;
    else if (a == "1" || a == "on")    m = m & ~OFF_ALL;
    else if (a == "snd")               m = m ^ OFF_SND;
    else if (a == "hud")               m = m ^ OFF_HUD;
    else if (a == "feed")              m = m ^ OFF_NOTE;
    else
    {
        SendHelp(p);
        return HOOK_HANDLED;
    }

    SetPref(p, m);
    SavePrefs();
    SendStatus(p, m);
    return HOOK_HANDLED;
}

// ---------------------------- MENUS -----------------------------------------
array<CTextMenu@> g_Menus(33);
array<int> g_MenuPage(33, 0);

string PvpName(int m)
{
    if (m == 0) return "Off";
    if (m == 1) return "On";
    return "Auto";
}

bool PvpActive()
{
    if (CFG_PVP == 1) return true;
    if (CFG_PVP == 0) return false;
    return g_EngineFuncs.CVarGetFloat("mp_friendlyfire") > 0.0f;
}

string AudName(int a)
{
    if (a == 0) return "Admins only";
    if (a == 1) return "Victim + admins";
    return "Everyone";
}

void OpenMenu(CBasePlayer@ p, bool admin)
{
    if (p is null || !p.IsConnected()) return;
    int i = p.entindex();

    @g_Menus[i] = null;

    CTextMenu@ m;
    if (admin) @m = CTextMenu(@AdminMenuCB);
    else       @m = CTextMenu(@PlayerMenuCB);

    if (admin)
    {
        m.SetTitle("Quake Sounds - admin\n");
        if (g_MenuPage[i] == 0)
        {
            m.AddItem("Audience: " + AudName(CFG_AUDIENCE), any("aud"));
            m.AddItem("Big text: " + St(CFG_HUD), any("hud"));
            m.AddItem("Kill feed: " + St(CFG_NOTIFY), any("note"));
            m.AddItem("Chat lines: " + St(CFG_CHAT_TEXT), any("chat"));
            m.AddItem("Admin assist: " + St(CFG_ASSIST), any("assist"));
            m.AddItem("PvP mode: " + PvpName(CFG_PVP), any("pvp"));
            m.AddItem("More", any("next"));
        }
        else
        {
            m.AddItem("Suicide / world: " + St(CFG_SUICIDE_SOUND), any("suicide"));
            m.AddItem("Last man: " + St(CFG_LASTMAN), any("lastman"));
            m.AddItem("Tips: " + St(CFG_TIP_SECS > 0), any("tips"));
            m.AddItem("", any(""));
            m.AddItem("", any(""));
            m.AddItem("", any(""));
            m.AddItem("Back", any("prev"));
        }
    }
    else
    {
        int64 off = PrefMask(p);
        m.SetTitle("Quake Sounds\n");
        m.AddItem("Sounds: " + St((off & OFF_SND) == 0), any("snd"));
        m.AddItem("Big text: " + St((off & OFF_HUD) == 0), any("hud"));
        m.AddItem("Kill feed: " + St((off & OFF_NOTE) == 0), any("feed"));
        m.AddItem("All ON", any("on"));
        m.AddItem("All OFF", any("off"));
    }

    m.Register();
    @g_Menus[i] = m;
    m.Open(0, 0, p);
}

HookReturnCode OnMapChange(const string &in szNextMap)
{
    for (uint i = 0; i < g_Menus.length(); i++)
        @g_Menus[i] = null;
    return HOOK_CONTINUE;
}

void ReopenMenu(EHandle hPlayer, bool admin)
{
    CBasePlayer@ p = cast<CBasePlayer@>(hPlayer.GetEntity());
    OpenMenu(p, admin);
}

void PlayerMenuCB(CTextMenu@ menu, CBasePlayer@ p, int page, const CTextMenuItem@ item)
{
    if (item is null || p is null) return;

    string key;
    item.m_pUserData.retrieve(key);

    int64 m = PrefMask(p) | P_SEEN;
    if (key == "snd")       m = m ^ OFF_SND;
    else if (key == "hud")  m = m ^ OFF_HUD;
    else if (key == "feed") m = m ^ OFF_NOTE;
    else if (key == "on")   m = m & ~OFF_ALL;
    else if (key == "off")  m = m | OFF_ALL;

    SetPref(p, m);
    SavePrefs();
    g_Scheduler.SetTimeout("ReopenMenu", 0.05f, EHandle(p), false);
}

void AdminMenuCB(CTextMenu@ menu, CBasePlayer@ p, int page, const CTextMenuItem@ item)
{
    if (p is null) return;
    if (item is null)
    {
        g_MenuPage[p.entindex()] = 0;
        return;
    }
    if (g_PlayerFuncs.AdminLevel(p) < ADMIN_YES) return;

    string key;
    item.m_pUserData.retrieve(key);

    if (key == "next")          g_MenuPage[p.entindex()] = 1;
    else if (key == "prev")     g_MenuPage[p.entindex()] = 0;
    else if (key == "aud")      CFG_AUDIENCE = (CFG_AUDIENCE + 1) % 3;
    else if (key == "hud")      CFG_HUD = !CFG_HUD;
    else if (key == "note")     CFG_NOTIFY = !CFG_NOTIFY;
    else if (key == "chat")     CFG_CHAT_TEXT = !CFG_CHAT_TEXT;
    else if (key == "assist")   CFG_ASSIST = !CFG_ASSIST;
    else if (key == "pvp")      CFG_PVP = (CFG_PVP + 1) % 3;
    else if (key == "suicide")  CFG_SUICIDE_SOUND = !CFG_SUICIDE_SOUND;
    else if (key == "lastman")  CFG_LASTMAN = !CFG_LASTMAN;
    else if (key == "tips")
    {
        if (CFG_TIP_SECS > 0) CFG_TIP_SECS = 0;
        else CFG_TIP_SECS = 300;
        ArmTip();
    }

    SaveCfg();
    g_Scheduler.SetTimeout("ReopenMenu", 0.05f, EHandle(p), true);
}

// ---------------------------- DEBUG TIMELINE --------------------------------
string YN(bool b)
{
    if (b) return "yes";
    return "no";
}

string Ts()
{
    int cs = int(g_Engine.time * 100.0f);
    int frac = cs % 100;
    string f = string(frac);
    if (frac < 10) f = "0" + f;
    return string(cs / 100) + "." + f;
}

string Fs(float x)
{
    int d = int(x * 10.0f);
    return string(d / 10) + "." + string(d % 10);
}

void DebugLog(const string &in msg)
{
    string line = "[QS " + Ts() + "] " + msg + "\n";
    g_Game.AlertMessage(at_console, line);
    for (int i = 1; i <= g_Engine.maxClients; i++)
    {
        CBasePlayer@ p = g_PlayerFuncs.FindPlayerByIndex(i);
        if (p !is null && p.IsConnected() && g_PlayerFuncs.AdminLevel(p) >= ADMIN_YES)
            g_PlayerFuncs.ClientPrint(p, HUD_PRINTCONSOLE, line);
    }
}

bool DbgFor(CBasePlayer@ p)
{
    return (CFG_DEBUG && p !is null && g_PlayerFuncs.AdminLevel(p) >= ADMIN_YES);
}

// ---------------------------- SOUND ROUTING ---------------------------------
bool ShouldPlayerReceive(CBasePlayer@ listener, CBasePlayer@ primaryTarget)
{
    if (listener is null || !listener.IsConnected())
        return false;

    bool isAdmin = (g_PlayerFuncs.AdminLevel(listener) >= ADMIN_YES);

    if (CFG_AUDIENCE == 0) return isAdmin;
    if (CFG_AUDIENCE == 1) return (isAdmin || (primaryTarget !is null && listener is primaryTarget));
    return true;
}

void QueueSound(CBasePlayer@ pPlayer, const string &in snd)
{
    if (snd.IsEmpty() || pPlayer is null || !pPlayer.IsConnected())
        return;

    int idx = pPlayer.entindex();
    float now = g_Engine.time;

    if (g_NextSoundTime[idx] < now)
        g_NextSoundTime[idx] = now;

    float delay = g_NextSoundTime[idx] - now;
    if (delay > CFG_EVENT_DELAY * CFG_MAX_QUEUE)
    {
        if (DbgFor(pPlayer))
            DebugLog("sound DROPPED (backlog " + Fs(delay) + "s): " + snd);
        return;
    }

    if (DbgFor(pPlayer))
        DebugLog("sound queued for " + string(pPlayer.pev.netname) + ": " + snd + ", starts in " + Fs(delay) + "s");

    g_NextSoundTime[idx] += CFG_EVENT_DELAY;

    if (delay <= 0.0f)
        PlayNow(EHandle(pPlayer), snd);
    else
        g_Scheduler.SetTimeout("PlayNow", delay, EHandle(pPlayer), snd);
}

void PlayNow(EHandle hPlayer, const string &in snd)
{
    CBaseEntity@ ent = hPlayer.GetEntity();
    if (ent is null) return;
    CBasePlayer@ pPlayer = cast<CBasePlayer@>(ent);
    if (pPlayer is null || !pPlayer.IsConnected()) return;

    if (DbgFor(pPlayer))
        DebugLog("sound PLAY for " + string(pPlayer.pev.netname) + ": " + snd);

    // SND_FORCE_SINGLE: only this client hears it
    g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_STATIC, snd, 1.0f, ATTN_NONE, SND_FORCE_SINGLE, PITCH_NORM, pPlayer.entindex());
}

void AnnounceEvent(Ev@ ev, const string &in snd, CBasePlayer@ primaryTarget)
{
    if (CFG_DEBUG)
    {
        string kind = "main";
        if (ev.slot == 1) kind = "flavor";
        DebugLog("announce (" + kind + ") [" + ev.hud + "] snd " + snd);
    }

    for (int i = 1; i <= g_Engine.maxClients; i++)
    {
        CBasePlayer@ listener = g_PlayerFuncs.FindPlayerByIndex(i);
        if (!ShouldPlayerReceive(listener, primaryTarget))
            continue;

        int64 off = PrefMask(listener);

        if (CFG_CHAT_TEXT)
            g_PlayerFuncs.ClientPrint(listener, HUD_PRINTTALK, CFG_PREFIX + ev.note);

        if (CFG_NOTIFY && (off & OFF_NOTE) == 0)
            g_PlayerFuncs.ClientPrint(listener, HUD_PRINTNOTIFY, ev.note);

        if (CFG_HUD && (off & OFF_HUD) == 0)
        {
            if (ev.slot == 1) g_PlayerFuncs.HudMessage(listener, g_HudP2, ev.hud);
            else              g_PlayerFuncs.HudMessage(listener, g_HudP, ev.hud);
        }

        if (!snd.IsEmpty() && (off & OFF_SND) == 0)
            QueueSound(listener, snd);
    }
}

// ---------------------------- ENTITY HELPERS --------------------------------
string FormatEntityName(CBaseEntity@ e)
{
    if (e is null) return "world";
    if (e.IsPlayer()) return string(e.pev.netname);

    // display name (mapper "displayname" kv): API accessor unverified, uncomment to test
    // CBaseMonster@ pm = e.MyMonsterPointer();
    // if (pm !is null && !string(pm.m_FormattedName).IsEmpty()) return string(pm.m_FormattedName);

    string cname = e.GetClassname();
    if (g_PrettyNames.exists(cname))
    {
        string pretty;
        g_PrettyNames.get(cname, pretty);
        return pretty;
    }
    return PrettyClass(cname);
}

string PrettyClass(const string &in cn)
{
    string s = cn;
    if (s.Find("monster_") == 0) s = s.SubString(8);

    string res = "";
    bool up = true;
    for (uint i = 0; i < s.Length(); i++)
    {
        string c = s.SubString(i, 1);
        if (c == "_")
        {
            res += " ";
            up = true;
        }
        else
        {
            if (up) res += c.ToUppercase();
            else    res += c;
            up = false;
        }
    }
    return res;
}

int GetEntityIntKV(CBaseEntity@ e, const string &in key)
{
    if (e is null) return 0;
    CustomKeyvalues@ kv = e.GetCustomKeyvalues();
    CustomKeyvalue val = kv.GetKeyvalue(key);
    return val.Exists() ? val.GetInteger() : 0;
}

float GetEntityFloatKV(CBaseEntity@ e, const string &in key)
{
    if (e is null) return 0.0f;
    CustomKeyvalues@ kv = e.GetCustomKeyvalues();
    CustomKeyvalue val = kv.GetKeyvalue(key);
    return val.Exists() ? val.GetFloat() : 0.0f;
}

void SetEntityIntKV(CBaseEntity@ e, const string &in key, int v)
{
    if (e is null) return;
    e.GetCustomKeyvalues().SetKeyvalue(key, v);
}

void SetEntityFloatKV(CBaseEntity@ e, const string &in key, float v)
{
    if (e is null) return;
    e.GetCustomKeyvalues().SetKeyvalue(key, v);
}

void ResetChain(CBaseEntity@ e)
{
    if (CFG_DEBUG && e !is null && GetEntityIntKV(e, "$i_aqs_kills") > 0)
        DebugLog("chain reset #" + string(e.entindex()) + " " + FormatEntityName(e) + " (had " + string(GetEntityIntKV(e, "$i_aqs_kills")) + " kills)");

    SetEntityIntKV(e, "$i_aqs_kills", 0);
    SetEntityIntKV(e, "$i_aqs_multicount", 0);
    SetEntityFloatKV(e, "$f_aqs_lastkill", 0.0f);
    SetEntityIntKV(e, "$i_aqs_lastvictim", 0);
}

// Player itself, or the player who owns a projectile/explosive
CBasePlayer@ ResolvePlayer(CBaseEntity@ e)
{
    if (e is null) return null;
    if (e.IsPlayer()) return cast<CBasePlayer@>(e);
    if (e.pev.owner !is null)
    {
        CBaseEntity@ o = g_EntityFuncs.Instance(e.pev.owner);
        if (o !is null && o.IsPlayer()) return cast<CBasePlayer@>(o);
    }
    return null;
}

// ---------------------------- GREY-ZONE ASSIST (admins) ---------------------
HookReturnCode OnWeaponFire(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon)
{
    if (pPlayer is null) return HOOK_CONTINUE;

    Math.MakeVectors(pPlayer.pev.v_angle);
    Vector vecSrc = pPlayer.GetGunPosition();
    Vector vecEnd = vecSrc + g_Engine.v_forward * 4096.0f;

    TraceResult tr;
    g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr);

    if (tr.pHit !is null)
    {
        CBaseEntity@ pHit = g_EntityFuncs.Instance(tr.pHit);
        if (pHit !is null && IsExplosiveOrBreakable(pHit))
        {
            SetEntityIntKV(pHit, "$i_aqs_shooter", pPlayer.entindex());
            SetEntityFloatKV(pHit, "$f_aqs_time", g_Engine.time);
        }
    }
    return HOOK_CONTINUE;
}

bool IsExplosiveOrBreakable(CBaseEntity@ e)
{
    if (e.IsBreakable()) return true;
    string cn = e.GetClassname();
    return (cn == "func_pushable" || cn == "env_explosion" || cn == "monster_satchel" || cn == "monster_tripmine");
}

void CheckGreyZoneAssist(CBasePlayer@ victim, CBaseEntity@ atk, CBaseEntity@ infl)
{
    if (!CFG_ASSIST) return;

    CBaseEntity@ sourceObj = (infl !is null && !infl.IsPlayer()) ? infl : atk;
    if (sourceObj is null || sourceObj.IsPlayer()) return;

    int suspectIdx = 0;

    CBasePlayer@ owner = ResolvePlayer(sourceObj);
    if (owner !is null)
        suspectIdx = owner.entindex();

    if (suspectIdx == 0)
    {
        int shooter = GetEntityIntKV(sourceObj, "$i_aqs_shooter");
        float shotTime = GetEntityFloatKV(sourceObj, "$f_aqs_time");
        if (shooter > 0 && (g_Engine.time - shotTime) <= ASSIST_EXPIRE)
            suspectIdx = shooter;
    }

    if (suspectIdx <= 0 || suspectIdx == victim.entindex()) return;

    CBasePlayer@ suspect = g_PlayerFuncs.FindPlayerByIndex(suspectIdx);
    if (suspect is null || !suspect.IsConnected()) return;

    float dist = (suspect.pev.origin - victim.pev.origin).Length();
    string distTag = (dist <= TROLL_RADIUS) ? " [CLOSE: " + string(int(dist)) + "u]" : " [" + string(int(dist)) + "u]";

    string adminMsg = "[QS-ASSIST] " + string(suspect.pev.netname) + " -> " +
                      sourceObj.GetClassname() + " (*" + string(sourceObj.entindex()) + ") -> " +
                      string(victim.pev.netname) + distTag + "\n";

    for (int i = 1; i <= g_Engine.maxClients; i++)
    {
        CBasePlayer@ p = g_PlayerFuncs.FindPlayerByIndex(i);
        if (p !is null && p.IsConnected() && g_PlayerFuncs.AdminLevel(p) >= ADMIN_YES)
            g_PlayerFuncs.ClientPrint(p, HUD_PRINTNOTIFY, adminMsg);
    }
}

// ---------------------------- DAMAGE / KILL CLASSIFICATION ------------------
HookReturnCode OnPlayerTakeDamage(DamageInfo@ info)
{
    CBasePlayer@ pVictim = cast<CBasePlayer@>(info.pVictim);
    if (pVictim is null) return HOOK_CONTINUE;

    int vi = pVictim.entindex();
    g_LastDmgType[vi] = info.bitsDamageType;
    g_LastDmgTime[vi] = g_Engine.time;
    g_LastInflictor[vi] = EHandle(info.pInflictor);

    return HOOK_CONTINUE;
}

bool IsCrushKill(CBaseEntity@ atk, int dmgBits)
{
    if ((dmgBits & DMG_CRUSH) != 0) return true;
    if (atk is null) return false;
    string cn = atk.GetClassname();
    return (cn == "func_door" || cn == "func_door_rotating" || cn == "func_train" ||
            cn == "func_tracktrain" || cn == "func_pendulum" || cn == "func_rotating");
}

// Monster claws / bite: direct attack (inflictor == attacker) with slash/club flags
bool IsMeleeKill(CBaseEntity@ atk, CBaseEntity@ infl, int dmgBits)
{
    return (atk !is null && infl is atk && (dmgBits & (DMG_CLUB | DMG_SLASH)) != 0);
}

bool IsAssassinKill(CBaseEntity@ atk)
{
    if (atk is null) return false;
    string cn = atk.GetClassname();
    return (cn == "monster_human_assassin" || cn == "monster_male_assassin");
}

bool FlavorReady(CBaseEntity@ atk)
{
    float now = g_Engine.time;
    float last = GetEntityFloatKV(atk, "$f_aqs_flavor");
    if (last > 0.0f && (now - last) < CFG_FLAVOR_COOLDOWN)
        return false;
    SetEntityFloatKV(atk, "$f_aqs_flavor", now);
    return true;
}

void CheckLastManStanding(CBasePlayer@ dying)
{
    if (!CFG_LASTMAN || g_bLastManTriggered) return;

    int totalConnected = 0;
    int totalAlive = 0;
    CBasePlayer@ lastSurvivor = null;

    for (int i = 1; i <= g_Engine.maxClients; i++)
    {
        CBasePlayer@ p = g_PlayerFuncs.FindPlayerByIndex(i);
        if (p !is null && p.IsConnected())
        {
            totalConnected++;
            if (p !is dying && p.IsAlive()) // the victim may still look alive inside the hook
            {
                totalAlive++;
                @lastSurvivor = p;
            }
        }
    }

    if (totalConnected >= CFG_LASTMAN_MIN_PLAYERS && totalAlive == 1 && lastSurvivor !is null)
    {
        g_bLastManTriggered = true;
        AnnounceEvent(MsgSolo(T_LASTMAN, string(lastSurvivor.pev.netname)), PickRandomSound(POOL_LASTMAN), lastSurvivor);
    }
    else if (totalAlive > 1)
    {
        g_bLastManTriggered = false;
    }
}

// ---------------------------- KILL BURST (multikill + streak coalescing) ----
void RegisterBurstKill(CBaseEntity@ atk, CBasePlayer@ victim, const string &in atkName, int multiCount, int totalKills,
                       const string &in fTitle, const string &in fSnd, const string &in victimName,
                       bool preShout, bool sameVictim)
{
    string key = string(atk.entindex());
    KillBurst@ b;

    if (!g_Bursts.get(key, @b))
    {
        @b = KillBurst();
        b.startKills = totalKills - 1;
        g_Bursts.set(key, @b);
    }
    else if (b.timer !is null)
    {
        g_Scheduler.RemoveTimer(b.timer);
    }

    b.name = atkName;
    if (preShout) b.preShout = true;
    b.hAtk = EHandle(atk);
    b.hVictim = EHandle(victim);
    if (!fTitle.IsEmpty())
    {
        b.fTitle = fTitle;
        b.fSnd = fSnd;
        b.fVictim = victimName;
    }
    b.multi = multiCount;
    b.total = totalKills;
    // same victim again: announce right away. Different victim: short timer so simultaneous kills do not stack
    float wait = CFG_BURST_DEBOUNCE;
    if (sameVictim) wait = 0.0f;
    if (CFG_DEBUG)
    {
        string why = "debounce, different victim";
        if (sameVictim) why = "same victim, no wait";
        DebugLog("burst #" + key + ": flush in " + Fs(wait) + "s (" + why + ")");
    }
    @b.timer = g_Scheduler.SetTimeout("FlushBurst", wait, key);
}

void FlushBurstNow(CBaseEntity@ e)
{
    string key = string(e.entindex());
    KillBurst@ b;
    if (g_Bursts.get(key, @b))
    {
        if (b.timer !is null)
            g_Scheduler.RemoveTimer(b.timer);
        FlushBurst(key);
    }
}

void AnnounceMulti(const string &in name, int n, CBasePlayer@ victim)
{
    int k = (n > 6) ? 6 : n;
    string snd;
    if (k == 2)      snd = PickRandomSound(POOL_DOUBLEKILL);
    else if (k == 3) snd = PickRandomSound(POOL_TRIPLEKILL);
    else if (k == 4) snd = PickRandomSound(POOL_QUADRAKILL);
    else if (k == 5) snd = PickRandomSound(POOL_PENTAKILL);
    else             snd = PickRandomSound(POOL_HEXAKILL);

    AnnounceEvent(MsgSolo(MULTI_TITLES[k], name), snd, victim);
}

void FlushBurst(string key)
{
    KillBurst@ b;
    if (!g_Bursts.get(key, @b)) return;
    g_Bursts.delete(key);

    CBasePlayer@ victim = cast<CBasePlayer@>(b.hVictim.GetEntity());

    if (CFG_DEBUG)
        DebugLog("flush #" + key + ": multi " + string(b.multi) + ", total " + string(b.total) +
                 ", first blood " + YN(b.preShout) + ", flavor " + b.fTitle);

    // highest streak tier crossed during this burst (tiers are ascending, last match wins)
    StreakTier@ best = null;
    for (uint i = 0; i < g_StreakTiers.length(); i++)
    {
        int k = g_StreakTiers[i].kills;
        if (k >= CFG_STREAK_MIN_KILLS && k > b.startKills && k <= b.total)
            @best = g_StreakTiers[i];
    }

    // multikill > streak tier; melee/headshot/... follow CFG_FLAVOR_OFFSET later so the two sounds do not overlap
    bool streakSpoke = b.preShout;   // first blood counts as a shout too

    if (b.multi >= 2 && b.multi <= 6)
    {
        AnnounceMulti(b.name, b.multi, victim);
        streakSpoke = true;
    }
    else if (best !is null)
    {
        AnnounceEvent(MsgSolo(best.title, b.name, string(b.total) + " kills"), PickRandomSound(best.sounds), victim);
        streakSpoke = true;
    }

    if (!b.fTitle.IsEmpty() && (!streakSpoke || CFG_FLAVOR_WITH_STREAK))
    {
        CBaseEntity@ atkEnt = b.hAtk.GetEntity();
        if (atkEnt !is null && FlavorReady(atkEnt))
        {
            if (streakSpoke)
            {
                if (CFG_DEBUG)
                    DebugLog("flavor " + b.fTitle + " delayed by " + Fs(CFG_FLAVOR_OFFSET) + "s");
                g_Scheduler.SetTimeout("DelayedFlavor", CFG_FLAVOR_OFFSET, b.fTitle, b.name, b.fVictim, b.fSnd, b.hVictim);
            }
            else
                AnnounceEvent(MsgVs(b.fTitle, b.name, b.fVictim), b.fSnd, victim);
        }
        else if (CFG_DEBUG)
            DebugLog("flavor " + b.fTitle + " skipped (cooldown " + Fs(CFG_FLAVOR_COOLDOWN) + "s)");
    }
}

void DelayedFlavor(string title, string a, string v, string snd, EHandle hVictim)
{
    if (CFG_DEBUG)
        DebugLog("flavor timer fired: " + title);
    CBasePlayer@ victim = cast<CBasePlayer@>(hVictim.GetEntity());
    Ev@ ev = MsgVs(title, a, v);
    ev.slot = 1;
    AnnounceEvent(ev, snd, victim);
}

// ---------------------------- PLAYER KILLED ---------------------------------
HookReturnCode OnPlayerKilled(CBasePlayer@ victim, CBaseEntity@ atk, int iGib)
{
    if (victim is null) return HOOK_CONTINUE;

    int vi = victim.entindex();
    string victimName = string(victim.pev.netname);
    CBaseEntity@ infl = g_LastInflictor[vi].GetEntity();
    int dmgBits = g_LastDmgType[vi];

    // damage info that is not from this death (kill command, etc.) must not leak in
    if (g_Engine.time - g_LastDmgTime[vi] > CFG_DMG_STALE)
    {
        @infl = null;
        dmgBits = 0;
    }

    CheckGreyZoneAssist(victim, atk, infl);

    string atkName;
    if (atk is victim) atkName = "self";
    else               atkName = FormatEntityName(atk);

    bool isSelfOrWorld = (atk is null || atk is victim ||
                          atk.GetClassname() == "worldspawn" || atk.GetClassname() == "trigger_hurt");

    // one sound per death: first blood takes priority over flavor / suicide sounds
    bool announced = false;

    if (!g_bFirstBlood)
    {
        g_bFirstBlood = true;
        announced = true;
        AnnounceEvent(MsgVs(T_FIRSTBLOOD, atkName, victimName), PickRandomSound(POOL_FIRSTBLOOD), victim);
    }

    if (isSelfOrWorld)
    {
        if (!announced && CFG_SUICIDE_SOUND && g_Engine.time >= g_NextSuicideTime)
        {
            if (Roll(CFG_SUICIDE_CHANCE))
            {
                g_NextSuicideTime = g_Engine.time + CFG_SUICIDE_COOLDOWN;
                AnnounceEvent(MsgSolo(T_SUICIDE, victimName, atkName), PickRandomSound(POOL_SUICIDE), victim);
            }
            else if (CFG_DEBUG)
                DebugLog("suicide laugh skipped (chance " + string(CFG_SUICIDE_CHANCE) + "%)");
        }
    }
    else if (atk.IsPlayer() && !PvpActive())
    {
        if (!announced)
            AnnounceEvent(MsgVs(T_TEAMKILL, atkName, victimName), PickRandomSound(POOL_TEAMKILL), victim);
    }
    else
    {
        // monster / entity killer (or a player in PvP mode): remember who it killed (for PAYBACK)
        SetEntityIntKV(atk, "$i_aqs_victim_" + string(vi), 1);

        // flavor: one per death, rate-limited per attacker
        string fTitle = "";
        string fSnd = "";
        if (IsCrushKill(atk, dmgBits))
        {
            fTitle = T_PANCAKE;
            fSnd = PickRandomSound(POOL_PANCAKE);
        }
        else if (IsMeleeKill(atk, infl, dmgBits))
        {
            int chance = MeleeChance(atk);
            if (Roll(chance))
            {
                fTitle = T_MELEE;
                fSnd = PickRandomSound(POOL_HUMILIATE);
            }
            else if (CFG_DEBUG)
                DebugLog("melee skipped for " + atk.GetClassname() + " (chance " + string(chance) + "%)");
        }
        else if (victim.m_LastHitGroup == HITGROUP_HEAD)
        {
            fTitle = T_HEADSHOT;
            fSnd = PickRandomSound(POOL_HEADSHOT);
        }
        else if (IsAssassinKill(atk))
        {
            fTitle = T_ASSASSIN;
            fSnd = PickRandomSound(POOL_ASSASSIN);
        }
        else if ((dmgBits & DMG_BLAST) != 0)
        {
            fTitle = T_BLAST;
            fSnd = PickRandomSound(POOL_GRENADE);
        }

        if (!IsNoStreak(atk))
        {
            float now = g_Engine.time;
            float lastKillTime = GetEntityFloatKV(atk, "$f_aqs_lastkill");
            int multiCount = GetEntityIntKV(atk, "$i_aqs_multicount");

            bool sameVictim = (GetEntityIntKV(atk, "$i_aqs_lastvictim") == vi);

            // monsters never expire; players need to keep up within the window
            if (lastKillTime > 0.0f && (!atk.IsPlayer() || (now - lastKillTime) <= MULTIKILL_WINDOW))
                multiCount++;
            else
                multiCount = 1;

            SetEntityIntKV(atk, "$i_aqs_lastvictim", vi);

            SetEntityFloatKV(atk, "$f_aqs_lastkill", now);
            SetEntityIntKV(atk, "$i_aqs_multicount", multiCount);

            int totalKills = GetEntityIntKV(atk, "$i_aqs_kills") + 1;
            SetEntityIntKV(atk, "$i_aqs_kills", totalKills);

            if (CFG_DEBUG)
            {
                string gap = "-";
                if (lastKillTime > 0.0f) gap = Fs(now - lastKillTime) + "s";
                DebugLog("kill #" + string(atk.entindex()) + " " + atkName + " -> " + victimName + " | gap " + gap +
                         " | chain " + string(multiCount) + " | total " + string(totalKills) +
                         " | same victim " + YN(sameVictim) + " | first blood " + YN(announced) + " | flavor " + fTitle);
            }

            RegisterBurstKill(atk, victim, atkName, multiCount, totalKills, fTitle, fSnd, victimName, announced, sameVictim);
        }
        else if (!fTitle.IsEmpty() && !announced && FlavorReady(atk))
        {
            AnnounceEvent(MsgVs(fTitle, atkName, victimName), fSnd, victim);
        }
    }

    ResetChain(victim);   // a dead player's streak is over
    CheckLastManStanding(victim);
    return HOOK_CONTINUE;
}

// ---------------------------- MONSTER KILLED --------------------------------
HookReturnCode OnMonsterKilled(CBaseMonster@ pMonster, CBaseEntity@ pAttacker, int iGib)
{
    if (pMonster is null || pMonster.IsPlayer())
        return HOOK_CONTINUE;

    CBasePlayer@ killer = ResolvePlayer(pAttacker); // also resolves grenades / satchels by owner
    if (killer is null)
    {
        ResetChain(pMonster);
        return HOOK_CONTINUE;
    }

    // finish the monster's pending burst announcement before SHUTDOWN / PAYBACK
    FlushBurstNow(pMonster);

    int ki = killer.entindex();
    string killerName = string(killer.pev.netname);
    string monsterName = FormatEntityName(pMonster);

    int monsterStreak = GetEntityIntKV(pMonster, "$i_aqs_kills");
    bool hadVendetta  = (GetEntityIntKV(pMonster, "$i_aqs_victim_" + string(ki)) == 1);

    // PAYBACK (personal) has priority over SHUTDOWN
    if (hadVendetta)
    {
        SetEntityIntKV(pMonster, "$i_aqs_victim_" + string(ki), 0);
        AnnounceEvent(MsgVs(T_PAYBACK, killerName, monsterName), PickRandomSound(POOL_REVENGE), killer);
    }
    else if (monsterStreak >= SHUTDOWN_MIN_KILLS)
    {
        SetEntityIntKV(pMonster, "$i_aqs_kills", 0);
        AnnounceEvent(MsgVs(T_SHUTDOWN, killerName, monsterName, string( monsterStreak ) + "-kill streak"),
                      PickRandomSound(POOL_SHUTDOWN), killer);
    }

    ResetChain(pMonster);
    return HOOK_CONTINUE;
}