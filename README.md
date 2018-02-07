# The Oryx bhop anticheat for CSS.

This was written for SourceMod v1.7. Few comments are provided because I never planned on releasing the code, however there are *some* comments. The bulk of everything outside of oryx.sp is just pure game-mechanic-related logic anyway, so it just works because that's the way things work.

## Users please note that this project is no longer supported.

# Building

Depends on smlib.  
All you need to do is make sure you've specified your timer in oryx.inc by defining either `notimer` or `bTimes`. Build each file manually with the sourcemod compiler, like usual.  

# Documentation  
A lot of this info is found in oryx.inc too.

Exported command | Action | Admin only? | From: 
---------------- | ------ | ----------- | -----
sm_otest | Enables the TRIGGER_TEST detection level | yes | oryx
sm_lock \<player> | Disables movement for a player | yes | oryx
scroll_stats \<player> | Print the scroll stat buffer for a given player | no | oryx-scroll
strafe_stats \<player> | Print the strafe stat buffer for a given player | no | oryx-strafe
config_streak \<player> | Print the config stat buffer for a given player | yes | oryx-configcheck


Trigger type | Usage
------------ | -----
TRIGGER_LOW | Like an early warning system. Oryx has probably not found a cheater, but you should keep an eye out.  
TRIGGER_MEDIUM | Also early warning.  
TRIGGER_HIGH | Oryx is pretty sure someone is cheating, and this will kick them.  
TRIGGER_HIGH_NOKICK | Just what it sounds like. High alert, but no automated consequences.  
TRIGGER_DEFINITIVE | Used by only by oryx-sanity right now. This should be used on non-stat-based detections.
TRIGGER_TEST | Allows you to develop new detections on live servers with minimal side effects.

Detection type | Meaning | From
-------------- | ------- | ----
Acute TR formatter | The player's turn rate has been made perfect | oryx-strafe
+left/right bypasser | +left/right bitflags have been stripped from the client's buttons variable | oryx-strafe
Prestrafe tool | Player is using a static turnrate to get 289 walk speed. Same as +left/right bypassing, but for a specific value on the ground | oryx-strafe
Average strafe too close to 0 | The average strafe offset is suspiciously near 0 | oryx-strafe
Too many perfect strafes | The average strafe offset is not too close to 0, but there is a suspiciously high frequency of 0s | oryx-strafe
Movement config | Player exhibits behavior that is humanly possible, but movement configs would enforce it | oryx-configcheck
Unsynchronised movement | Wish velocity does not align with with the player's buttons variable | oryx-sanity
Invalid wish velocity | Wish velocity can only be multiples of 100, bound to 400 and -400 | oryx-sanity
Script on scroll | Too many perfect jumps indicates a potential jump script usage | oryx-scroll
Hyperscroll | Too many jumps in the air prior to jumping indicates potential +jump spamming | oryx-scroll


Docs on natives are found in oryx.inc, using the sm self-documenting style.

The plugins have only been tested with bTimes ~v1.8.x (as found [here](https://github.com/Nolan-O/bTimes))  
If someone else is able to test with 2.0, please edit this readme and submit a pull request.

# Useful Definitions

* **Key-transition**: the changing of direction with keys (i.e. changing from `+moveleft` to `+moveright`)
* **Angle-transition**: the changing of direction in a player's camera along the x axis
* **Strafe offset**: the number of ticks that pass between a key-transition and angle-transition
* **Wish velocity**: Also called wishvel, this value is used for calculating movement direction, not the player buttons variable
* **Movement config**: Key bindings that prohibit the player from pressing opposing movement keys (i.e. `+moveleft` and `+moveright` can't be held at the same time
* **TR**: Turn-rate -- the rate of rotation of the client's camera along the x axis
