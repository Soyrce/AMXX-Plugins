#include <amxmodx>

new const PREFIX[] = "^4[TagServer]^1";

// Flags
#define FLAG_A (1<<0)
#define FLAG_B (1<<1)
#define FLAG_C (1<<2)
#define FLAG_D (1<<3)
#define FLAG_E (1<<4)
#define FLAG_K (1<<10)

enum _:DATA_PREM {
	auth[50],
	password[50],
	accessflags,
	flags
};
new g_aPremium[DATA_PREM];
new Array:g_aDataPremiums;
new g_iUserFlags[MAX_PLAYERS + 1];
new g_iMaxPlayers;
new amx_password_field_string[32];

public plugin_init() {
	register_plugin("HitAndRun: Premium Core", "1.0", "CheezPuff");
	get_cvar_string("amx_password_field", amx_password_field_string, charsmax(amx_password_field_string));
	register_clcmd("say /premiums", "Command_ShowPrem");
	register_clcmd("say /premium", "Command_ShowPrem");
	g_iMaxPlayers = get_maxplayers();
	
	register_concmd("amx_reloadvips", "reload_vips", ADMIN_CFG, "<Edit soon>")
	register_concmd("amx_reloadvip", "reload_vips", ADMIN_CFG, "<Edit soon>")
}

public Command_ShowPrem(id) {
	new szText[256];
	for(new i = 1; i <= g_iMaxPlayers; i++) {
		if(!is_user_connected(i))
			continue;
		
		if(!get_user_premium(i))
			continue;
		
		formatex(szText, charsmax(szText), "%s%n, ", szText, i);
	}
	
	if(!szText[0])
		format(szText, charsmax(szText), "None premium online");
	else 
		szText[strlen(szText)-2] = '^0';
	
	client_print_color(id, id, "%s - Premium Online: ^3%s", PREFIX, szText);
	return PLUGIN_HANDLED;
}

public client_putinserver(id) {
	set_flags(id);
}

public plugin_cfg() {
	reload_vips();
}

public plugin_natives() {
	register_native("get_user_premium", "get_user_premium", true);
}

public get_user_premium(id)
	return 1;
	
public set_flags(id) {
	static szAuthId[31], szIp[31], szName[32], szPassword[30];
	get_user_authid(id, szAuthId, charsmax(szAuthId));
	get_user_ip(id, szIp, charsmax(szIp), 1);
	get_user_name(id, szName, charsmax(szName));
	get_user_info(id, amx_password_field_string, szPassword, charsmax(szPassword));
	
	g_iUserFlags[id] = 0
	for(new i; i < ArraySize(g_aDataPremiums); i++) {
		ArrayGetArray(g_aDataPremiums, i, g_aPremium);
		
		if(g_aPremium[flags] & FLAG_D) 
		{
			if(equal(szIp, g_aPremium[auth])) 
			{
				if(~g_aPremium[flags] & FLAG_E)
				{
					if(equal(szPassword, g_aPremium[password]))
						g_iUserFlags[id] = g_aPremium[accessflags];
					else if(g_aPremium[flags] & FLAG_A) {
						server_cmd("kick #%d ^"Ivalid password!^"", get_user_userid(id));
						break;
					}
				}
				else 
					g_iUserFlags[id] = g_aPremium[accessflags];
				
				log_amx("%s become Premium. (SteamID: ^"%s^") (IP: ^"%s^") (Flags: ^"%s^")", szName, szAuthId, szIp, get_flags_string(g_aPremium[accessflags]));
				break;
			}
		}
		else if(g_aPremium[flags] & FLAG_C) 
		{
			if(equal(szAuthId, g_aPremium[auth])) 
			{
				if(~g_aPremium[flags] & FLAG_E)
				{
					if(equal(szPassword, g_aPremium[password]))
						g_iUserFlags[id] = g_aPremium[accessflags];
					else if(g_aPremium[flags] & FLAG_A) {
						server_cmd("kick #%d ^"Ivalid password!^"", get_user_userid(id));
						break;
					}
				}
				else
					g_iUserFlags[id] = g_aPremium[accessflags];
				
				log_amx("%s become Premium. (SteamID: ^"%s^") (IP: ^"%s^") (Flags: ^"%s^")", szName, szAuthId, szIp, get_flags_string(g_aPremium[accessflags]));
				break;
			}
		}
		else 
		{
			if(g_aPremium[flags] & FLAG_K) {
				if((g_aPremium[flags] & FLAG_B && contain(szName, g_aPremium[auth]) != -1) || equal(szName, g_aPremium[auth])) 
				{
					if(~g_aPremium[flags] & FLAG_E)
					{
						if(equal(szPassword, g_aPremium[password]))
							g_iUserFlags[id] = g_aPremium[accessflags];
						else if(g_aPremium[flags] & FLAG_A) 
						{
							server_cmd("kick #%d ^"Ivalid password!^"", get_user_userid(id));
							break;
						}
					}
					else 
						g_iUserFlags[id] = g_aPremium[accessflags];
					
					log_amx("%s become Premium. (SteamID: ^"%s^") (IP: ^"%s^") (Flags: ^"%s^")", szName, szAuthId, szIp, get_flags_string(g_aPremium[accessflags]));
					break;
				}
			}
			else 
			{
				if((g_aPremium[flags] & FLAG_B && containi(szName, g_aPremium[auth]) != -1) || equali(szName, g_aPremium[auth])) 
				{
					if(~g_aPremium[flags] & FLAG_E)
					{
						if(equal(szPassword, g_aPremium[password]))
							g_iUserFlags[id] = g_aPremium[accessflags];
						else if(g_aPremium[flags] & FLAG_A) {
							server_cmd("kick #%d ^"Ivalid password!^"", get_user_userid(id));
							break;
						}
					}
					else 
						g_iUserFlags[id] = g_aPremium[accessflags];
					
					log_amx("%s become Premium. (SteamID: ^"%s^") (IP: ^"%s^") (Flags: ^"%s^")", szName, szAuthId, szIp, get_flags_string(g_aPremium[accessflags]));
					break;
				}
			}
		}
	}
	return 1;
}

public reload_vips() {
	new szBuffer[256], szArg[2][8], iFile = fopen("addons/amxmodx/configs/premium.ini", "a+");
	if(!iFile) 
		return set_fail_state("File ^"addons/amxmodx/configs/premium.ini^" not found");
	
	if(g_aDataPremiums) 
		ArrayDestroy(g_aDataPremiums);
	g_aDataPremiums = ArrayCreate(DATA_PREM);
	
	while(!feof(iFile)) {
		fgets(iFile, szBuffer, charsmax(szBuffer));
		trim(szBuffer);
		if(!szBuffer[0] || szBuffer[0] == ';')
			continue;
		
		if(parse(szBuffer,
			g_aPremium[auth], charsmax(g_aPremium[auth]),
			g_aPremium[password], charsmax(g_aPremium[password]),
			szArg[0], charsmax(szArg[]),
			szArg[1], charsmax(szArg[])
		))
			continue;
			
		g_aPremium[accessflags] = read_flags(szArg[0]);
		g_aPremium[flags] = read_flags(szArg[1]);
	}
	return 1;
}

stock get_flags_string(iFlags) {
	new szBuffer[16];
	get_flags(iFlags, szBuffer, charsmax(szBuffer));
	return szBuffer;
}
