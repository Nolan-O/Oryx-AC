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
#include <bTimes-core>
#endif

public Plugin:myinfo = 
{
    name = "ORYX strafe module",
    author = "Rusty",
    description = "Detects suspicious strafe behaviour",
    version = "1.0",
    url = ""
}

#define DESC1 "Acute TR formatter"
#define DESC2 "+left/right bypasser"
//#define DESC3 "Angle snapping"
#define DESC4 "Prestrafe tool"
#define DESC5 "Possible AC bypass attempt via +left/right forging"
#define DESC6 "Average strafe too close to 0"
#define DESC7 "Too many perfect strafes"

char logpath[PLATFORM_MAX_PATH];

int g_perfAngStreak[MAXPLAYERS];
int g_steadyAngStreak[MAXPLAYERS];
int g_steadyAngStreakPre[MAXPLAYERS];
int g_unsteadyAngStreak[MAXPLAYERS];

int g_keyTransTick[MAXPLAYERS];
int g_angTransTick[MAXPLAYERS];
int g_strafeHist[MAXPLAYERS][30];
int g_strafeHistIdx[MAXPLAYERS];
bool g_keyChanged[MAXPLAYERS];
bool g_dirChanged[MAXPLAYERS];
bool g_suffBashData[MAXPLAYERS];
int g_bashTrigCtDown[MAXPLAYERS];
int g_bashCheckIdx = 1;

public OnPluginStart()
{
    RegConsoleCmd("strafe_stats", Command_PrintStrafeStats);
    
    BuildPath(Path_SM, logpath, sizeof(logpath), "logs/oryx-strafe-stats.log");
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
    g_perfAngStreak[client] = 0;
    g_steadyAngStreak[client] = 0;
    g_steadyAngStreakPre[client] = 0;
    g_unsteadyAngStreak[client] = 0;
    g_keyTransTick[client] = 0;
    g_angTransTick[client] = 0;
    g_keyChanged[client] = false;
    g_dirChanged[client] = false;
    g_suffBashData[client] = false;
    g_bashTrigCtDown[client] = 0;
    g_strafeHistIdx[client] = 0;
    for(int i=0; i<30; i++)
    {
        g_strafeHist[client][i] = 0;
    }
    
    return true;
}

public Action Command_PrintStrafeStats(int client, int args)
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
    if(g_suffBashData[target])
        PrintToConsole(client, FormatStrafeStats(target));
    else
        PrintToChat(client, "Player does not have sufficient strafe data yet!");
    return Plugin_Handled;
}

char[] FormatStrafeStats(int target)
{
    decl String:id[32], String:name[64];
    GetClientName(target, name, sizeof(name));
    if(!GetClientAuthId(target, AuthId_Steam2, id, sizeof(id)))
        id = "ERR_GETTING_ID";
    
    decl String:statStr[150];
    Format(statStr, sizeof(statStr), "\n\nSTRAFE STATS FOR:\n%s ( %s )\n%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d",
        name,
        id,
        g_strafeHist[target][0],
        g_strafeHist[target][1],
        g_strafeHist[target][2],
        g_strafeHist[target][3],
        g_strafeHist[target][4],
        g_strafeHist[target][5],
        g_strafeHist[target][6],
        g_strafeHist[target][7],
        g_strafeHist[target][8],
        g_strafeHist[target][9],
        g_strafeHist[target][10],
        g_strafeHist[target][11],
        g_strafeHist[target][12],
        g_strafeHist[target][13],
        g_strafeHist[target][14],
        g_strafeHist[target][15],
        g_strafeHist[target][16],
        g_strafeHist[target][17],
        g_strafeHist[target][18],
        g_strafeHist[target][19],
        g_strafeHist[target][20],
        g_strafeHist[target][21],
        g_strafeHist[target][22],
        g_strafeHist[target][23],
        g_strafeHist[target][24],
        g_strafeHist[target][25],
        g_strafeHist[target][26],
        g_strafeHist[target][27],
        g_strafeHist[target][28],
        g_strafeHist[target][29]);
    return statStr;
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel_w[3], float angles[3])
{
    static float fPrevOptiAng[MAXPLAYERS], fPrevAng[MAXPLAYERS], fPrevDtAng[MAXPLAYERS], _fPrevDtAng[MAXPLAYERS];
    static int absTicks[MAXPLAYERS], iPrevButtons[MAXPLAYERS];
    static bool leftThisJump[MAXPLAYERS], rightThisJump[MAXPLAYERS];
    //static AngDir angDir;
    
    if(!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
        return Plugin_Continue;
    
    absTicks[client]++;

    float _dtAng = angles[1] - fPrevAng[client];
    if (_dtAng > 180)
        _dtAng -= 360;
    else if(_dtAng < -180)
        _dtAng += 360;
    float dtAng = FloatAbs(_dtAng);
    
    if(dtAng < 1/64)
        return Plugin_Continue;
    
    /*
    * BASH remake
    * Some of the logic may seem redundant, but it probably isn't.
    */
    if(!(GetEntityFlags(client) & FL_ONGROUND))
    {
        if(!(buttons & IN_MOVERIGHT && buttons & IN_MOVELEFT))
        {
            if(buttons & IN_MOVELEFT){
                if((iPrevButtons[client] & IN_MOVERIGHT && iPrevButtons[client] & IN_MOVELEFT) || !(iPrevButtons[client] & IN_MOVELEFT))
                {
                    g_keyChanged[client] = true;
                    g_keyTransTick[client] = absTicks[client];
                }
            }
            else if(buttons & IN_MOVERIGHT){
                if((iPrevButtons[client] & IN_MOVERIGHT && iPrevButtons[client] & IN_MOVELEFT) || !(iPrevButtons[client] & IN_MOVERIGHT))
                {
                    g_keyChanged[client] = true;
                    g_keyTransTick[client] = absTicks[client];
                }
            }
        }
        if(dtAng != 0.0 && ((_dtAng < 0.0 && _fPrevDtAng[client] > 0.0) || (_dtAng > 0.0 && _fPrevDtAng[client] < 0.0) || fPrevDtAng[client] == 0.0))
        {
            if(!g_dirChanged[client])
            {
                g_dirChanged[client] = true;
                g_angTransTick[client] = absTicks[client];
            }
        }
        
        if(g_keyChanged[client] && g_dirChanged[client])
        {
            g_keyChanged[client] = false;
            g_dirChanged[client] = false;
            int t = g_keyTransTick[client] - g_angTransTick[client];
            //Chop off anything greater than 25 ticks of error
            if(t > -26 && t < 26)
            {
                g_strafeHist[client][g_strafeHistIdx[client]] = t;
                g_strafeHistIdx[client]++;
            }
            if(g_bashTrigCtDown[client])
                g_bashTrigCtDown[client]--;
        }
        
        if(!g_suffBashData[client])
            if(g_strafeHistIdx[client] == 30)
                g_suffBashData[client] = true;
        if(g_strafeHistIdx[client] == 30)
            g_strafeHistIdx[client] = 0;
        
        #if defined bTimes
        //this block is for allowing usage of +left/right, but in only one direction per jump
        if(buttons & IN_LEFT)
            leftThisJump[client] = true;
        if(buttons & IN_RIGHT)
            rightThisJump[client] = true;
        if(leftThisJump[client] && rightThisJump[client] && IsBeingTimed(client, TIMER_ANY))
        {
            StopTimer(client);
            PrintToChat(client, "Your timer has been stopped for using +left and +right in a single jump.");
            leftThisJump[client] = false;
            rightThisJump[client] = false;
        }
        #endif
    }
    else
    {
        g_keyChanged[client] = false;
        g_dirChanged[client] = false;
        
        #if defined bTimes
        //for the above +left/right-related block
        leftThisJump[client] = false;
        rightThisJump[client] = false;
        #endif
    }
    
    float vel[3];
    Entity_GetAbsVelocity(client, vel);
    float vel2D = SquareRoot((vel[0] * vel[0]) + (vel[1] * vel[1]));
    
    /* Perfect TR formatter */
    //Above a certain speed, float inaccuracies throw false positives
    if(WithinFlThresh(dtAng, fPrevOptiAng[client], 128.0) && vel2D < 2560.0)
    {
        g_perfAngStreak[client]++;
        if(g_perfAngStreak[client] == 10)
            OryxTrigger(client, TRIGGER_LOW, DESC1);
        else if(g_perfAngStreak[client] == 33)
            OryxTrigger(client, TRIGGER_MEDIUM, DESC1);
        else if(g_perfAngStreak[client] == 48)
            OryxTrigger(client, TRIGGER_HIGH, DESC1);
    }
    else { g_perfAngStreak[client] = 0; }

    if(!(buttons & IN_LEFT || buttons & IN_RIGHT))
    {
        /* +left/right bypassing */
        if(WithinFlThresh(dtAng, fPrevDtAng[client], 128.0))
        {
            if(!(GetEntityFlags(client) & FL_ONGROUND))
            {
                g_steadyAngStreak[client]++;
                if(g_steadyAngStreak[client] == 50)
                    OryxTrigger(client, TRIGGER_HIGH, DESC2);
            }
        }
        else { g_steadyAngStreak[client] = 0; }
        
        /* Basically +left/right check but on the ground */
        if(GetEntityFlags(client) & FL_ONGROUND && WithinFlThresh(dtAng, 1.2, 128.0))
        {
            //Yes, I know this method is bad. It's just not high priority.
            g_steadyAngStreakPre[client]++;
            if(g_steadyAngStreakPre[client] > 18)
                OryxTrigger(client, TRIGGER_MEDIUM, DESC4);
            else if(g_steadyAngStreakPre[client] > 36)
                OryxTrigger(client, TRIGGER_HIGH, DESC4);
        }
        else { g_steadyAngStreakPre[client] = 0; }
    }
    
    iPrevButtons[client] = buttons;
    fPrevOptiAng[client] = ArcSine(30.0 / vel2D) * 57.29577951308;
    fPrevAng[client] = angles[1];
    fPrevDtAng[client] = dtAng;
    _fPrevDtAng[client] = _dtAng;

    return Plugin_Continue;
}

/* Loop through the player list, one player per tick, and check their bash stats.
 * It is important that you don't check players based on when they strafe, otherwise they
 * can gerrymander their stats to allow better improvements without more detections aswell
 */
public OnGameFrame()
{
    if(g_bashCheckIdx > MaxClients)
        g_bashCheckIdx = 1;

    //Cooldowns prevent the same stats getting analyzed again after a detection
    if(g_bashTrigCtDown[g_bashCheckIdx])
    {
        g_bashCheckIdx++;
        return;
    }
    if(IsClientInGame(g_bashCheckIdx) && IsPlayerAlive(g_bashCheckIdx))
    {
        //Use their ground state as a makeshift afk determinant 
        //No need to check people who aren't playing
        if(g_suffBashData[g_bashCheckIdx] && !(GetEntityFlags(g_bashCheckIdx) & FL_ONGROUND))
        {
            CheckBash(g_bashCheckIdx);
        }
    }
        
    g_bashCheckIdx++;
}

void CheckBash(int client)
{
    int accum, zct;
    for(int i = 0; i < 30; ++i)
    {
        accum += ((g_strafeHist[client][i] >= 0) ? (g_strafeHist[client][i]) : (g_strafeHist[client][i] * -1)); //Make abs
        if(g_strafeHist[client][i] == 0)
            zct++;
    }
    
    /*Average tick difference*/
    if(accum < 9)
    {
        OryxTrigger(client, TRIGGER_HIGH, DESC6);
        g_bashTrigCtDown[client] = 35;
    }
    else if(accum < 15)
    {
        OryxTrigger(client, TRIGGER_LOW, DESC6);
        g_bashTrigCtDown[client] = 35;
    }

    //Don't trigger twice in one tick
    if(g_bashTrigCtDown[client])
    {
        decl String:str[150];
        str = FormatStrafeStats(client);
        PrintToAdminsConsole(str);
        LogToFileEx(logpath, str);
        return;
    }
    
    /*Too many 0s?*/
    if(zct > 25)
    {
        OryxTrigger(client, TRIGGER_HIGH, DESC7);
        g_bashTrigCtDown[client] = 35;
    }
    else if(zct > 22)
    {
        OryxTrigger(client, TRIGGER_MEDIUM, DESC7);
        g_bashTrigCtDown[client] = 35;
    }
    else if(zct > 18)
    {
        OryxTrigger(client, TRIGGER_LOW, DESC7);
        g_bashTrigCtDown[client] = 35;
    }
    
    if(g_bashTrigCtDown[client])
    {
        decl String:str[150];
        str = FormatStrafeStats(client);
        PrintToAdminsConsole(str);
        LogToFileEx(logpath, str);
        return;
    }
}









