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
#include <smlib/clients>
#include <oryx>
#if defined bTimes
#include <bTimes-zones>
#endif

public Plugin:myinfo = 
{
    name = "ORYX movement config module",
    author = "Rusty",
    description = "Detects movement configs",
    version = "1.0",
    url = ""
}

#define DESC "Movement config"

g_perfStrafeCt[MAXPLAYERS];
#if defined bTimes
g_jumpsFromZone[MAXPLAYERS];
#endif

public Action Command_ConfigStreak(int client, int args)
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
    
    decl String:id[32], String:name[64];
    GetClientName(target, name, sizeof(name));
    if(!GetClientAuthId(target, AuthId_Steam2, id, sizeof(id)))
        id = "ERR_GETTING_ID";
        
    PrintToConsole(client, "\nUser %s ( %s ) is on a config streak of %d", name, id, g_perfStrafeCt[target]);
    
    return Plugin_Handled;
}

public OnPluginStart()
{
    RegAdminCmd("config_streak", Command_ConfigStreak, ADMFLAG_GENERIC);
}

public bool OnClientConnect(int client)
{
    g_perfStrafeCt[client] = 0;
    #if defined bTimes
    g_jumpsFromZone[client] = 0;
    #endif
    
    return true;
}

public Action OnPlayerRunCmd(client, &buttons)
{
    if(!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
        return Plugin_Continue;

    static int iPrevButtons[MAXPLAYERS];
    
    #if defined bTimes
    /*Attempt at only sampling real gameplay*/
    if(Timer_InsideZone(client, MAIN_START, -1) != -1 || Timer_InsideZone(client, BONUS_START, -1) != -1)
    {
        g_jumpsFromZone[client] = 0;
        return Plugin_Continue;
    }
    
    if(GetEntityFlags(client) & FL_ONGROUND && buttons & IN_JUMP)
        g_jumpsFromZone[client]++;
        
    if(g_jumpsFromZone[client] < 2)
        return Plugin_Continue;
    #endif
	
    if(!(GetEntityFlags(client) & FL_ONGROUND))
    {
        if(!(buttons & IN_MOVELEFT) && buttons & IN_MOVERIGHT) //Holding right, not left
        {
            if(!(iPrevButtons[client] & IN_MOVERIGHT) && iPrevButtons[client] & IN_MOVELEFT)
                PerfTransition(client);
        }
        else if(!(buttons & IN_MOVERIGHT) && buttons & IN_MOVELEFT) //Holding left, not right
        {
            if(!(iPrevButtons[client] & IN_MOVELEFT) && iPrevButtons[client] & IN_MOVERIGHT)
                PerfTransition(client);
        }
        else if(buttons & IN_MOVELEFT && buttons & IN_MOVERIGHT)
            g_perfStrafeCt[client] = 0;
    }

    iPrevButtons[client] = buttons;
    return Plugin_Continue;
}

PerfTransition(int client)
{
    g_perfStrafeCt[client]++;
    if(g_perfStrafeCt[client] < 150)
        return;

	//Yes, I'm suspicious about these thresholds too...
		
    if(g_perfStrafeCt[client] == 250)
        OryxTrigger(client, TRIGGER_LOW, DESC);
    else if(g_perfStrafeCt[client] == 330)
        OryxTrigger(client, TRIGGER_MEDIUM, DESC);
    else if(g_perfStrafeCt[client] == 510)
        OryxTrigger(client, TRIGGER_HIGH_NOKICK, DESC);
}





