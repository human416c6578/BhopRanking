enum eSettings
{
	SQL_HOST[32],
	SQL_USER[32],
	SQL_PASSWORD[32],
	SQL_DATABASE[32],
	MEDAL_BRONZE,
	MEDAL_SILVER,
	MEDAL_GOLD
};

enum eData
{
	iBronze = 0,
	iSilver,
	iGold,
	iScore,
	iRank,
	iId
};

enum eRank
{
	szRankName[32],
	iRankScore
};

new g_eSettings[eSettings];

new g_aData[MAX_PLAYERS][eData];

new Array:g_aRanks;

new Handle:g_iSqlTuple;