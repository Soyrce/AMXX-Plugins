#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <nvault>
#include <engine>

#define MAX_LEVELS 10
#define MAX_PLAYERS 32

enum _:KnifeAttributes {
    KNIFE_MODEL[64],
    HP_BONUS,
    DAMAGE_BONUS,
    COST
}

new const KnifeData[MAX_LEVELS][KnifeAttributes] = {
    { "models/v_knife_1.mdl", 10, 5, 100 },
    { "models/v_knife_2.mdl", 20, 10, 200 },
    { "models/v_knife_3.mdl", 30, 15, 300 },
    { "models/v_knife_4.mdl", 40, 20, 400 },
    { "models/v_knife_5.mdl", 50, 25, 500 },
    { "models/v_knife_6.mdl", 60, 30, 600 },
    { "models/v_knife_7.mdl", 70, 35, 700 },
    { "models/v_knife_8.mdl", 80, 40, 800 },
    { "models/v_knife_9.mdl", 90, 45, 900 },
    { "models/v_knife_10.mdl", 100, 50, 1000 }
};

new const g_XPNeeded[MAX_LEVELS] = { 0, 500, 1200, 2500, 5000, 8000, 12000, 18000, 25000, 40000 };

new g_playerLevel[MAX_PLAYERS + 1], g_playerCash[MAX_PLAYERS + 1], g_playerEXP[MAX_PLAYERS + 1], g_playerKnife[MAX_PLAYERS + 1];
new g_vault, g_HudSync;

public plugin_init() {
    register_plugin("Surf Levels Ultimate", "1.4", "CheezPuff");
    
    register_clcmd("say /shop", "CmdShowBuyMenu");
    register_clcmd("say /knife", "CmdShowBuyMenu");
    
    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1);
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
    RegisterHam(Ham_Item_Deploy, "weapon_knife", "fw_KnifeDeploy_Post", 1);

    g_vault = nvault_open("surf_levels");
    g_HudSync = CreateHudSyncObj();
}

public plugin_precache() {
    for (new i = 0; i < MAX_LEVELS; i++) precache_model(KnifeData[i][KNIFE_MODEL]);
}

public client_putinserver(id) {
    if (!is_user_bot(id) && !is_user_hltv(id)) loadPlayerData(id);
}

public client_disconnected(id) {
    if (!is_user_bot(id) && !is_user_hltv(id)) savePlayerData(id);
}

// --- Menu System ---
public CmdShowBuyMenu(id) {
    if (!is_user_alive(id)) return PLUGIN_HANDLED;

    static szTitle[64];
    formatex(szTitle, charsmax(szTitle), "\yKnife Shop^n\wYour Cash: \r$%d", g_playerCash[id]);
    new menu = menu_create(szTitle, "HandleBuyMenu");

    for (new i = 0; i < MAX_LEVELS; i++) {
        static szItem[64], szIdx[3];
        formatex(szItem, charsmax(szItem), "Knife Lvl %d \y[$%d]", i + 1, KnifeData[i][COST]);
        num_to_str(i, szIdx, charsmax(szIdx));
        menu_additem(menu, szItem, szIdx);
    }

    menu_display(id, menu, 0);
    return PLUGIN_HANDLED;
}

public HandleBuyMenu(id, menu, item) {
    if (item == MENU_EXIT) { menu_destroy(menu); return PLUGIN_HANDLED; }

    static szIdx[3], _access, callback;
    menu_item_getinfo(menu, item, _access, szIdx, charsmax(szIdx), _, _, callback);
    
    new knifeIdx = str_to_num(szIdx);
    if (g_playerCash[id] >= KnifeData[knifeIdx][COST]) {
        g_playerCash[id] -= KnifeData[knifeIdx][COST];
        g_playerKnife[id] = knifeIdx;
        
        if (get_user_weapon(id) == CSW_KNIFE) 
            set_pev(id, pev_viewmodel2, KnifeData[knifeIdx][KNIFE_MODEL]);
            
        client_print_color(id, print_team_default, "^4[Shop] ^1Purchased ^3Level %d Knife^1!", knifeIdx + 1);
    } else {
        client_print_color(id, print_team_default, "^4[Shop] ^1Not enough cash!");
    }

    menu_destroy(menu);
    return PLUGIN_HANDLED;
}

public fw_KnifeDeploy_Post(weapon_ent) {
    new id = get_ent_data_entity(weapon_ent, "CBasePlayerItem", "m_pPlayer");
    if (is_user_connected(id)) {
        set_pev(id, pev_viewmodel2, KnifeData[g_playerKnife[id]][KNIFE_MODEL]);
    }
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_bits) {
    if (!is_user_connected(attacker) || victim == attacker) return HAM_IGNORED;

    if (get_user_weapon(attacker) == CSW_KNIFE) {
        new Float:bonus = float(KnifeData[g_playerKnife[attacker]][DAMAGE_BONUS]);
        SetHamParamFloat(4, damage + bonus);
        return HAM_HANDLED;
    }
    return HAM_IGNORED;
}

public fw_PlayerSpawn_Post(id) {
    if (!is_user_alive(id)) return;
    set_pev(id, pev_health, 100.0 + float(KnifeData[g_playerKnife[id]][HP_BONUS]));
}

public fw_PlayerKilled_Post(victim, attacker, shouldgib) {
    if (!is_user_connected(attacker) || victim == attacker) return;

    g_playerCash[attacker] += 50;
    g_playerEXP[attacker] += 100;
    checkLevelUp(attacker);
}

public checkLevelUp(id) {
    while (g_playerLevel[id] < MAX_LEVELS && g_playerEXP[id] >= g_XPNeeded[g_playerLevel[id]]) {
        g_playerLevel[id]++;
        static szName[32]; get_user_name(id, szName, charsmax(szName));
        set_hudmessage(255, 255, 0, -1.0, 0.2, 0, 6.0, 5.0);
        ShowSyncHudMsg(0, g_HudSync, "CONGRATULATIONS!^n%s reached Level %d!", szName, g_playerLevel[id]);
    }
}

// --- Persistence Logic (Anti-Bot & Anti-LAN Collision) ---
savePlayerData(id) {
    static szKey[36], szData[64];
    getPlayerSaveKey(id, szKey, charsmax(szKey));
    
    formatex(szData, charsmax(szData), "%d %d %d %d", g_playerLevel[id], g_playerCash[id], g_playerEXP[id], g_playerKnife[id]);
    nvault_set(g_vault, szKey, szData);
}

loadPlayerData(id) {
    static szKey[36], szData[64];
    getPlayerSaveKey(id, szKey, charsmax(szKey));
    
    if (nvault_get(g_vault, szKey, szData, charsmax(szData))) {
        static szL[5], szC[12], szE[12], szK[5];
        parse(szData, szL, charsmax(szL), szC, charsmax(szC), szE, charsmax(szE), szK, charsmax(szK));
        g_playerLevel[id] = str_to_num(szL);
        g_playerCash[id] = str_to_num(szC);
        g_playerEXP[id] = str_to_num(szE);
        g_playerKnife[id] = str_to_num(szK);
    } else {
        g_playerLevel[id] = 1; g_playerCash[id] = 0; g_playerEXP[id] = 0; g_playerKnife[id] = 0;
    }
}

// Helper to determine the best save key
getPlayerSaveKey(id, szKey[], iLen) {
    get_user_authid(id, szKey, iLen);
    
    // If Non-Steam/LAN, use IP address instead of SteamID
    if (contain(szKey, "ID_LAN") != -1 || equal(szKey, "PENDING")) {
        get_user_ip(id, szKey, iLen, 1);
    }
}

public plugin_end() nvault_close(g_vault);
