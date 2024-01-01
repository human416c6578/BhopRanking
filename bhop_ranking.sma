#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <medals>
#include <ranking_globals>
#include <ranking_db>

#define PLUGIN_NAME "Bhop Ranking"
#define PLUGIN_AUTHOR "MrShark45"
#define PLUGIN_VERSION "1.1"

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR );

	register_clcmd("say /toprank", "ShowTopCmd");
	register_clcmd("say /rank", "ShowRankCmd");
}

public plugin_natives()
{
	register_library("ranking");

	register_native("give_user_medals", "give_user_medals_native");
	register_native("get_user_medals", "get_user_medals_native");
	
	register_native("set_user_score", "set_user_score_native");
	register_native("get_user_score", "get_user_score_native");

	register_native("get_user_rank", "get_user_rank_native");
}

public give_user_medals_native(numParams)
{
	new id = get_param(1);
	new type = get_param(2);
	new number = get_param(3);

	new score = 0;
	switch(type)
	{
		case iBronze:
		{
			score = g_eSettings[MEDAL_BRONZE];
		}
		case iSilver:
		{
			score = g_eSettings[MEDAL_SILVER];
		}
		case iGold:
		{
			score = g_eSettings[MEDAL_GOLD];
		}
	}

	g_aData[id][type] += number;
	g_aData[id][iScore] += score;

	DB_UpdatePlayer(id);
	DB_UpdatePlayerMedals(id);
}

public get_user_medals_native(numParams)
{
	new id, medals[3], medals_length;
	id = get_param(1);
	medals_length = get_param(3);

	medals[0] = g_aData[id][iBronze];
	medals[1] = g_aData[id][iSilver];
	medals[2] = g_aData[id][iGold];
	set_array(2, medals, medals_length);

}

public set_user_score_native(numParams)
{
	new id = get_param(1);
	new number = get_param(2);

	g_aData[id][iScore] = number;
}

public get_user_score_native(numParams)
{
	new id = get_param(1);

	return g_aData[id][iScore];
}

public get_user_rank_native(numParams)
{
	new id = get_param(1);

	return g_aData[id][iRank];
}


public plugin_cfg()
{
	g_aRanks = ArrayCreate(eRank);
	LOAD_SETTINGS();
	DB_Init();
}

public plugin_end()
{
	ArrayDestroy(g_aRanks);
}

public LOAD_SETTINGS()
{
	new szFilename[256]
	get_configsdir(szFilename, charsmax(szFilename))
	add(szFilename, charsmax(szFilename), "/ranking.cfg")
	new iFilePointer = fopen(szFilename, "rt");
	new szData[256], szKey[32], szValue[64];
	new bool:bLoadingRanks = false;

	if(iFilePointer)
	{
		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)

			switch(szData[0])
			{
				case EOS, '#', ';', '/': continue
			}

			if(bLoadingRanks)
			{
				continue;
			}

			strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=');
			trim(szKey); trim(szValue);

			if(equal(szKey, "SQL_HOST"))
			{
				format(g_eSettings[SQL_HOST], charsmax(g_eSettings[SQL_HOST]), szValue);
			}
			if(equal(szKey, "SQL_USER"))
			{
				format(g_eSettings[SQL_USER], charsmax(g_eSettings[SQL_USER]), szValue);
			}
			if(equal(szKey, "SQL_PASSWORD"))
			{
				format(g_eSettings[SQL_PASSWORD], charsmax(g_eSettings[SQL_PASSWORD]), szValue);
			}
			if(equal(szKey, "SQL_DATABASE"))
			{
				format(g_eSettings[SQL_DATABASE], charsmax(g_eSettings[SQL_DATABASE]), szValue);
			}
			if(equal(szKey, "MEDAL_BRONZE"))
			{
				g_eSettings[MEDAL_BRONZE] = str_to_num(szValue);
			}
			if(equal(szKey, "MEDAL_SILVER"))
			{
				g_eSettings[MEDAL_SILVER] = str_to_num(szValue);
			}
			if(equal(szKey, "MEDAL_GOLD"))
			{
				g_eSettings[MEDAL_GOLD] = str_to_num(szValue);
			}
			if(containi(szData, "[RANKS]") != -1)
			{
				bLoadingRanks = true;
				continue;
			}
			if(containi(szData, "[END_RANKS]") != -1)
			{
				bLoadingRanks = false;
				continue;
			}
			if(bLoadingRanks)
			{
				new temp_rank[eRank];
				format(temp_rank[szRankName], charsmax(temp_rank[szRankName]), szKey);
				temp_rank[iRankScore] = str_to_num(szValue);
				ArrayPushArray(g_aRanks, temp_rank);
			}

		}
	}
	fclose(iFilePointer);
}

public client_putinserver(id)
{	
	if(is_user_bot(id)) return;
	
	new temp_data[eData];
	g_aData[id] = temp_data;
	set_task(3.0, "DB_LoadPlayerId", id);
}

public ShowTopCmd(id)
{
	show_motd(id, "");
}

public ShowRankCmd(id)
{
	new medals[3];
	get_user_map_medals(id, medals, 3);
	client_print_color(id, print_team_red, "^4[MEDALS] ^1Your rank is ^4%d ^1| Score ^4[%d]", g_aData[id][iRank], g_aData[id][iScore]);
	client_print_color(id, print_team_red, "^4[MEDALS] ^1Medals: ^1Bronze ^4%d ^1| Silver ^4%d ^1Gold ^4%d"	, g_aData[id][iBronze], g_aData[id][iSilver], g_aData[id][iGold]);
	client_print_color(id, print_team_red, "^4[MEDALS] ^1Map Medals: ^1Bronze ^4%d ^1| Silver ^4%d ^1Gold ^4%d", medals[0], medals[1], medals[2]);
}