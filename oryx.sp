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

public Plugin:myinfo = 
{
    name = "ORYX Anti-Cheat",
    author = "Rusty",
    description = "Cheat detection interface",
    version = "1.0",
    url = ""
}

char logpath[PLATFORM_MAX_PATH];
bool testing[MAXPLAYERS];
bool plLock[MAXPLAYERS];

public Action Command_OryxTest(int client, int args)
{
    testing[client] = !testing[client];
    PrintToChat(client, "%s", testing[client]?"On":"Off");
    return Plugin_Handled;
}

public Action Command_LockPlayer(int client, int args)
{
    if(args < 1)
        return Plugin_Handled;
    
    decl String:arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    int target = Client_FindByName(arg1);
    
    plLock[target] = !plLock[target];
    PrintToChat(client, "Player has been %s", plLock[target]?"locked":"unlocked");
    PrintToChat(target, "An admin has %s your ability to move!", plLock[target]?"locked":"unlocked");
    return Plugin_Handled;
}

public bool OnClientConnect(int client)
{
    plLock[client] = false;
    testing[client] = false;
    return true;
}

public OnPluginStart()
{
    RegAdminCmd("sm_otest", Command_OryxTest, ADMFLAG_GENERIC);
    RegAdminCmd("sm_lock", Command_LockPlayer, ADMFLAG_GENERIC);
    
    BuildPath(Path_SM, logpath, sizeof(logpath), "logs/oryx.log");
}

public APLRes AskPluginLoad2(Handle myself, bool late, String:error[], err_max)
{
    CreateNative("OryxTrigger", Native_OryxTrigger);
    CreateNative("WithinFlThresh", Native_WithinFlThresh);
    CreateNative("PrintToAdmins", Native_PrintToAdmins);
    CreateNative("PrintToAdminsConsole", Native_PrintToAdminsConsole);
    return APLRes_Success;
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel_w[3], float angles[3])
{
    if(plLock[client])
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Native_OryxTrigger(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    TriggerType level = GetNativeCell(2);
    decl String:id[32];
    GetClientAuthId(client, AuthId_Steam2, id, sizeof(id));
    
    char name[32];
    GetClientName(client, name, sizeof(name));
    
    char lvl[12], cheatdesc[32];
    GetNativeString(3, cheatdesc, sizeof(cheatdesc));
    if(level == TRIGGER_LOW)
        lvl = "LOW";
    else if(level == TRIGGER_MEDIUM)
        lvl = "MEDIUM";
    else if(level == TRIGGER_HIGH){
        lvl = "HIGH";
        KickClient(client, "%s", cheatdesc);
    }
    else if(level == TRIGGER_HIGH_NOKICK)
        lvl = "HIGH-nk";
    else if(level == TRIGGER_DEFINITIVE){
        lvl = "DEFINITIVE";
        KickClient(client, "%s", cheatdesc);
    }
    else if(level == TRIGGER_TEST){
        decl String:buf[132];
        Format(buf, sizeof(buf), "%s : %s | Level: %s", name, cheatdesc, "TESTING");
        for(int i = 0; i < MAXPLAYERS; ++i)
        {
            if(testing[i])
                PrintToChat(i, buf);
        }
        return;
    }

    decl String:buf[132];
    Format(buf, sizeof(buf), "%s ( %s ) Cheat: %s | Level: %s", name, id, cheatdesc, lvl);
    PrintToAdmins(buf);
    
    LogToFileEx(logpath, "%s ( %s ) Cheat: %s | Level: %s", name, id, cheatdesc, lvl);
}

public Native_WithinFlThresh(Handle plugin, int numParams)
{
    float f2 = GetNativeCell(2);
    float t = f2 / GetNativeCell(3);
    float f1 = GetNativeCell(1);
    if(f1 > (f2 - t) && f1 < (f2 + t)) { return true; }
        
    return false;
}

public Native_PrintToAdmins(Handle plugin, int numParams)
{
    decl String:msg[150];
    GetNativeString(1, msg, sizeof(msg));
    for (int i=1; i<=MAXPLAYERS; ++i)
    {
        if(CheckCommandAccess(i, "yoo", ADMFLAG_GENERIC, true))
            PrintToChat(i, msg);
    }
}

public Native_PrintToAdminsConsole(Handle plugin, int numParams)
{
    decl String:msg[150];
    GetNativeString(1, msg, sizeof(msg));
    for (int i=1; i<=MAXPLAYERS; ++i)
    {
        if(CheckCommandAccess(i, "yoo", ADMFLAG_GENERIC, true))
            PrintToConsole(i, msg);
    }
}






