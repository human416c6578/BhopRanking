#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <timer>
#include <credits>

#define USE_RANKING 0

#if USE_RANKING
#include <ranking>
#endif

#define DEBUG 1

#define MAX_CATEGORIES 34
#define TASK_ID 4832

new bronze[3] = {205, 127, 50};
new silver[3] = {192, 192, 192};
new gold[3]   = {255, 215, 0};

enum eMedalInfo{
	iMedalCategory,
	Float:fMedalTime,
	iMedalType,
	iMedalReward
};

enum eMedalCompleted{
	bool:bMedalBronze = 0,
	bool:bMedalSilver,
	bool:bMedalGold,
}

new Array:g_aMedals;

new g_bMedalsCompleted[MAX_PLAYERS][MAX_CATEGORIES][eMedalCompleted];

new Float:g_fStartTime[MAX_PLAYERS];

new bool:g_bMedalsEnabled;

new g_szMapName[64];

new g_iVault;
new g_iHudSync;
new bool:g_bShowHud[MAX_PLAYERS];

new Trie:g_tMedalsText;

public plugin_init()
{
	register_clcmd("say /hidemedals", "HideMedalsCmd");

	register_clcmd("say /medal", "CategoriesMenu");
	register_clcmd("say /medals", "CategoriesMenu");

	g_iHudSync = CreateHudSyncObj();
}

public plugin_natives()
{
	register_library("timer_medals");

	register_native("open_medals_menu", "open_medals_menu_native");

	register_native("get_user_map_medals", "get_user_map_medals_native");

	register_native("toggle_medals", "toggle_medals_native");
	register_native("get_bool_medals", "get_bool_medals_native");
}

public open_medals_menu_native(numParams)
{
	new id = get_param(1);
	CategoriesMenu(id);
}

public get_user_map_medals_native(numParams)
{
	new id = get_param(1);
	new length = get_param(3);
	new bool:medals[3];
	for(new i=0;i<MAX_CATEGORIES;i++)
	{
		medals[0] += g_bMedalsCompleted[id][i][bMedalBronze];
		medals[1] += g_bMedalsCompleted[id][i][bMedalSilver];
		medals[2] += g_bMedalsCompleted[id][i][bMedalGold];
	}

	set_array(2, medals, length);
}

public toggle_medals_native(numParams)
{
	new id = get_param(1);
	HideMedalsCmd(id);
}

public get_bool_medals_native(numParams)
{
	new id = get_param(1);
	return g_bShowHud[id];
}


public plugin_cfg()
{
	g_aMedals = ArrayCreate(eMedalInfo);

	g_tMedalsText = TrieCreate();

	g_bMedalsEnabled = false;

	get_mapname(g_szMapName, charsmax(g_szMapName));

	LOAD_MEDALS();

	new szVaultName[64];
	format(szVaultName, charsmax(szVaultName), "%s_medals5", g_szMapName);	
	g_iVault = nvault_open(szVaultName);

	set_task(1.0, "ShowMedalsTask", TASK_ID, _, _, "b");
}

public plugin_end()
{
	nvault_close(g_iVault);

	ArrayDestroy(g_aMedals);
	TrieDestroy(g_tMedalsText);
}

public client_putinserver(id)
{
	LoadMedals(id);
	g_bShowHud[id] = true;
}

public LOAD_MEDALS()
{
	new file_name[256];

	get_configsdir(file_name, charsmax(file_name));
	add(file_name, charsmax(file_name), "/medals.ini");

	new file_pointer = fopen(file_name, "rt");

	if(!file_pointer) return;

	new data[256], key[64], time[16], category[4], medal[4], reward[16], medal_name[8];
	new temp_text[64];
	new temp_medal[eMedalInfo];
	new lastCat = -1;
	
	while(!feof(file_pointer)){
		fgets(file_pointer, data, charsmax(data))
		trim(data);

		switch(data[0])
		{
			case EOS, '#', ';', ' ', '/': continue;
		}

		strtok(data, key, charsmax(key), data, charsmax(data), ' ');
		strtok(data, category, charsmax(category), data, charsmax(data), ' ');
		strtok(data, time, charsmax(time), data, charsmax(data), ' ');
		strtok(data, medal, charsmax(medal), data, charsmax(data), ' ');
		strtok(data, reward, charsmax(reward), data, charsmax(data), ' ');
		trim(key); trim(time); trim(category); trim(medal); trim(reward);

		if(equal(key, g_szMapName)){
			temp_medal[iMedalCategory] = str_to_num(category);
			temp_medal[fMedalTime] = str_to_float(time);
			temp_medal[iMedalType] = str_to_num(medal);
			temp_medal[iMedalReward] = str_to_num(reward);

			ArrayPushArray(g_aMedals, temp_medal);

			g_bMedalsEnabled = true;
#if DEBUG
			server_print("Map %s Medal Category : %d | Type %d | Time : %f | Reward : %d", g_szMapName, temp_medal[iMedalCategory], temp_medal[iMedalType], temp_medal[fMedalTime], temp_medal[iMedalReward]);
#endif		
	
			if(lastCat != temp_medal[iMedalCategory])
			{
				lastCat = temp_medal[iMedalCategory];
				formatex(temp_text, charsmax(temp_text), "");
			}

			format_time_float(time, charsmax(time), temp_medal[fMedalTime]);
			get_medal_name(temp_medal[iMedalType], medal_name, charsmax(medal_name));
			format(temp_text, charsmax(temp_text), "%s%s - %s^n", temp_text, medal_name, time);

			TrieSetString(g_tMedalsText, category, temp_text);
		}
	}
}

public ShowMedalsTask()
{
	static players[MAX_PLAYERS], iNumPlayers, id, i;
	static catName[8], cat;
	static medals_text[64];
	get_players(players, iNumPlayers, "ceh", "CT");
	for(i=0;i<iNumPlayers;i++)
	{
		id = players[i];
		if(!is_user_alive(id) || !g_bShowHud[id])
			continue;
		
		cat = get_user_category(id, catName, charsmax(catName));

		set_hudmessage(0, 192, 0, 0.05, 0.15, 0, 0.0, 1.0, 0.0, 0.0, -1);
		num_to_str(cat, catName, charsmax(catName));
		TrieGetString(g_tMedalsText, catName, medals_text, charsmax(medals_text));
		ShowSyncHudMsg(id, g_iHudSync, medals_text);
	}
}

public timer_player_started(id)
{
	if(!g_bMedalsEnabled) return PLUGIN_CONTINUE;

	g_fStartTime[id] = get_gametime();

	return PLUGIN_CONTINUE;
}

public timer_player_finished(id)
{
	if(!g_bMedalsEnabled) return PLUGIN_CONTINUE;

	check_time(id);

	return PLUGIN_CONTINUE;
}

public HideMedalsCmd(id)
{
	g_bShowHud[id] = !g_bShowHud[id];
}

public CategoriesMenu(id)
{
	if(!g_bMedalsEnabled){
		client_print_color(id, print_team_default, "^4[MEDALS] ^1There are no medals on this map!");
		return PLUGIN_HANDLED;
	}

	new title[128];
	new temp_medal[eMedalInfo];
	new bool:catItem[MAX_CATEGORIES];
	new catName[32];
	new szData[4];
	new size = ArraySize(g_aMedals);

	format(title, charsmax(title), "\rMedals \y%s \r:", g_szMapName);
	new menu = menu_create(title, "categories_menu_handler");
	
	for(new i=0;i<size;i++){
		ArrayGetArray(g_aMedals, i, temp_medal);
		if(catItem[temp_medal[iMedalCategory]]) continue;

		get_category_name(temp_medal[iMedalCategory], catName, charsmax(catName));
		format(szData, charsmax(szData), "%d", temp_medal[iMedalCategory]);
		menu_additem(menu, catName, szData, 0);

		catItem[temp_medal[iMedalCategory]] = true;
	}

	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public categories_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return PLUGIN_CONTINUE;
	}


	new cat;
	new itemInfo[4], szItemName[12];
	new _access, item_callback;

	menu_item_getinfo( menu, item, _access, itemInfo, charsmax( itemInfo ), szItemName ,charsmax( szItemName ), item_callback );
	cat = str_to_num(itemInfo);

	MedalsMenu(id, cat);
	
	menu_destroy( menu );
	return PLUGIN_HANDLED;
}

public MedalsMenu(id, cat)
{
	new temp_medal[eMedalInfo], size, medal_name[8];
	size = ArraySize(g_aMedals);
	new text[128];
	new time[16];
	new title[128];

	new catName[32];
	get_category_name(cat, catName, charsmax(catName));

	format(title, charsmax(title), "\rMedals \y%s \w%s\r:", g_szMapName, catName);

	new menu = menu_create(title, "menu_handler");

	for(new i=0;i<size;i++){
 		ArrayGetArray(g_aMedals, i, temp_medal);
		if(temp_medal[iMedalCategory] != cat) continue;

		format_time_float(time, charsmax(time), temp_medal[fMedalTime]);
		get_medal_name(temp_medal[iMedalType], medal_name, charsmax(medal_name))
		format(text, charsmax(text), "\d%s \y%s \d| \y%d credits %s", medal_name, time, temp_medal[iMedalReward], g_bMedalsCompleted[id][cat][temp_medal[iMedalType]]?"\r(Completed)":"");
 		menu_additem(menu, text, "", 0);
	}

	menu_setprop(menu, MPROP_EXITNAME, "Back");

	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public menu_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		CategoriesMenu(id);
		return PLUGIN_CONTINUE;
	}

	menu_destroy( menu );
	return PLUGIN_HANDLED;
}


public check_time(id)
{
	new Float:fFinishTime = get_gametime() - g_fStartTime[id];

	new temp_medal[eMedalInfo], size, cat, cat_name[32];
	size = ArraySize(g_aMedals);
	cat = get_user_category(id, cat_name, charsmax(cat_name));

	for(new i=0;i<size;i++){
		ArrayGetArray(g_aMedals, i, temp_medal);

		if(temp_medal[iMedalCategory] != cat) continue;

		if(g_bMedalsCompleted[id][cat][temp_medal[iMedalType]]) continue;

		if(fFinishTime <= temp_medal[fMedalTime]){
			
			reward_player(id, temp_medal[iMedalType], temp_medal[iMedalReward]);

			SaveMedal(id, temp_medal[iMedalCategory], temp_medal[iMedalType]);
#if USE_RANKING
			give_user_medals(id, temp_medal[iMedalType], 1);
#endif
		}
	}
}

public reward_player(id, medal_type, reward)
{
	new name[32];
	get_user_name(id, name, charsmax(name));
	
	new colors[3];

	switch(medal_type)
	{
		case 0:
		{
			colors = bronze;
		}
		case 1:
		{
			colors = silver;
		}
		case 2:
		{
			colors = gold;
		}
	}

	new Float:y = 0.05 + (medal_type / 10.0);
	set_dhudmessage ( colors[0], colors[1], colors[2], -1.0, y, 0, 6.0, 12.0, 0.1, 0.2);
	new medal_name[8];
	get_medal_name(medal_type, medal_name, charsmax(medal_name));
	for(new i=1;i<MAX_PLAYERS;i++)
	{
		if(!g_bShowHud[id] || is_user_connected(id)) continue;
		
		show_dhudmessage(id, "%s got a %s MEDAL!", name, medal_name);
	}
	
	set_user_credits(id, get_user_credits(id) + reward);
}

public LoadMedals(id)
{
	new key[32], authid[32], str_value[1], timestamp;
	get_user_authid(id, authid, charsmax(authid));

	for(new i=0;i<MAX_CATEGORIES;i++)
	{
		for(new j=0;j<3;j++)
		{   
			g_bMedalsCompleted[id][i][j] = false;

			format(key, charsmax(key), "%s_%d%d", authid, i, j);

			if(nvault_lookup(g_iVault, key, str_value, charsmax(str_value), timestamp))
				g_bMedalsCompleted[id][i][j] = true;
		}
	}
	
}

public SaveMedal(id, category_id, medal_type)
{
	new authid[32], key[32];

	get_user_authid(id, authid, charsmax(authid));
	format(key, charsmax(key), "%s_%d%d", authid, category_id, medal_type);

	nvault_set(g_iVault, key, "1");

	g_bMedalsCompleted[id][category_id][medal_type] = true;
}

stock format_time_float(output[], len, Float:time)
{
    new minutes, seconds, centiseconds;

    minutes = floatround(time / 60.0, floatround_floor);
    seconds = floatround(time, floatround_floor) % 60;

    centiseconds = floatround((time - floatround(time, floatround_floor)) * 100.0);

    formatex(output, len, "%02d:%02d.%02d", minutes, seconds, centiseconds);
}


stock get_medal_name(id, buffer[], length)
{
	switch(id)
	{
		case 0:
			format(buffer, length, "Bronze");
		case 1:
			format(buffer, length, "Silver");
		case 2:
			format(buffer, length, "Gold");
	}
}