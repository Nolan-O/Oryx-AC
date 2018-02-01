/*  Oryx AC: collects and analyzes statistics to find some cheaters in CS:S bhop
 *  Copyright (C) 2018  Nolan O.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#include <smlib/entities>
#include <smlib/clients>
#include <oryx>
#if defined bTimes
#include <bTimes-timer>
#endif

public Plugin:myinfo = 
{
    name = "ORYX scroll module",
    author = "Rusty",
    description = "Detects jump scripts",
    version = "1.0",
    url = ""
}

#define DESC1 "Script on scroll"
#define DESC2 "Hyperscroll"

char logpath[PLATFORM_MAX_PATH];

int g_ticks[MAXPLAYERS];
int g_statsIdx[MAXPLAYERS];
int g_totalGndJumps[MAXPLAYERS];
int g_gndStats[MAXPLAYERS][30];
int g_pendGndTicks[MAXPLAYERS];
float g_avgGndStats[MAXPLAYERS];
int g_jumpsPreGnd[MAXPLAYERS];
float g_avgJumpsPreGnd[MAXPLAYERS];
int g_trigCoolDown[MAXPLAYERS];

#if defined notimer
#else
bool g_autoEnabled[MAXPLAYERS];
#endif

public OnPluginStart()
{
    RegConsoleCmd("scroll_stats", Command_PrintScrollStats);
    
    #if defined bTimes
    for(int i=0;i<MaxClients;i++)
    {
        new sbuf[StyleConfig];
        Style_GetConfig(GetClientStyle(i), sbuf);
        g_autoEnabled[i] = sbuf[Auto];
    }
    #endif
    
    BuildPath(Path_SM, logpath, sizeof(logpath), "logs/oryx-scroll-stats.log"); 
}

public bool OnClientConnect(int client)
{
    g_pendGndTicks[client] = 0;
    g_ticks[client] = 0;
    g_statsIdx[client] = 0;
    g_totalGndJumps[client] = 0;
    for(int i=0; i<30; i++)
        g_gndStats[client][i] = 0;
    
    g_avgGndStats[client] = 0.0;
    g_jumpsPreGnd[client] = 0;
    g_avgJumpsPreGnd[client] = 0.0;
    
    #if defined bTimes
    new buf[StyleConfig];
    Style_GetConfig(GetClientStyle(client), buf);
    g_autoEnabled[client] = buf[Auto];
    #endif
    return true;
}

#if defined bTimes
public OnStyleChanged(client, OldStyle[StyleConfig], NewStyle[StyleConfig], Type)
{
    new buf[StyleConfig];
    Style_GetConfig(GetClientStyle(client), buf);
    g_autoEnabled[client] = buf[Auto];
}
#endif

public Action Command_PrintScrollStats(int client, int args)
{
    if(args < 1)
        return Plugin_Handled;

    decl String:arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    int target = Client_FindByName(arg1);
    if(target == -1)
    {
        PrintToChat(client, "Could not find that player");
        return Plugin_Handled;
    }
    PrintToConsole(client, FormatScrollStats(target));
    return Plugin_Handled;
}

char[] FormatScrollStats(int target)
{
    decl String:id[32], String:name[64];
    GetClientName(target, name, sizeof(name));
    if(!GetClientAuthId(target, AuthId_Steam2, id, sizeof(id)))
        id = "ERR_GETTING_ID";
    
    decl String:statStr[150];
    Format(statStr, sizeof(statStr), "\n\nSCROLL STATS FOR:\n%s ( %s )\nAvg ground ticks: %.3f, Scrolls/Jump: %.2f\n%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
        name,
        id,
        g_avgGndStats[target],
        g_avgJumpsPreGnd[target],
        g_gndStats[target][0],
        g_gndStats[target][1],
        g_gndStats[target][2],
        g_gndStats[target][3],
        g_gndStats[target][4],
        g_gndStats[target][5],
        g_gndStats[target][6],
        g_gndStats[target][7],
        g_gndStats[target][8],
        g_gndStats[target][9],
        g_gndStats[target][10],
        g_gndStats[target][11],
        g_gndStats[target][12],
        g_gndStats[target][13],
        g_gndStats[target][14],
        g_gndStats[target][15],
        g_gndStats[target][16],
        g_gndStats[target][17],
        g_gndStats[target][18],
        g_gndStats[target][19],
        g_gndStats[target][20],
        g_gndStats[target][21],
        g_gndStats[target][22],
        g_gndStats[target][23],
        g_gndStats[target][24],
        g_gndStats[target][25],
        g_gndStats[target][26],
        g_gndStats[target][27],
        g_gndStats[target][28],
        g_gndStats[target][29]);
    return statStr;
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel_a[3])
{
    if(!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
        return Plugin_Continue;
    
    static iPrevButtons[MAXPLAYERS];
    
    #if defined notimer
    #else
    if(g_autoEnabled[client])
        return Plugin_Continue;
    #endif

    g_ticks[client]++;
    
    if(g_statsIdx[client] == 30)
        g_statsIdx[client] = 0;
    if(GetEntityFlags(client) & FL_ONGROUND)
    {
        if(!(buttons & IN_JUMP))
            g_pendGndTicks[client]++;
        else if(!(iPrevButtons[client] & IN_JUMP) && g_pendGndTicks[client] < 11)
        {
            g_trigCoolDown[client]--;
            g_gndStats[client][g_statsIdx[client]] = g_pendGndTicks[client];

            ++g_totalGndJumps[client];
            g_avgGndStats[client] = (g_avgGndStats[client] * 29 + g_gndStats[client][g_statsIdx[client]]) / 30;
            if(g_avgGndStats[client] < 0.1667 && g_totalGndJumps[client] > 25 && g_trigCoolDown[client] <= 0)
            {
                g_trigCoolDown[client] = 35;
                OryxTrigger(client, TRIGGER_HIGH, DESC1);
                decl String:buf[150];
                buf = FormatScrollStats(client);
                PrintToAdminsConsole(buf);
                LogToFileEx(logpath, buf);
            }

            g_avgJumpsPreGnd[client] = (g_avgJumpsPreGnd[client] * 29 + g_jumpsPreGnd[client]) / 30;
            g_jumpsPreGnd[client] = 0;
            if(g_avgJumpsPreGnd[client] > 20 && g_totalGndJumps[client] > 25 && g_trigCoolDown[client] <= 0)
            {
                g_trigCoolDown[client] = 35;
                OryxTrigger(client, TRIGGER_HIGH_NOKICK, DESC2);
                decl String:buf[150];
                buf = FormatScrollStats(client);
                PrintToAdminsConsole(buf);
                LogToFileEx(logpath, buf);
            }
            g_statsIdx[client]++;
        }
    }
    else if(buttons & IN_JUMP && !(iPrevButtons[client] & IN_JUMP) && !(GetEntityMoveType(client) & MOVETYPE_NOCLIP || GetEntityMoveType(client) & MOVETYPE_LADDER || GetEntityFlags(client) & FL_INWATER))
    {
        g_jumpsPreGnd[client]++;
    }
    else
    {
        g_pendGndTicks[client] = 0;
    }
    
    iPrevButtons[client] = buttons;
    
    return Plugin_Continue;
}






