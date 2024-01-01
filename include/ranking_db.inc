public DB_Init()
{
	g_iSqlTuple = SQL_MakeDbTuple(g_eSettings[SQL_HOST], g_eSettings[SQL_USER], g_eSettings[SQL_PASSWORD], g_eSettings[SQL_DATABASE]);

	SQL_SetAffinity("mysql");

	new iErrorCode, szSqlError[128], Handle:iSqlConnection = SQL_Connect(g_iSqlTuple, iErrorCode, szSqlError, charsmax(szSqlError));

	if(iSqlConnection == Empty_Handle)
	{
		log_amx(szSqlError);
		set_fail_state("Couldn't connect to mysql!");
	}
	else
	{
		SQL_FreeHandle(iSqlConnection);
	}
}

public DB_LoadPlayerId(id)
{
	new szQuery[256];
	new data[1];
	data[0] = id;
	new szAuthId[32];
	get_user_authid(id, szAuthId, charsmax(szAuthId));

	formatex(szQuery, charsmax(szQuery), "SELECT id FROM Users WHERE AuthId='%s';", szAuthId);

	SQL_ThreadQuery(g_iSqlTuple, "QueryLoadIdHandler", szQuery, data, sizeof(data));
}

public QueryLoadIdHandler(iFailState, Handle:iQuery, szError[], iErrorCode, iData[], iSize){
	new id = iData[0];
	check_and_log_query_error(iFailState, szError, iErrorCode)
	if(SQL_NumResults(iQuery))
	{
		g_aData[id][iId] = SQL_ReadResult(iQuery, 0);
		DB_LoadPlayer(id);
		DB_UpdatePlayerMedals(id);
	}
}

public DB_InsertPlayer(id)
{
	new szQuery[256];

	formatex(szQuery, charsmax(szQuery), "\
	INSERT INTO Ranking (UserId, Score, Bronze, Silver, Gold) \
	VALUES (%d, %d, %d, %d, %d);",
		g_aData[id][iId], g_aData[id][iScore], g_aData[id][iBronze], g_aData[id][iSilver], g_aData[id][iGold]);

	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery)
}

public DB_LoadPlayer(id)
{
	new szQuery[256];
	new data[1];
	data[0] = id;

	formatex(szQuery, charsmax(szQuery), "\
	SELECT Rank, Score, Bronze, Silver, Gold \
		FROM ( \
		    SELECT UserId, Score, Bronze, Silver, Gold, RANK() OVER (ORDER BY Score DESC) AS Rank \
		    FROM Ranking \
		) AS RankedUsers \
		WHERE UserId = %d;", g_aData[id][iId]);

	SQL_ThreadQuery(g_iSqlTuple, "QueryLoadPlayerHandler", szQuery, data, sizeof(data));
}

public QueryLoadPlayerHandler(iFailState, Handle:iQuery, szError[], iErrorCode, iData[], iSize){
	new id = iData[0];
	check_and_log_query_error(iFailState, szError, iErrorCode)
	if(SQL_NumResults(iQuery))
	{
		g_aData[id][iRank] = SQL_ReadResult(iQuery, 0);
		g_aData[id][iScore] = SQL_ReadResult(iQuery, 1);
		g_aData[id][iBronze] = SQL_ReadResult(iQuery, 2);
		g_aData[id][iSilver] = SQL_ReadResult(iQuery, 3);
		g_aData[id][iGold] = SQL_ReadResult(iQuery, 4);
	}
	else
	{
		DB_InsertPlayer(id);
	}
}

public DB_UpdatePlayer(id)
{
	new szQuery[256];

	formatex(szQuery, charsmax(szQuery), "\
	UPDATE Ranking \
	SET Score = %d, Bronze = %d, Silver = %d, Gold = %d \
	WHERE UserId = %d;",
		g_aData[id][iScore], g_aData[id][iBronze], g_aData[id][iSilver], g_aData[id][iGold], g_aData[id][iId]);

	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery)
}

public DB_UpdatePlayerMedals(id)
{
	new szQuery[256];
	new iMedals[3], szMapName[32];
	get_user_map_medals(id, iMedals, 3);
	if(iMedals[0] == 0) return;

	get_mapname(szMapName, charsmax(szMapName));

	formatex(szQuery, charsmax(szQuery), "\
	INSERT INTO Player_Medals (UserId, MapId, Bronze, Silver, Gold) \
		VALUES (%d, (SELECT id FROM Maps m WHERE m.Name = '%s'), %d, %d, %d) \
  		ON DUPLICATE KEY UPDATE Bronze = %d, Silver = %d, Gold = %d;",
		g_aData[id][iId], szMapName, iMedals[0], iMedals[1], iMedals[2], iMedals[0], iMedals[1], iMedals[2]);


	SQL_ThreadQuery(g_iSqlTuple, "QueryHandler", szQuery)
}

public QueryHandler(iFailState, Handle:iQuery, szError[], iErrorCode)
{
	check_and_log_query_error(iFailState, szError, iErrorCode)
}

check_and_log_query_error(iFailState, const szError[], iErrorCode)
{
	switch(iFailState)
	{
		case TQUERY_CONNECT_FAILED: log_amx("[SQL Error] Connection failed (%i): %s", iErrorCode, szError)
		case TQUERY_QUERY_FAILED:   log_amx("[SQL Error] Query failed (%i): %s", iErrorCode, szError)
	}
}