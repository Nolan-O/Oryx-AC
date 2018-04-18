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

#pragma semicolon 1

enum TriggerType:
{
    TRIGGER_LOW,                    //Reachable by skilled players occasionally. Not always necessary before a med detect
    TRIGGER_MEDIUM,                 //Reachable by skilled players by unlikely chance
    TRIGGER_HIGH,                   //Only theoretically reachable by the aligning of stars by the gods
    TRIGGER_HIGH_NOKICK,            //This should really only be used for a follow up definitive detection
    TRIGGER_DEFINITIVE,              //Non-skill-based detection type. 100% sure detection.
    TRIGGER_TEST
};

/**
 * Acceptable timers: "bTimes" & "notimer"
 */
#define bTimes

/**
 * Call to activate oryx's trigger procedure (logging, kicking, admin notifications, etc..)
 *
 * @param int                   client entity index
 * @param TriggerType           level of detection as defined in the above enum
 * @param String                short description or name of the cheat being detected
 * @noreturn
 */
native void OryxTrigger(int client, TriggerType level, char[] cheat);

/**
 * Prints a message to admins' chat
 *
 * @param char[]                pre-formatted message to print to admins
 */
native void PrintToAdmins(char[] msg);

/**
 * Prints a message to admins' console
 *
 * @param char[]                pre-formatted message to print to admins
 */
native void PrintToAdminsConsole(char[] msg);

/**
 * Tests if f1 is within a 1/frac threshold of f2
 *
 * @param float                 first value
 * @param float                 second value
 * @param int                   used as a fractional threshold of f2 for f1 to be within
 * @return                      true if the test passed
 */
native bool WithinFlThresh(float f1, float f2, float frac);


/*List of current detection descriptions:

"Acute TR formatter"
"+left/right bypasser"
"Prestrafe tool"
"Average strafe too close to 0"
"Too many perfect strafes"
"Movement config"
"Unsynchronised movement"
"Invalid wish velocity"
"Script on scroll"
"Hyperscroll"
*/
 
 




