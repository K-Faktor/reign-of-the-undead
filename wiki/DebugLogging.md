# Debug Logging in RotU

 - **Applies to:** RotU 2.2.2-git+
 - **Status:** Draft


## Introduction

We have replaced the logging system used in the RotU 2.2 series with a new system that allows for JSON logging and simplified configuration. JSON logging facilitates writing log parsers and analyzers.

The implementation of the debug system is in scripts/include/utility.gsc. There is one primary logging function, and a few helper functions.

```c
/**
 * @brief Writes JSON-formatted log messages to logfile specified in g_log dvar
 *
 * @param eventType string The type of message. Any of the values in the switch:
 *                           [value|warn|error|debug|server|criticalbug|...]
 *
 * @param message string The pipe-encoded JSON message to write.  The first JSON
 *                       key in the message ahould be 'msg|`.
 * @param includeEpoch bool Include the Unix epoch, i.e. integer seconds?
 *
 * @returns nothing
 */
log(eventType, message, includeEpoch)
```

The message must be valid pipe-encoded JSON, that is, JSON with colons, spaces, and double-quotes omitted. a single pipe `|` marks the end of a key, and a double pipe `||` marks the end of a key-value pair.

A simple log message might be:

```c
log("server", "msg|Hello World!||");
```

which produces a log message with a valid JSON fragment like:

```log
0:00 Notice: {"event": "server",   "msg": "Hello World!"}
```

Note: For "pre" type log messages, you are responsible for adding your own newline "\n" characters.

## Supporting Methods

 - `initLogging()`
        This method reads logging dvars, and sets up the logging system, including which messages to suppress.
 - `tokenizeMessage(encodedJson)`
        The method converts the pipe-encoded JSON to valid JSON fragments. Append ':n" to a value to designate it as Numeric, and ':b" for boolean
 - `sprintfLog(formatString, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19)`
        This method does sprintf-like variable interpolation in a string. It is very helpful for long json fragments.

## Sample Real Logging Messages

```c
log("debug", "msg|From players::cleanup(), trying to remove turret " + level.minigunTurrets[i].id + "||");
log("server", sprintfLog("msg|player state||name|$1||sessionState|$2||sessionTeam|$3||isIntermission|$4:b||", self.name, self.sessionstate, self.sessionteam, isIntermission));

// The long line above could be written as two lines, with identical results:
fmt = "msg|player state||name|$1||sessionState|$2||sessionTeam|$3||isIntermission|$4:b||";
log("server", sprintfLog(fmt, self.name, self.sessionstate, self.sessionteam, isIntermission));
```

## Configuration

The configuration settings in game.cfg/game_default.cfg from 2.2.2 and earlier are deprecated and removed.  The only log settings are now in server.cfg.  Only one part of the new logging system is configurable--which messages to suppress:

```c
set sv_hide_log_message           "trace, debug, value, signal, pre" // hide these type of messages
```

Note: If you run the non-debug version of the scripts on your server, most log() function calls have been removed and replaced with blank lines (to preserve line numbering).  You probably always want to suppress trace and signal messages--they will really blow things up.

## Non-Debug Scripts

The non-debug scripts have most logging statements removed. They are intended for running a normal released version of the mod on a production server.  If you are running a alpha, beta, nightly, or git version, please use the debug version of the scripts, so potentially more useful debug output is written to the logs.

The new build system, makeMod.py, deprecates makMod.pl, and creates debug and non-debug versions of the rotu server scripts.  For the non-debug version, it removes certain lines from the source code, while preserving the new line characters so error messages in console_mp.log still refer to the correct lines.  The three types of code the script removes, in precedence order, are:

1)  Any lines containing and between `<debug></debug>` tags following a C++ style
    comment, e.g.
    ```c
    // <debug>
    for (i=0; i<level.players.size; i++) {
        level.players[i].headicon = "myTestHeadicon";
    }
    // </debug>
    ``` 
    N.B. the entire line containing a `<debug>` or `</debug>` tag is removed!

2)  Any single line containing a self-closing `<debug />` tag inside of a C++ style
    comment.  This is useful for denoting that a function call should only be
    made when in debug mode, e.g. ```printPlayersInGame(); // <debug />```

3)  All log() messages with the following types will be removed:
    - trace
    - debug
    - value
    - signal
    - dev
    - automaptest

    The following message types will not be removed:
    - server
    - bug
    - error
    - warn
    - criticalbug
    - validate
    - pre
    
## Errata

CoD4 1.7 official has a line-character limit of unknown length for log file lines. Any message that exceeds that limit gets truncated to that limit, losing data. Messages up to about 200 characters are OK; anything longer, and you risk truncation.
