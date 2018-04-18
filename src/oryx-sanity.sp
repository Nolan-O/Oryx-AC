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
#include <oryx>

public Plugin:myinfo = 
{
    name = "ORYX sanity module",
    author = "Rusty",
    description = "Sanity checks on movement",
    version = "1.0",
    url = ""
}

#define DESC1 "Unsynchronised movement"
#define DESC2 "Invalid wish velocity"

public Action OnPlayerRunCmd(client, &buttons, &impulse, float wishvel[3], float angles[3])
{
    //[0] = forwardmove
    //[1] = sidemove
    if(!IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
        return Plugin_Continue;
    
    //Used to prevent multiple triggers on a single tick
    bool triggered = false;
    
    if(wishvel[1] == -400 && !(buttons & IN_MOVELEFT))
        triggered = true;
    else if(wishvel[1] == 400 && !(buttons & IN_MOVERIGHT))
        triggered = true;
    else if(wishvel[0] == 400 && !(buttons & IN_FORWARD))
        triggered = true;
    else if(wishvel[0] == -400 && !(buttons & IN_BACK))
        triggered = true;
        
    if(triggered)
    {
        OryxTrigger(client, TRIGGER_DEFINITIVE, DESC1);
        return Plugin_Continue;
    }
    
    float side = FloatAbs(wishvel[1]);
    float fore = FloatAbs(wishvel[0]);
    if(fore && fore != 400 &&  fore != 200 && fore != 300 && fore != 100)
        triggered = true;
    else if(side && side != 400 &&  side != 200 && side != 300 && side != 100)
        triggered = true;
    
    if(triggered)
    {
        OryxTrigger(client, TRIGGER_DEFINITIVE, DESC2);
        return Plugin_Continue;
    }
    return Plugin_Continue;
}