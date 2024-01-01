# Bhop Ranking and Medals AMX Mod X Plugin

## Overview
This AMX Mod X plugin consists of two interconnected plugins: `bhop_ranking` and `medals.sma`. These plugins work together and cannot function properly without each other. The `bhop_ranking` plugin is responsible for updating the database, displaying the rank, score and medals.

### Features
- Rank players based on their BHOP (Bunny Hop) skills.
- Award players with Bronze, Silver, and Gold medals based on their achievements.
- Integration with a database to store player rankings and medals.
- HUD display of player ranks and medals.
- Command to display the top ranking players (`/toprank`).
- Command to display a player's rank and medals (`/rank`).
- Configurable settings through a `ranking.cfg` file.
- Configurable medals for every map through a `medals.ini` file


## Usage
1. Players can use the `/toprank` command to view the top-ranked players.
2. Players can use the `/rank` command to view their own rank and medals.
3. Medals are awarded based on BHOP achievements.
4. Player rankings and medals are stored in a database.

## Plugin Configuration (`ranking.cfg`)
The `ranking.cfg` file contains settings such as SQL database connection details and medal scores.

```ini
SQL_HOST "localhost"
SQL_USER "root"
SQL_PASSWORD "password"
SQL_DATABASE "bhop_ranking"

MEDAL_BRONZE 10
MEDAL_SILVER 20
MEDAL_GOLD 30
```

## Notes
- The `medals.sma` plugin is an extension that provides additional functionality for awarding and displaying medals.
- Ensure that the required include files are available in your AMX Mod X include directory.

Feel free to contribute, report issues, or suggest improvements!