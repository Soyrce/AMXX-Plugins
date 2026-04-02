#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>
#include <nvault_util>
#include <engine>

/* 
------------------------------------------------------------------
    Plugin: Surf Mission & Crate System (Final Edition)
    Version: 4.5
    Author: Ariel - CheezPuff
------------------------------------------------------------------
*/

#define PLUGIN          "Surf Mission System"
#define VERSION         "4.5"
#define AUTHOR          "CheezPuff"

#define CHAT_PREFIX     "^4[Missions]^1"
#define MAX_MISSIONS    30
#define MAX_PLAYERS     32
#define m_pPlayer       41
#define VAULT_NAME      "surf_missions_final"

// --- Mission Types ---
enum {
    TYPE_KILLS = 0,
    TYPE_HEADSHOT,
    TYPE_KNIFE,
    TYPE_AWP,
    TYPE_SHOTGUN,
    TYPE_LONGSHOT,
    TYPE_MIDAIR
}

enum _:MissionData {
    MISSION_NAME[32],
    MISSION_DESC[64],
    MISSION_GOAL,
    MISSION_TYPE,
    MISSION_REWARD_XP,
    MISSION_REWARD_CASH
}

// --- Missions Database ---
new const g_Missions[MAX_MISSIONS][MissionData] = {
    { "Warm Up",            "Get 20 Headshots",                     20,     TYPE_HEADSHOT,  1000,   2000 },
    { "Bird Hunter",        "Kill 10 players mid-air",              10,     TYPE_MIDAIR,    2500,   5000 },
    { "Sniper Entry",       "Get 15 Kills with AWP",                15,     TYPE_AWP,       3000,   6000 },
    { "Close Quarters",     "Get 15 Kills with XM1014",             15,     TYPE_SHOTGUN,   3500,   7000 },
    { "Long Distance",      "5 Kills from 2000+ units",             5,      TYPE_LONGSHOT,  5000,   10000 },
    { "Pro Assassin",       "Get 5 Knife kills",                    5,      TYPE_KNIFE,     6000,   12000 },
    { "Airborne Sniper",    "10 mid-air AWP kills",                 10,     TYPE_MIDAIR,    8000,   15000 },
    { "Point Blank",        "30 Shotgun kills",                     30,     TYPE_SHOTGUN,   9000,   18000 },
    { "Eagle Eye",          "20 Longshots (2500 units)",            20,     TYPE_LONGSHOT,  12000,  25000 },
    { "The Butcher",        "Get 15 Knife kills",                   15,     TYPE_KNIFE,     15000,  30000 },
    { "One Shot One Kill",  "50 Headshots with AWP",                50,     TYPE_HEADSHOT,  20000,  40000 },
    { "Flying Scout",       "20 mid-air kills (Self)",              20,     TYPE_MIDAIR,    25000,  50000 },
    { "Extreme Distance",   "15 Kills from 3500+ units",            15,     TYPE_LONGSHOT,  30000,  60000 },
    { "Shotgun Mastery",    "100 Shotgun kills",                    100,    TYPE_SHOTGUN,   35000,  70000 },
    { "Elite Assassin",     "Get 25 Knife kills",                   25,     TYPE_KNIFE,     4000,   80000 },
    { "AWP God",            "Get 200 Kills with AWP",               200,    TYPE_AWP,       50000,  100000 },
    { "Impossible Shot",    "10 Headshots from 3000+ units",        10,     TYPE_LONGSHOT,  60000,  120000 },
    { "Air Domination",     "50 kills on surfing players",          50,     TYPE_MIDAIR,    70000,  150000 },
    { "Serial Killer",      "Get 500 Total Kills",                  500,    TYPE_KILLS,     80000,  200000 },
    { "Master Sniper",      "100 Headshots with AWP",               100,    TYPE_HEADSHOT,  100000, 250000 },
    { "Silent Death",       "Get 50 Knife kills",                   50,     TYPE_KNIFE,     120000, 300000 },
    { "Across the Map",     "30 Kills from 4000+ units",            30,     TYPE_LONGSHOT,  150000, 400000 },
    { "Shotgun Legend",     "250 Kills with XM1014",                250,    TYPE_SHOTGUN,   200000, 500000 },
    { "Gravity Defier",     "Get 100 Mid-air kills",                100,    TYPE_MIDAIR,    250000, 600000 },
    { "Headshot King",      "Get 500 Headshots total",              500,    TYPE_HEADSHOT,  300000, 700000 },
    { "AWP Monster",        "Get 500 Kills with AWP",               500,    TYPE_AWP,       400000, 800000 },
    { "Knife God",          "Get 150 Knife kills",                  150,    TYPE_KNIFE,     500000, 1000000 },
    { "The Finisher",       "Get 1000 Total Kills",                 1000,   TYPE_KILLS,     700000, 1500000 },
    { "Untouchable",        "250 Headshots from 3500+ units",       250,    TYPE_LONGSHOT,  1000000,2000000 },
    { "Surf Overlord",      "Complete all 30 Missions!",            2500,   TYPE_KILLS,     1000000,5000000 }
};

new g_iCurrentMission[MAX_PLAYERS + 1];
new g_iMissionProgress[MAX_PLAYERS + 1];
new g_iPlayerCrates[MAX_PLAYERS + 1];
new bool:g_bOpening[MAX_PLAYERS + 1];

new g_vault;
new g_HudSync;

// ------------------------------------------------------------------
//  Plugin Init & Precache
// ------------------------------------------------------------------

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    register_clcmd("say /mission",  "CmdMainMenu");
    register_clcmd("say /missions", "CmdMainMenu");
    register_clcmd("say /ach",      "CmdMainMenu");
    
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1);
    
    g_vault = nvault_open(VAULT_NAME);
    g_HudSync = CreateHudSyncObj();
    
    set_task(1.0, "UpdateMissionHUD", .flags = "b");
}

public plugin_precache() {
    // No models to precache here, but kept for future use
}

public client_putinserver(id) {
    if(!is_user_bot(id)) {
        load_data(id);
    }
}

public client_disconnected(id) {
    if(!is_user_bot(id)) {
        save_data(id);
    }
}

// ------------------------------------------------------------------
//  Menus
// ------------------------------------------------------------------

public CmdMainMenu(id) {
    static szTitle[128];
    new iCur = g_iCurrentMission[id];
    
    formatex(szTitle, charsmax(szTitle), "\y--- [ MISSION SYSTEM ] ---^n\wLevel: \r%d \w/ \y%d^n\wCrates: \r%d Ready^n", 
        (iCur >= MAX_MISSIONS) ? MAX_MISSIONS : iCur + 1, MAX_MISSIONS, g_iPlayerCrates[id]);
    
    new menu = menu_create(szTitle, "HandleMainMenu");
    
    menu_additem(menu, "\wCurrent Objective", "0");
    menu_additem(menu, "\yAll Missions List", "1");
    menu_additem(menu, "\rOpen My Crates \d(Unbox Reward)", "2");
    menu_additem(menu, "\wLeaderboard \d(Top 10)", "3");
    
    menu_display(id, menu, 0);
    return PLUGIN_HANDLED;
}

public HandleMainMenu(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        return PLUGIN_HANDLED;
    }

    switch(item) {
        case 0: ShowCurrentMission(id);
        case 1: ShowMissionList(id);
        case 2: CmdOpenCrate(id);
        case 3: ShowLeaderboard(id);
    }
    
    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

public ShowCurrentMission(id) {
    new iCur = g_iCurrentMission[id];
    if (iCur >= MAX_MISSIONS) {
        client_print_color(id, print_team_default, "%s All missions completed!", CHAT_PREFIX);
        return;
    }

    static szInfo[512];
    formatex(szInfo, charsmax(szInfo), "\yMission %d: \w%s^n\d%s^n^n\wProgress: \r%d \y/ \w%d^n^n\rRewards: \y%d XP / $%d", 
        iCur + 1, g_Missions[iCur][MISSION_NAME], g_Missions[iCur][MISSION_DESC], 
        g_iMissionProgress[id], g_Missions[iCur][MISSION_GOAL],
        g_Missions[iCur][MISSION_REWARD_XP], g_Missions[iCur][MISSION_REWARD_CASH]);
        
    new menu = menu_create(szIn, "HandleBackToMenu");
    menu_additem(menu, "\yBack", "0");
    menu_display(id, menu, 0);
}

public ShowMissionList(id) {
    new menu = menu_create("\y--- [ MISSION LIST ] ---", "HandleBackToMenu");
    static szItem[64], szIdx[5];
    
    for (new i = 0; i < MAX_MISSIONS; i++) {
        if (i < g_iCurrentMission[id])
            formatex(szItem, charsmax(szItem), "\d[Done] %s", g_Missions[i][MISSION_NAME]);
        else if (i == g_iCurrentMission[id])
            formatex(szItem, charsmax(szItem), "\w[Current] \y%s", g_Missions[i][MISSION_NAME]);
        else
            formatex(szItem, charsmax(szItem), "\d[Locked] Mission %d", i + 1);
            
        num_to_str(i, szIdx, charsmax(szIdx));
        menu_additem(menu, szItem, szIdx);
    }
    menu_display(id, menu, 0);
}

public HandleBackToMenu(id, menu, item) {
    menu_destroy(menu);
    CmdMainMenu(id);
    return PLUGIN_HANDLED;
}

// ------------------------------------------------------------------
//  Crate System Logic
// ------------------------------------------------------------------

public CmdOpenCrate(id) {
    if (g_iPlayerCrates[id] <= 0) {
        client_print_color(id, print_team_default, "%s No crates available! Finish missions to earn them.", CHAT_PREFIX);
        return CmdMainMenu(id);
    }
    
    if (g_bOpening[id]) {
        client_print_color(id, print_team_default, "%s You are already opening a crate!", CHAT_PREFIX);
        return PLUGIN_HANDLED;
    }

    g_bOpening[id] = true;
    g_iPlayerCrates[id]--;
    
    set_task(1.0, "CrateAnimationTask", id + 500, .parameter = 5);
    return PLUGIN_HANDLED;
}

public CrateAnimationTask(id_task, count) {
    new id = id_task - 500;
    if (!is_user_connected(id)) return;

    if (count > 0) {
        static szAnim[] = { "|", "/", "-", "\" };
        set_hudmessage(255, 200, 0, -1.0, 0.4, 0, 0.0, 1.1, 0.0, 0.0, -1);
        ShowSyncHudMsg(id, g_HudSync, "--- [ UNBOXING ] ---^n      [%s] %d [%s]      ^nRolling for reward...", szAnim[count % 4], count, szAnim[count % 4]);
        
        set_task(1.0, "CrateAnimationTask", id_task, .parameter = count - 1);
    } else {
        GiveRandomReward(id);
        g_bOpening[id] = false;
    }
}

public GiveRandomReward(id) {
    new iRandom = random_num(1, 100);
    static szReward[64];

    if (iRandom <= 10) { 
        set_pev(id, pev_takedamage, 0.0); 
        formatex(szReward, charsmax(szReward), "GODMODE (5 Sec)");
        set_task(5.0, "RemoveGodmode", id);
    } 
    else if (iRandom <= 30) {
        set_pev(id, pev_gravity, 0.5); 
        formatex(szReward, charsmax(szReward), "LOW GRAVITY (Round)");
    } 
    else if (iRandom <= 60) {
        formatex(szReward, charsmax(szReward), "$10,000 BONUS CASH");
    } 
    else {
        formatex(szReward, charsmax(szReward), "2,000 BONUS XP");
    }

    set_hudmessage(0, 255, 0, -1.0, 0.4, 1, 6.0, 5.0);
    ShowSyncHudMsg(id, g_HudSync, "--- [ UNBOXED ] ---^n^nWINNER: %s!", szReward);
    client_print_color(0, id, "%s ^3%n ^1opened a crate and won ^4%s^1!", CHAT_PREFIX, id, szReward);
}

public RemoveGodmode(id) {
    if (is_user_connected(id)) {
        set_pev(id, pev_takedamage, 2.0);
    }
}

// ------------------------------------------------------------------
//  Mission Completion Logic
// ------------------------------------------------------------------

public fw_PlayerKilled_Post(victim, attacker) {
    if (!is_user_connected(attacker) || victim == attacker) return;
    
    new iCur = g_iCurrentMission[attacker];
    if (iCur >= MAX_MISSIONS) return;
    
    new bool:bIncr = false;
    new iWeapon = get_user_weapon(attacker);
    
    switch(g_Missions[iCur][MISSION_TYPE]) {
        case TYPE_KILLS:    bIncr = true;
        case TYPE_HEADSHOT: if (get_pdata_int(victim, 75) & (1<<8)) bIncr = true;
        case TYPE_KNIFE:    if (iWeapon == CSW_KNIFE) bIncr = true;
        case TYPE_AWP:      if (iWeapon == CSW_AWP) bIncr = true;
        case TYPE_SHOTGUN:  if (iWeapon == CSW_XM1014 || iWeapon == CSW_M3) bIncr = true;
        case TYPE_LONGSHOT: {
            static Float:o1[3], Float:o2[3]; 
            pev(attacker, pev_origin, o1); pev(victim, pev_origin, o2);
            if (get_distance_f(o1, o2) >= 2000.0) bIncr = true;
        }
        case TYPE_MIDAIR:   if (!(pev(victim, pev_flags) & FL_ONGROUND)) bIncr = true;
    }

    if (bIncr) {
        g_iMissionProgress[attacker]++;
        
        if (g_iMissionProgress[attacker] >= g_Missions[iCur][MISSION_GOAL]) {
            client_print_color(0, print_team_default, "%s Player ^3%n ^1completed Mission ^4'%s'^1! +1 Crate!", CHAT_PREFIX, attacker, g_Missions[iCur][MISSION_NAME]);
            
            g_iCurrentMission[attacker]++;
            g_iMissionProgress[attacker] = 0;
            g_iPlayerCrates[attacker]++;
            
            save_data(attacker);
        }
    }
}

// ------------------------------------------------------------------
//  HUD & Leaderboard
// ------------------------------------------------------------------

public UpdateMissionHUD() {
    static szBuf[128], id;
    for (id = 1; id <= MaxClients; id++) {
        if (!is_user_alive(id) || g_iCurrentMission[id] >= MAX_MISSIONS) continue;
        
        new iC = g_iCurrentMission[id];
        formatex(szBuf, charsmax(szBuf), "[ Mission: %s ]^nProgress: %d / %d", 
            g_Missions[iC][MISSION_NAME], g_iMissionProgress[id], g_Missions[iC][MISSION_GOAL]);
            
        set_hudmessage(255, 255, 255, 0.02, 0.2, 0, 0.0, 1.1, 0.0, 0.0, -1);
        ShowSyncHudMsg(id, g_HudSync, "%s", szBuf);
    }
}

public ShowLeaderboard(id) {
    new iVaultUtil = nvault_util_open(VAULT_NAME);
    if (iVaultUtil == INVALID_HANDLE) return;

    static szMotd[2048];
    new iLen = formatex(szMotd, charsmax(szMotd), "<body bgcolor=#000000 style='color:white;font-family:Tahoma;padding:20px;'><h2 style='color:#ffcc00;text-align:center;'>--- TOP 10 MISSION MASTERS ---</h2><table width=100%% border=0 style='text-align:left;border-collapse:collapse;'><tr style='background:#333;color:#ff9900;'><th>#</th><th>Player (AuthID)</th><th>Level</th><th>Status</th></tr>");
    
    new szK[32], szV[32], iT, iPos = 0;
    new iCount = (nvault_util_count(iVaultUtil) > 10) ? 10 : nvault_util_count(iVaultUtil);
    
    for (new i = 0; i < iCount; i++) {
        iPos = nvault_util_read(iVaultUtil, iPos, szK, charsmax(szK), szV, charsmax(szV), iT);
        
        static szM[5], szP[12], szC[5];
        parse(szV, szM, charsmax(szM), szP, charsmax(szP), szC, charsmax(szC));
        
        new iLvl = str_to_num(szM);
        iLen += formatex(szMotd[iLen], charsmax(szMotd) - iLen, "<tr style='border-bottom:1px solid #222;'><td>%d</td><td>%s</td><td>%d</td><td>%d%% Done</td></tr>", i + 1, szK, iLvl + 1, (iLvl * 100 / MAX_MISSIONS));
    }
    
    iLen += formatex(szMotd[iLen], charsmax(szMotd) - iLen, "</table></body>");
    show_motd(id, szMotd, "Leaderboard");
    
    nvault_util_close(iVaultUtil);
}

// ------------------------------------------------------------------
//  Data Persistence
// ------------------------------------------------------------------

save_data(id) {
    static auth[32], data[64];
    get_user_authid(id, auth, charsmax(auth));
    
    if (contain(auth, "ID_LAN") != -1) {
        get_user_ip(id, auth, charsmax(auth), 1);
    }
    
    formatex(data, charsmax(data), "%d %d %d", g_iCurrentMission[id], g_iMissionProgress[id], g_iPlayerCrates[id]);
    nvault_set(g_vault, auth, data);
}

load_data(id) {
    static auth[32], data[64];
    get_user_authid(id, auth, charsmax(auth));
    
    if (contain(auth, "ID_LAN") != -1) {
        get_user_ip(id, auth, charsmax(auth), 1);
    }
    
    if (nvault_get(g_vault, auth, data, charsmax(data))) {
        static m[5], p[12], c[5];
        parse(data, m, charsmax(m), p, charsmax(p), c, charsmax(c));
        
        g_iCurrentMission[id] = str_to_num(m);
        g_iMissionProgress[id] = str_to_num(p);
        g_iPlayerCrates[id] = str_to_num(c);
    }
}

public plugin_end() {
    if (g_vault != INVALID_HANDLE) {
        nvault_close(g_vault);
    }
}
