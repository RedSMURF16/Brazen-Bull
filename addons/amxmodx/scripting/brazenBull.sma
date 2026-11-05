/*
*
*	Brazen Bull by RedSMURF
*
*
*	Description:
*
*	Cvars:
*		None
*
*   Commands:
*       say /bull [name | all]          "Opens the Bull menu or executes the specified player(s)."
*       say_team /bull [name | all]     "Opens the Bull menu or executes the specified player(s)."
*       brazenbull_reload               "Reloads the configuration file."
*
*	Changelog:
*       v1.0: Initial release.
*
*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#if !defined MAX_PLAYERS
    #define MAX_PLAYERS 32
#endif

#if !defined MAX_VALUE_LENGTH
    #define MAX_VALUE_LENGTH 64
#endif

#if !defined MAX_RESOURCE_PATH_LENGTH
    #define MAX_RESOURCE_PATH_LENGTH 128
#endif

#if !defined MAX_FILE_CELL_SIZE
    #define MAX_FILE_CELL_SIZE 192
#endif

#if !defined MAX_PLATFORM_PATH_LENGTH
    #define MAX_PLATFORM_PATH_LENGTH 256
#endif

#define MAX_ENT                     32
#define BULL_CHECK                  10.0
#define BULL_OFFSET_BASE            120.0
#define BULL_OFFSET_MIN             65.0
#define BULL_OFFSET_MAX             900.0
#define BULL_OFFSET_STEP            10.0
#define BULL_GHOST_ALPHA            120
#define BULL_ROTATION_STEP          22.5
#define ADMIN_ACCESS                ADMIN_RCON
#define PDATA_NEXT_ATTACK           83
#define XO_CBASEPLAYER              5
#define XO_CBASEPLAYERWEAPON        4
#define BULL_KEY                    444404
#define BULL_LOCKED_KEY             444405
#define BULL_ARRAY_ITEM             pev_iuser1
#define SEQ                         60
#define VIEW_FORWARD_OFFSET         128.0
#define VIEW_RIGHT_OFFSET           128.0
#define VIEW_UP_OFFSET              32.0
#define HUD_Y_STEP                  0.025
#define HUD_Y_MAX                   0.7
#define BULL_DURATION_OPEN          3.0
#define BULL_DURATION_CLOSE         0.69
#define BULL_SEQ_OPENED             0
#define BULL_SEQ_CLOSED             1
#define BULL_SEQ_OPEN               2
#define BULL_SEQ_CLOSE              3
#define SOUND_NAV                   "buttons/blip1.wav"
#define SOUND_REMOVE                "buttons/button10.wav"
#define SOUND_ALERT                 "buttons/bell1.wav"

new const PLUGIN_VERSION[]          = "1.0"
new const Float:DELAY_ON_LOAD       = 2.0
new const ERROR_FILE[]              = "BrazenBull_ERRORS.log"

enum
{
    SECTION_NONE,
    SECTION_MAIN_SETTINGS,
    SECTION_BULL
}

enum
{
    DTYPE_INT,
    DTYPE_FLOAT,
    DTYPE_FLAGS,
    DTYPE_STRING_MODEL,
    DTYPE_STRING_SOUND,
    DTYPE_ARRAY_MESSAGE,
    DTYPE_ARRAY_MODEL,
    DTYPE_ARRAY_SOUND,
    DTYPE_STRING_MODEL_ID,
    DTYPE_ARRAY_MODEL_ID
}

enum
{
    FLAG_SHOW               = (1 << 0),
    FLAG_GHOST              = (1 << 1),
    FLAG_GROUND             = (1 << 2),
    FLAG_ACTIVE             = (1 << 3),
    FLAG_USED               = (1 << 4)
}

enum
{
    TEAM_NONE,
    TEAM_T,
    TEAM_CT,
    TEAM_BOTH
}

enum
{
    TARGET_GHOST,
    TARGET_SELECT,
    TARGET_HIDE,
    TARGET_CLEAR
}

enum _:MAIN_SETTINGS
{
    SETTING_DEFAULT_MODEL[MAX_RESOURCE_PATH_LENGTH],
    SETTING_DEFAULT_SPRITE_FIRE[MAX_RESOURCE_PATH_LENGTH],
    Array:SETTING_DEFAULT_SOUND,
    Array:SETTING_DEFAULT_SOUND_FIRE,
    Array:SETTING_DEFAULT_SOUND_OPEN,
    Array:SETTING_DEFAULT_SOUND_CLOSE,
    Array:SETTING_DEFAULT_SOUND_SCREAM,
    Array:SETTING_DEFAULT_MESSAGE,
    Array:SETTING_DEFAULT_MESSAGE_FORCED,
    SETTING_DEFAULT_FLAGS,
    SETTING_DEFAULT_TEAM,
    Float:SETTING_DEFAULT_FRAMERATE,
    SETTING_DEFAULT_HOLD_DURATION[2],
    Float:SETTING_DEFAULT_COOLDOWN[2],
    Float:SETTING_DEFAULT_FIRE_FRAMERATE,
    Float:SETTING_DEFAULT_FIRE_SCALE,
    Float:SETTING_DEFAULT_FIRE_COLOR[3],
    Float:SETTING_DEFAULT_FIRE_ALPHA,
    SETTING_DEFAULT_DAMAGE[2],
    Float:SETTING_DEFAULT_DAMAGE_INTERVAL[2],
    SETTING_DEFAULT_DAMAGETYPE,
    Float:SETTING_DEFAULT_SCREAM_INTERVAL[2],
    bool:SETTING_PLAY_SOUND_ON_DEATH,
    bool:SETTING_WRITE_MESSAGE_ON_DEATH,
    bool:SETTING_KILL_ALL_EXCLUDE_CALLER,
    bool:SETTING_SET_CAMERA_ON_VICTIM,

    Float:SETTING_HUD_X,
    Float:SETTING_HUD_Y,
    SETTING_HUD_COLOR[3],
    SETTING_HUD_EFFECT,
    Float:SETTING_HUD_FXTIME,
    Float:SETTING_HUD_HOLDTIME,
    Float:SETTING_HUD_FADEIN,
    Float:SETTING_HUD_FADEOUT,

    Float:SETTING_MINS[3],
    Float:SETTING_MAXS[3],

    bool:SETTING_BULL_LOAD,
    Float:SETTING_BULL_TASK,
}

enum _:BULL
{
    BULL_ID,
    BULL_ITEM,
    BULL_FLAGS,
    BULL_TEAM,
    BULL_VIEW,
    BULL_FIRE,
    BULL_NAME[MAX_VALUE_LENGTH],
    BULL_SPRITE_FIRE[MAX_RESOURCE_PATH_LENGTH],
    Float:BULL_FRAMERATE,
    Float:BULL_COOLDOWN[2],
    Float:BULL_FIRE_FRAMERATE,
    Float:BULL_FIRE_SCALE,
    Float:BULL_FIRE_COLOR[3],
    Float:BULL_FIRE_ALPHA,
    BULL_DAMAGE[2],
    Float:BULL_DAMAGE_INTERVAL[2],
    BULL_DAMAGETYPE,

    Float:BULL_ORIGIN[3],
    Float:BULL_ANGLES[3],
    Float:BULL_MINS[3],
    Float:BULL_MAXS[3],

    Float:BULL_NEXT_ACTIVE,
    Float:BULL_NEXT_OPEN
}

enum _:PLAYER_DATA
{
    PDATA_BULL_GHOST,
    PDATA_BULL_MENU,
    bool:PDATA_BULL_ACTION,
    PDATA_BULL_ID,
    bool:PDATA_BULL_HELD,
    bool:PDATA_BULL_LOCKED,
    PDATA_BULL_DAMAGE[2],
    Float:PDATA_BULL_DAMAGE_INTERVAL[2],
    PDATA_BULL_DAMAGETYPE,
    PDATA_CURRENT_SCREAM[MAX_VALUE_LENGTH],
    PDATA_CURRENT_SCREAM_ID,
    Float:PDATA_OFFSET,
    Float:PDATA_NEXT_OFFSET,

    PDATA_MENU_TYPE,
    bool:PDATA_MENU_TRACE,

    Float:PDATA_NEXT_BULL,
    Float:PDATA_NEXT_CHECK,
    Float:PDATA_NEXT_CLOSE,
    Float:PDATA_NEXT_SCREAM
}

enum
{
    SOUND_MENU_NAV,
    SOUND_MENU_REMOVE,
    SOUND_MENU_ALERT,
    SOUND_BULL,
    SOUND_FIRE,
    SOUND_OPEN,
    SOUND_CLOSE
}

enum
{
    MENU_ROOT,
    MENU_CREATE,
    MENU_EDIT,
    MENU_REMOVE,
    MENU_SHOW,
    MENU_STATUS,
    MENU_ROTATE
}

enum
{
    ROOT_CREATE,
    ROOT_EDIT,
    ROOT_REMOVE,
    ROOT_SAVE,

    ROOT_NOCLIP = 5,
    ROOT_GODMODE
}

enum
{
    EDIT_SHOW,
    EDIT_STATUS
}

enum
{
    REMOVE_NEXT,
    REMOVE_BACK,

    REMOVE_CURRENT = 3,
    REMOVE_ALL
}

enum
{
    SHOW_NEXT,
    SHOW_BACK,

    SHOW_CURRENT = 3,
    SHOW_ALL_SHOW,
    SHOW_ALL_HIDE
}

enum
{
    STATUS_NEXT,
    STATUS_BACK,

    STATUS_CURRENT = 3,
    STATUS_ALL_ENABLE,
    STATUS_ALL_DISABLE
}

enum
{
    ROTATE_UP,
    ROTATE_DOWN,

    ROTATE_GROUND = 3,
    ROTATE_PLACE
}

new Float:g_fDirections[][] =
{
    {-1.0, 0.0, 0.0},
    {1.0, 0.0, 0.0},
    {0.0, -1.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, -1.0},
    {0.0, 0.0, 1.0}
}

new g_szMenuHandler[][MAX_VALUE_LENGTH] =
{
    "menuHandlerRoot",
    "menuHandlerCreate",
    "menuHandlerEdit",
    "menuHandlerRemove",
    "menuHandlerShow",
    "menuHandlerStatus",
    "menuHandlerRotate"
}

new g_szCN[] = "brazenbull"

new Array:g_aBull,
    Array:g_aBullConfig,
    g_eSettings[MAIN_SETTINGS],
    g_ePlayerData[MAX_PLAYERS + 1][PLAYER_DATA],
    bool:g_bFileWasRead, g_iActivePlayers,
    g_iFwdEmitSound, HamHook:g_iFwdUse, HamHook:g_iFwdObjectCaps, HamHook:g_iFwdPreThink, HamHook:g_iFwdPostThink,
    g_iBull, g_iBullConfig, g_iBarTime, Float:g_iHudCurrentY, g_iHudObject_1, g_iHudObject_2, g_iHudObject_3, g_iHudSlot,
    g_iMaxPlayers

new Float:g_fFireOffset[] = { 0.0, 0.0, 20.0 }
new Float:g_fPlayerOffset[] = { 7.5, 0.0, -5.0 }
new g_szModelRPG[MAX_RESOURCE_PATH_LENGTH] = "models/w_rpg.mdl"

public plugin_init()
{
    register_plugin("Brazen Bull", PLUGIN_VERSION, "RedSMURF")
    register_cvar("RedSMURF_BrazenBull", PLUGIN_VERSION, ADMIN_ACCESS)

    register_clcmd("say /bull",             "cmdMenu", ADMIN_ACCESS, "-- Opens the Bull menu.")
    register_clcmd("say_team /bull",        "cmdMenu", ADMIN_ACCESS, "-- Opens the Bull menu.")
    register_concmd("brazenbull_reload",    "cmdReload", ADMIN_ACCESS, "-- Reloads the configuration file")
    register_dictionary("BrazenBull.txt")

    g_iFwdEmitSound = register_forward(FM_EmitSound, "fwdEmitSound")
    g_iFwdUse = RegisterHam(Ham_Use, "info_target", "fwdUse")
    g_iFwdObjectCaps = RegisterHam(Ham_ObjectCaps, "info_target", "fwdObjectCaps")
    g_iFwdPreThink = RegisterHam(Ham_Player_PreThink, "player", "fwdPreThink")
    g_iFwdPostThink = RegisterHam(Ham_Player_PostThink, "player", "fwdPostThink", 1)
    RegisterHam(Ham_Killed, "player", "fwdKilled", 1)
    g_iBarTime = get_user_msgid("BarTime")
    g_iHudObject_1 = CreateHudSyncObj()
    g_iHudObject_2 = CreateHudSyncObj()
    g_iHudObject_3 = CreateHudSyncObj()
    register_logevent("eventRoundStart", 2, "1=Round_Start")
    DisableForward()
    DisableBull()

    bullInit()
    g_iMaxPlayers = get_maxplayers()
}

public plugin_precache()
{
    g_aBull = ArrayCreate(BULL)
    g_aBullConfig = ArrayCreate(BULL)
    g_eSettings[SETTING_DEFAULT_SOUND] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_FIRE] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_OPEN] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_CLOSE] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_SOUND_SCREAM] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_MESSAGE] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)
    g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED] = ArrayCreate(MAX_RESOURCE_PATH_LENGTH)

    precache_model(g_szModelRPG)
    ReadFile()
}

public plugin_end()
{
    ArrayDestroy(g_aBull)
    ArrayDestroy(g_aBullConfig)
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_FIRE])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_OPEN])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_CLOSE])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_SOUND_SCREAM])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_MESSAGE])
    ArrayDestroy(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED])
}

public cmdMenu(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    new szTarget[64]
    read_argv(2, szTarget, charsmax(szTarget))
    remove_quotes(szTarget)
    if ( !szTarget[0] )
    {
        bullSound(id, SOUND_MENU_NAV)
        bullMenu(id, MENU_ROOT)
        return PLUGIN_HANDLED
    }

    new eBull[BULL], bool:bFoundBull
    new iArgIndex = 2
    new bool:bProcessed[33]
    while ( szTarget[0] )
    {
        if ( equali(szTarget, "all") )
        {
            for ( new iTarget = 1; iTarget <= g_iMaxPlayers; iTarget ++ )
            {
                if ( !is_user_connected(iTarget) || bProcessed[iTarget]
                || (g_eSettings[SETTING_KILL_ALL_EXCLUDE_CALLER] && iTarget == id) )
                    continue

                bProcessed[iTarget] = true
                if ( !is_user_alive(iTarget) )
                    continue

                bFoundBull = false
                for ( new iItem = 0; iItem < g_iBull; iItem ++ )
                {
                    ArrayGetArray(g_aBull, iItem, eBull)
                    if ( eBull[BULL_FLAGS] & FLAG_USED )
                        continue

                    bullBull(eBull, iTarget, true)
                    ArraySetArray(g_aBull, iItem, eBull)
                    bFoundBull = true
                    break
                }

                if ( !bFoundBull )
                {
                    client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_NO_BULL")
                    break
                }
            }
        }
        else
        {
            new iTarget = cmd_target(id, szTarget, CMDTARGET_ALLOW_SELF)
            if ( iTarget && !bProcessed[iTarget] )
            {
                bProcessed[iTarget] = true
                if ( !is_user_alive(iTarget) )
                {
                    client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_NOT_ALIVE")
                }
                else
                {
                    bFoundBull = false
                    for ( new iItem = 0; iItem < g_iBull; iItem ++ )
                    {
                        ArrayGetArray(g_aBull, iItem, eBull)
                        if ( eBull[BULL_FLAGS] & FLAG_USED )
                            continue

                        bullBull(eBull, iTarget, true)
                        ArraySetArray(g_aBull, iItem, eBull)
                        bFoundBull = true
                        break
                    }

                    if ( !bFoundBull )
                    {
                        client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_NO_BULL")
                        break
                    }
                }
            }
        }

        iArgIndex ++
        szTarget[0] = EOS
        read_argv(iArgIndex, szTarget, charsmax(szTarget))
        remove_quotes(szTarget)
    }

    return PLUGIN_HANDLED
}

public cmdReload(id, iLevel, iCmd)
{
    if ( !cmd_access(id, iLevel, iCmd, 1) )
        return PLUGIN_HANDLED

    ReadFile()
    console_print(id, "The configuration file has been reloaded successfully !")

    return PLUGIN_HANDLED
}

public eventRoundStart()
{
    bullReset()
}

ReadFile()
{
    if ( g_bFileWasRead )
    {
        ArrayClear(g_aBullConfig)
        g_iBullConfig = 0
    }

    new szFile[MAX_RESOURCE_PATH_LENGTH], iFile
    get_configsdir(szFile, charsmax(szFile))
    add(szFile, charsmax(szFile), "/BrazenBull.ini")
    iFile = fopen(szFile, "rt")

    if ( !iFile )
    {
        set_fail_state("An error occured during the opening of the configuration file !")
    }

    new szData[MAX_FILE_CELL_SIZE],
        szKey[MAX_VALUE_LENGTH], szValue[MAX_VALUE_LENGTH],
        eBull[BULL], iSection = SECTION_NONE, iLine, iPos

    while( !feof(iFile) )
    {
        iLine ++
        fgets(iFile, szData, charsmax(szData))
        trim(szData)

        switch( szData[0] )
        {
            case EOS, ';', '#':
            {
                continue
            }
            case '[':
            {
                if ( szData[strlen(szData) - 1] == ']' )
                {
                    replace(szData, charsmax(szData), "[", "")
                    replace(szData, charsmax(szData), "]", "")
                    trim(szData)

                    if ( equali(szData, "Main Settings") )
                    {
                        iSection = SECTION_MAIN_SETTINGS
                    }
                    else
                    {
                        if ( g_iBullConfig )
                            ArrayPushArray(g_aBullConfig, eBull)

                        copy(eBull[BULL_NAME], charsmax(eBull[BULL_NAME]), szData)
                        copy(eBull[BULL_SPRITE_FIRE], charsmax(eBull[BULL_SPRITE_FIRE]), g_eSettings[SETTING_DEFAULT_SPRITE_FIRE])
                        xs_vec_copy(g_eSettings[SETTING_DEFAULT_FIRE_COLOR], eBull[BULL_FIRE_COLOR])
                        eBull[BULL_FLAGS]                       = g_eSettings[SETTING_DEFAULT_FLAGS]
                        eBull[BULL_TEAM]                        = g_eSettings[SETTING_DEFAULT_TEAM]
                        eBull[BULL_FRAMERATE]                   = g_eSettings[SETTING_DEFAULT_FRAMERATE]
                        eBull[BULL_COOLDOWN][0]                 = g_eSettings[SETTING_DEFAULT_COOLDOWN][0]
                        eBull[BULL_COOLDOWN][1]                 = g_eSettings[SETTING_DEFAULT_COOLDOWN][1]
                        eBull[BULL_FIRE_FRAMERATE]              = g_eSettings[SETTING_DEFAULT_FIRE_FRAMERATE]
                        eBull[BULL_FIRE_SCALE]                  = g_eSettings[SETTING_DEFAULT_FIRE_SCALE]
                        eBull[BULL_FIRE_ALPHA]                  = g_eSettings[SETTING_DEFAULT_FIRE_ALPHA]
                        eBull[BULL_DAMAGE][0]                   = g_eSettings[SETTING_DEFAULT_DAMAGE][0]
                        eBull[BULL_DAMAGE][1]                   = g_eSettings[SETTING_DEFAULT_DAMAGE][1]
                        eBull[BULL_DAMAGE_INTERVAL][0]          = g_eSettings[SETTING_DEFAULT_DAMAGE_INTERVAL][0]
                        eBull[BULL_DAMAGE_INTERVAL][1]          = g_eSettings[SETTING_DEFAULT_DAMAGE_INTERVAL][1]
                        eBull[BULL_DAMAGETYPE]                  = g_eSettings[SETTING_DEFAULT_DAMAGETYPE]

                        iSection = SECTION_BULL
                        g_iBullConfig ++
                    }
                }
                else
                {
                    LogConfigError(iLine, "Unclosed section name: %s", szData)
                    iSection = SECTION_NONE
                }
            }
            default:
            {
                strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
                iPos = contain(szValue, "#")
                if ( iPos != -1 )
                    szValue[iPos] = EOS

                trim(szKey)
                trim(szValue)

                switch( iSection )
                {
                    case SECTION_NONE:
                    {
                        LogConfigError(iLine, "Data is not in any defined section: %s", szData)
                    }
                    case SECTION_MAIN_SETTINGS:
                    {
                        if ( equali(szKey, "SETTING_DEFAULT_MODEL") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MODEL], charsmax(g_eSettings[SETTING_DEFAULT_MODEL]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SPRITE_FIRE") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SPRITE_FIRE], charsmax(g_eSettings[SETTING_DEFAULT_SPRITE_FIRE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND], charsmax(g_eSettings[SETTING_DEFAULT_SOUND]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_FIRE") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_FIRE], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_FIRE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_OPEN") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_OPEN], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_OPEN]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_CLOSE") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_CLOSE], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_CLOSE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SOUND_SCREAM") )
                            parseSetting(DTYPE_ARRAY_SOUND, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SOUND_SCREAM], charsmax(g_eSettings[SETTING_DEFAULT_SOUND_SCREAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_MESSAGE") )
                            parseSetting(DTYPE_ARRAY_MESSAGE, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MESSAGE], charsmax(g_eSettings[SETTING_DEFAULT_MESSAGE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_MESSAGE_FORCED") )
                            parseSetting(DTYPE_ARRAY_MESSAGE, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED], charsmax(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FLAGS], charsmax(g_eSettings[SETTING_DEFAULT_FLAGS]))
                        else if ( equali(szKey, "SETTING_DEFAULT_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_TEAM], charsmax(g_eSettings[SETTING_DEFAULT_TEAM]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_HOLD_DURATION") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_HOLD_DURATION], charsmax(g_eSettings[SETTING_DEFAULT_HOLD_DURATION]))
                        else if ( equali(szKey, "SETTING_DEFAULT_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_COOLDOWN], charsmax(g_eSettings[SETTING_DEFAULT_COOLDOWN]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FIRE_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FIRE_FRAMERATE], charsmax(g_eSettings[SETTING_DEFAULT_FIRE_FRAMERATE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FIRE_SCALE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FIRE_SCALE], charsmax(g_eSettings[SETTING_DEFAULT_FIRE_SCALE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FIRE_COLOR") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FIRE_COLOR], charsmax(g_eSettings[SETTING_DEFAULT_FIRE_COLOR]))
                        else if ( equali(szKey, "SETTING_DEFAULT_FIRE_ALPHA") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_FIRE_ALPHA], charsmax(g_eSettings[SETTING_DEFAULT_FIRE_ALPHA]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGE], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGE_INTERVAL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGE_INTERVAL], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGE_INTERVAL]))
                        else if ( equali(szKey, "SETTING_DEFAULT_DAMAGETYPE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_DAMAGETYPE], charsmax(g_eSettings[SETTING_DEFAULT_DAMAGETYPE]))
                        else if ( equali(szKey, "SETTING_DEFAULT_SCREAM_INTERVAL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_DEFAULT_SCREAM_INTERVAL], charsmax(g_eSettings[SETTING_DEFAULT_SCREAM_INTERVAL]))
                        else if ( equali(szKey, "SETTING_PLAY_SOUND_ON_DEATH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_PLAY_SOUND_ON_DEATH], charsmax(g_eSettings[SETTING_PLAY_SOUND_ON_DEATH]))
                        else if ( equali(szKey, "SETTING_WRITE_MESSAGE_ON_DEATH") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_WRITE_MESSAGE_ON_DEATH], charsmax(g_eSettings[SETTING_WRITE_MESSAGE_ON_DEATH]))
                        else if ( equali(szKey, "SETTING_KILL_ALL_EXCLUDE_CALLER") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_KILL_ALL_EXCLUDE_CALLER], charsmax(g_eSettings[SETTING_KILL_ALL_EXCLUDE_CALLER]))
                        else if ( equali(szKey, "SETTING_SET_CAMERA_ON_VICTIM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_SET_CAMERA_ON_VICTIM], charsmax(g_eSettings[SETTING_SET_CAMERA_ON_VICTIM]))
                        else if ( equali(szKey, "SETTING_HUD_X") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_X], charsmax(g_eSettings[SETTING_HUD_X]))
                        else if ( equali(szKey, "SETTING_HUD_Y") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_Y], charsmax(g_eSettings[SETTING_HUD_Y]))
                        else if ( equali(szKey, "SETTING_HUD_COLOR") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_COLOR], charsmax(g_eSettings[SETTING_HUD_COLOR]))
                        else if ( equali(szKey, "SETTING_HUD_EFFECT") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_EFFECT], charsmax(g_eSettings[SETTING_HUD_EFFECT]))
                        else if ( equali(szKey, "SETTING_HUD_FXTIME") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FXTIME], charsmax(g_eSettings[SETTING_HUD_FXTIME]))
                        else if ( equali(szKey, "SETTING_HUD_HOLDTIME") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_HOLDTIME], charsmax(g_eSettings[SETTING_HUD_HOLDTIME]))
                        else if ( equali(szKey, "SETTING_HUD_FADEIN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FADEIN], charsmax(g_eSettings[SETTING_HUD_FADEIN]))
                        else if ( equali(szKey, "SETTING_HUD_FADEOUT") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_HUD_FADEOUT], charsmax(g_eSettings[SETTING_HUD_FADEOUT]))
                        else if ( equali(szKey, "SETTING_MINS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MINS], charsmax(g_eSettings[SETTING_MINS]))
                        else if ( equali(szKey, "SETTING_MAXS") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_MAXS], charsmax(g_eSettings[SETTING_MAXS]))
                        else if ( equali(szKey, "SETTING_BULL_LOAD") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), g_eSettings[SETTING_BULL_LOAD], charsmax(g_eSettings[SETTING_BULL_LOAD]))
                        else if ( equali(szKey, "SETTING_BULL_TASK") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), g_eSettings[SETTING_BULL_TASK], charsmax(g_eSettings[SETTING_BULL_TASK]))
                    }
                    case SECTION_BULL:
                    {
                        if ( equali(szKey, "BULL_SPRITE_FIRE") )
                            parseSetting(DTYPE_STRING_MODEL, szValue, charsmax(szValue), eBull[BULL_SPRITE_FIRE], charsmax(eBull[BULL_SPRITE_FIRE]))
                        else if ( equali(szKey, "BULL_FLAGS") )
                            parseSetting(DTYPE_FLAGS, szValue, charsmax(szValue), eBull[BULL_FLAGS], charsmax(eBull[BULL_FLAGS]))
                        else if ( equali(szKey, "BULL_TEAM") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eBull[BULL_TEAM], charsmax(eBull[BULL_TEAM]))
                        else if ( equali(szKey, "BULL_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eBull[BULL_FRAMERATE], charsmax(eBull[BULL_FRAMERATE]))
                        else if ( equali(szKey, "BULL_COOLDOWN") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eBull[BULL_COOLDOWN], charsmax(eBull[BULL_COOLDOWN]))
                        else if ( equali(szKey, "BULL_FIRE_FRAMERATE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eBull[BULL_FIRE_FRAMERATE], charsmax(eBull[BULL_FIRE_FRAMERATE]))
                        else if ( equali(szKey, "BULL_FIRE_SCALE") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eBull[BULL_FIRE_SCALE], charsmax(eBull[BULL_FIRE_SCALE]))
                        else if ( equali(szKey, "BULL_FIRE_COLOR") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eBull[BULL_FIRE_COLOR], charsmax(eBull[BULL_FIRE_COLOR]))
                        else if ( equali(szKey, "BULL_FIRE_ALPHA") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eBull[BULL_FIRE_ALPHA], charsmax(eBull[BULL_FIRE_ALPHA]))
                        else if ( equali(szKey, "BULL_DAMAGE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eBull[BULL_DAMAGE], charsmax(eBull[BULL_DAMAGE]))
                        else if ( equali(szKey, "BULL_DAMAGE_INTERVAL") )
                            parseSetting(DTYPE_FLOAT, szValue, charsmax(szValue), eBull[BULL_DAMAGE_INTERVAL], charsmax(eBull[BULL_DAMAGE_INTERVAL]))
                        else if ( equali(szKey, "BULL_DAMAGETYPE") )
                            parseSetting(DTYPE_INT, szValue, charsmax(szValue), eBull[BULL_DAMAGETYPE], charsmax(eBull[BULL_DAMAGETYPE]))
                    }
                }
            }
        }
    }

    if ( g_iBullConfig )
        ArrayPushArray(g_aBullConfig, eBull)
    else
        set_fail_state("No Brazen Bulls were found in the configuration file.")

    g_bFileWasRead = true
    fclose(iFile)
}

public client_disconnected(id)
{
    new eBull[BULL], iItem
    if ( g_ePlayerData[id][PDATA_BULL_GHOST]
    && (iItem = bullGet(eBull, g_ePlayerData[id][PDATA_BULL_GHOST])) != -1 )
    {
        bullKill(eBull)
        bullRemove(iItem)
    }

    DisableAction(id)
    g_ePlayerData[id][PDATA_BULL_GHOST]  = 0
    g_ePlayerData[id][PDATA_BULL_MENU]   = 0
}

stock bullInit()
{
    g_iHudCurrentY = g_eSettings[SETTING_HUD_Y]
    if ( g_eSettings[SETTING_BULL_LOAD] )
        set_task(DELAY_ON_LOAD, "loadData")
}

stock bullMenu(id, iType)
{
    if ( !is_user_connected(id) )
        return PLUGIN_HANDLED

    new szData[256], iMenu
    formatex(szData, charsmax(szData), "%L", id, "BULL_MENU_TITLE", PLUGIN_VERSION)
    iMenu = menu_create(szData, g_szMenuHandler[iType])
    switch( iType )
    {
        case MENU_ROOT:             { menuRoot(id, iMenu); }
        case MENU_CREATE:           { menuCreate(iMenu);            format(szData, charsmax(szData), "%s^n%L", szData, id, "BULL_ROOT_CREATE"); }
        case MENU_EDIT:             { menuEdit(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "BULL_ROOT_EDIT"); }
        case MENU_REMOVE:           { menuRemove(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "BULL_ROOT_REMOVE"); }
        case MENU_SHOW:             { menuShow(id, iMenu);          format(szData, charsmax(szData), "%s^n%L", szData, id, "BULL_ROOT_SHOW"); }
        case MENU_STATUS:           { menuStatus(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "BULL_ROOT_STATUS"); }
        case MENU_ROTATE:           { menuRotate(id, iMenu);        format(szData, charsmax(szData), "%s^n%L", szData, id, "BULL_ROOT_ROTATE"); }
    }

    if ( menu_pages(iMenu) > 1 )
        format(szData, charsmax(szData), "%s^n%L", szData, id, "BULL_MENU_TITLE_PAGE")

    menu_setprop(iMenu, MPROP_TITLE, szData)
    menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
    menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")

    menu_display(id, iMenu)
    return PLUGIN_HANDLED
}

stock menuNav(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "BULL_NAV_NEXT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_NAV_BACK")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)
}

public menuRoot(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "BULL_ROOT_CREATE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_ROOT_EDIT")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_ROOT_REMOVE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_ROOT_SAVE")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_ROOT_NOCLIP", id, (pev(id, pev_movetype) == MOVETYPE_NOCLIP) ? "BULL_ON" : "BULL_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_ROOT_GODMODE", id, (pev(id, pev_takedamage) == DAMAGE_NO) ? "BULL_ON" : "BULL_OFF")
    menu_additem(iMenu, szItem)
}

public menuHandlerRoot(id, menu, item)
{
    if ( item == MENU_EXIT )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROOT_CREATE:
        {
            if ( g_iBull >= MAX_ENT )
            {
                client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_LIMIT", MAX_ENT)

                bullSound(id, SOUND_MENU_REMOVE)
                bullMenu(id, MENU_ROOT)
            }
            else
            {
                bullSound(id, SOUND_MENU_NAV)
                bullMenu(id, MENU_CREATE)
            }
        }
        case ROOT_EDIT:
        {
            if ( !g_iBull )
            {
                client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_NO_BULL")

                bullSound(id, SOUND_MENU_REMOVE)
                bullMenu(id, MENU_ROOT)
            }
            else
            {
                bullSound(id, SOUND_MENU_NAV)
                bullMenu(id, MENU_EDIT)
            }
        }
        case ROOT_REMOVE:
        {
            if ( !g_iBull )
            {
                client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_NO_BULL")

                bullSound(id, SOUND_MENU_REMOVE)
                bullMenu(id, MENU_ROOT)
            }
            else
            {
                bullSound(id, SOUND_MENU_REMOVE)
                bullMenu(id, MENU_REMOVE)
            }
        }
        case ROOT_SAVE:
        {
            saveData(id)
        }
        case ROOT_NOCLIP:
        {
            bullNoClip(id)
        }
        case ROOT_GODMODE:
        {
            bullGodMode(id)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuCreate(iMenu)
{
    new eBull[BULL], szItem[64]
    for ( new i = 0; i < g_iBullConfig; i ++ )
    {
        ArrayGetArray(g_aBullConfig, i, eBull)

        copy(szItem, charsmax(szItem), eBull[BULL_NAME])
        menu_additem(iMenu, szItem)
    }
}

public menuHandlerCreate(id, menu, item)
{
    if ( !is_user_alive(id) )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }
    else if ( item == MENU_EXIT )
    {
        bullSound(id, SOUND_MENU_NAV)
        bullMenu(id, MENU_ROOT)

        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    bullCreate(id, item)
    bullSound(id, SOUND_MENU_NAV)
    bullMenu(id, MENU_ROTATE)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuEdit(id, iMenu)
{
    new szItem[64]
    formatex(szItem, charsmax(szItem), "%L", id, "BULL_EDIT_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_EDIT_STATUS")
    menu_additem(iMenu, szItem)
}

public menuHandlerEdit(id, menu, item)
{
    switch( item )
    {
        case EDIT_SHOW:
        {
            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_SHOW)
        }
        case EDIT_STATUS:
        {
            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_ROOT)
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRemove(id, iMenu)
{
    new szItem[64], eBull[BULL]
    menuNav(id, iMenu)
    ArrayGetArray(g_aBull, g_ePlayerData[id][PDATA_BULL_MENU], eBull)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_REMOVE_CURRENT", eBull[BULL_NAME])
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_REMOVE_ALL")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    bullSelect(eBull, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_REMOVE
    ArraySetArray(g_aBull, g_ePlayerData[id][PDATA_BULL_MENU], eBull)
}

public menuHandlerRemove(id, menu, item)
{
    new eBull[BULL]
    ArrayGetArray(g_aBull, g_ePlayerData[id][PDATA_BULL_MENU], eBull)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        bullSelect(eBull, eBull[BULL_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case REMOVE_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_BULL_MENU] >= g_iBull - 1 )
                g_ePlayerData[id][PDATA_BULL_MENU] = 0
            else
                g_ePlayerData[id][PDATA_BULL_MENU] ++

            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_REMOVE)
        }
        case REMOVE_BACK:
        {
            if ( g_ePlayerData[id][PDATA_BULL_MENU] <= 0 )
                g_ePlayerData[id][PDATA_BULL_MENU] = g_iBull - 1
            else
                g_ePlayerData[id][PDATA_BULL_MENU] --

            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_REMOVE)
        }
        case REMOVE_CURRENT:
        {
            eBull[BULL_FLAGS] &= ~FLAG_ACTIVE
            bullSetState(eBull)
            bullKill(eBull)
            bullRemove(g_ePlayerData[id][PDATA_BULL_MENU])

            client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_REMOVE_CURRENT", eBull[BULL_NAME])
            g_ePlayerData[id][PDATA_BULL_MENU] = 0

            bullSound(id, g_iBull > 0 ? SOUND_MENU_REMOVE : SOUND_MENU_NAV)
            bullMenu(id, g_iBull > 0 ? MENU_REMOVE : MENU_ROOT)
        }
        case REMOVE_ALL:
        {
            while( g_iBull )
            {
                ArrayGetArray(g_aBull, 0, eBull)
                eBull[BULL_FLAGS] &= ~FLAG_ACTIVE

                bullSetState(eBull)
                bullKill(eBull)
                bullRemove(0)
            }

            client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_REMOVE_ALL")
            g_ePlayerData[id][PDATA_BULL_MENU] = 0

            bullSound(id, SOUND_MENU_ALERT)
            bullMenu(id, MENU_ROOT)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                bullSound(id, SOUND_MENU_NAV)
                bullMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_BULL_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_BULL_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuShow(id, iMenu)
{
    new szItem[64], eBull[BULL]
    menuNav(id, iMenu)
    ArrayGetArray(g_aBull, g_ePlayerData[id][PDATA_BULL_MENU], eBull)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_SHOW_CURRENT",
    eBull[BULL_FLAGS] & FLAG_SHOW ? "\y" : "\r", eBull[BULL_NAME], id, eBull[BULL_FLAGS] & FLAG_SHOW ? "BULL_SHOWN" : "BULL_HIDDEN")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_SHOW_ALL_SHOW")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_SHOW_ALL_HIDE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    bullSelect(eBull, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_SHOW
    ArraySetArray(g_aBull, g_ePlayerData[id][PDATA_BULL_MENU], eBull)
}

public menuHandlerShow(id, menu, item)
{
    new eBull[BULL]
    ArrayGetArray(g_aBull, g_ePlayerData[id][PDATA_BULL_MENU], eBull)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        bullSelect(eBull, eBull[BULL_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case SHOW_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_BULL_MENU] >= g_iBull - 1 )
                g_ePlayerData[id][PDATA_BULL_MENU] = 0
            else
                g_ePlayerData[id][PDATA_BULL_MENU] ++

            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_SHOW)
        }
        case SHOW_BACK:
        {
            if ( g_ePlayerData[id][PDATA_BULL_MENU] <= 0 )
                g_ePlayerData[id][PDATA_BULL_MENU] = g_iBull - 1
            else
                g_ePlayerData[id][PDATA_BULL_MENU] --

            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_SHOW)
        }
        case SHOW_CURRENT:
        {
            eBull[BULL_FLAGS] ^= FLAG_SHOW
            if ( eBull[BULL_FLAGS] & FLAG_SHOW )
                eBull[BULL_FLAGS] |= FLAG_ACTIVE
            else
                eBull[BULL_FLAGS] &= ~FLAG_ACTIVE
            bullSetState(eBull)

            client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_SHOW_CURRENT",
            eBull[BULL_NAME], id, eBull[BULL_FLAGS] & FLAG_SHOW ? "BULL_CHAT_SHOWN" : "BULL_CHAT_HIDDEN")
            ArraySetArray(g_aBull, g_ePlayerData[id][PDATA_BULL_MENU], eBull)

            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_SHOW:
        {
            for ( new i = 0; i < g_iBull; i ++ )
            {
                ArrayGetArray(g_aBull, i, eBull)
                eBull[BULL_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
                bullSetState(eBull)

                ArraySetArray(g_aBull, i, eBull)
            }

            client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_SHOW_ALL_SHOWN")
            bullSound(id, SOUND_MENU_ALERT)
            bullMenu(id, MENU_SHOW)
        }
        case SHOW_ALL_HIDE:
        {
            for ( new i = 0; i < g_iBull; i ++ )
            {
                ArrayGetArray(g_aBull, i, eBull)
                eBull[BULL_FLAGS] &= ~(FLAG_SHOW | FLAG_ACTIVE)
                bullSetState(eBull)

                ArraySetArray(g_aBull, i, eBull)
            }

            client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_SHOW_ALL_HIDDEN")
            bullSound(id, SOUND_MENU_ALERT)
            bullMenu(id, MENU_SHOW)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                bullSound(id, SOUND_MENU_NAV)
                bullMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_BULL_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_BULL_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuStatus(id, iMenu)
{
    new szItem[64], eBull[BULL]
    menuNav(id, iMenu)
    ArrayGetArray(g_aBull, g_ePlayerData[id][PDATA_BULL_MENU], eBull)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_STATUS_CURRENT",
    eBull[BULL_FLAGS] & FLAG_ACTIVE ? "\y" : "\r", eBull[BULL_NAME], id, eBull[BULL_FLAGS] & FLAG_ACTIVE ? "BULL_ENABLED" : "BULL_DISABLED")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_STATUS_ALL_ENABLE")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_STATUS_ALL_DISABLE")
    menu_additem(iMenu, szItem)

    EnableAction(id)
    bullSelect(eBull, TARGET_SELECT)
    g_ePlayerData[id][PDATA_MENU_TYPE] = MENU_STATUS
    ArraySetArray(g_aBull, g_ePlayerData[id][PDATA_BULL_MENU], eBull)
}

public menuHandlerStatus(id, menu, item)
{
    new eBull[BULL]
    ArrayGetArray(g_aBull, g_ePlayerData[id][PDATA_BULL_MENU], eBull)
    if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
        bullSelect(eBull, eBull[BULL_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

    switch( item )
    {
        case STATUS_NEXT:
        {
            if ( g_ePlayerData[id][PDATA_BULL_MENU] >= g_iBull - 1 )
                g_ePlayerData[id][PDATA_BULL_MENU] = 0
            else
                g_ePlayerData[id][PDATA_BULL_MENU] ++

            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_STATUS)
        }
        case STATUS_BACK:
        {
            if ( g_ePlayerData[id][PDATA_BULL_MENU] <= 0 )
                g_ePlayerData[id][PDATA_BULL_MENU] = g_iBull - 1
            else
                g_ePlayerData[id][PDATA_BULL_MENU] --

            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_STATUS)
        }
        case STATUS_CURRENT:
        {
            eBull[BULL_FLAGS] ^= FLAG_ACTIVE
            bullSetState(eBull)

            client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_STATUS_CURRENT",
            eBull[BULL_NAME], id, eBull[BULL_FLAGS] & FLAG_ACTIVE ? "BULL_CHAT_ENABLED" : "BULL_CHAT_DISABLED")
            ArraySetArray(g_aBull, g_ePlayerData[id][PDATA_BULL_MENU], eBull)

            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_ENABLE:
        {
            for ( new i = 0; i < g_iBull; i ++ )
            {
                ArrayGetArray(g_aBull, i, eBull)
                eBull[BULL_FLAGS] |= FLAG_ACTIVE
                bullSetState(eBull)

                ArraySetArray(g_aBull, i, eBull)
            }

            client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_STATUS_ALL_ENABLED")
            bullSound(id, SOUND_MENU_ALERT)
            bullMenu(id, MENU_STATUS)
        }
        case STATUS_ALL_DISABLE:
        {
            for ( new i = 0; i < g_iBull; i ++ )
            {
                ArrayGetArray(g_aBull, i, eBull)
                eBull[BULL_FLAGS] &= ~FLAG_ACTIVE
                bullSetState(eBull)

                ArraySetArray(g_aBull, i, eBull)
            }

            client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_STATUS_ALL_DISABLED")
            bullSound(id, SOUND_MENU_ALERT)
            bullMenu(id, MENU_STATUS)
        }
        case MENU_EXIT:
        {
            if ( !g_ePlayerData[id][PDATA_MENU_TRACE] )
            {
                bullSound(id, SOUND_MENU_NAV)
                bullMenu(id, MENU_ROOT)

                DisableAction(id)
                g_ePlayerData[id][PDATA_BULL_MENU] = 0
            }

            g_ePlayerData[id][PDATA_MENU_TRACE] = false
        }
        default:
        {
            DisableAction(id)
            g_ePlayerData[id][PDATA_BULL_MENU] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public menuRotate(id, iMenu)
{
    new szItem[64], eBull[BULL]
    if ( bullGet(eBull, g_ePlayerData[id][PDATA_BULL_GHOST]) == -1 )
    {
        menu_destroy(iMenu)
        return
    }

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_ROTATE_UP")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_ROTATE_DOWN")
    menu_additem(iMenu, szItem)

    menu_addblank2(iMenu)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_ROTATE_GROUND",
    id, eBull[BULL_FLAGS] & FLAG_GROUND ? "BULL_ON" : "BULL_OFF")
    menu_additem(iMenu, szItem)

    formatex(szItem, charsmax(szItem), "%L", id, "BULL_ROTATE_PLACE")
    menu_additem(iMenu, szItem)
}

public menuHandlerRotate(id, menu, item)
{
    new eBull[BULL], iItem
    if ( (iItem = bullGet(eBull, g_ePlayerData[id][PDATA_BULL_GHOST])) == -1 )
    {
        menu_destroy(menu)
        return PLUGIN_HANDLED
    }

    switch( item )
    {
        case ROTATE_UP:
        {
            pev(eBull[BULL_ID], pev_angles, eBull[BULL_ANGLES])
            eBull[BULL_ANGLES][1] -= BULL_ROTATION_STEP
            if ( eBull[BULL_ANGLES][1] < -180.0 ) eBull[BULL_ANGLES][1] += 360.0

            set_pev(eBull[BULL_ID], pev_angles, eBull[BULL_ANGLES])
            ArraySetArray(g_aBull, iItem, eBull)

            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_ROTATE)
        }
        case ROTATE_DOWN:
        {
            pev(eBull[BULL_ID], pev_angles, eBull[BULL_ANGLES])
            eBull[BULL_ANGLES][1] += BULL_ROTATION_STEP
            if ( eBull[BULL_ANGLES][1] > 180.0 ) eBull[BULL_ANGLES][1] -= 360.0

            set_pev(eBull[BULL_ID], pev_angles, eBull[BULL_ANGLES])
            ArraySetArray(g_aBull, iItem, eBull)

            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_ROTATE)
        }
        case ROTATE_GROUND:
        {
            eBull[BULL_FLAGS] ^= FLAG_GROUND
            ArraySetArray(g_aBull, iItem, eBull)

            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_ROTATE)
        }
        case ROTATE_PLACE:
        {
            bullTrace(eBull, id)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_BULL_GHOST] = 0

            eBull[BULL_FLAGS] &= ~FLAG_GHOST
            eBull[BULL_FLAGS] |= (FLAG_SHOW | FLAG_ACTIVE)
            eBull[BULL_ANGLES][0] = -eBull[BULL_ANGLES][0]
            bullSetSize(eBull)
            bullSetState(eBull)
            client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_CREATE_NEW", eBull[BULL_NAME])

            ArraySetArray(g_aBull, iItem, eBull)
            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_CREATE)
        }
        case MENU_EXIT:
        {
            bullKill(eBull)
            bullRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_BULL_GHOST] = 0

            bullSound(id, SOUND_MENU_NAV)
            bullMenu(id, MENU_CREATE)
        }
        default:
        {
            bullKill(eBull)
            bullRemove(iItem)
            DisableAction(id)
            set_pdata_float(id, PDATA_NEXT_ATTACK, 0.0, XO_CBASEPLAYER, XO_CBASEPLAYER)
            g_ePlayerData[id][PDATA_BULL_GHOST] = 0
        }
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public bullTask()
{
    new eBull[BULL], iItem, Float:fCurrentTime
    fCurrentTime = get_gametime()

    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        if ( g_ePlayerData[id][PDATA_NEXT_BULL] )
        {
            if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_BULL] )
            {
                if ( (iItem = bullGet(eBull, g_ePlayerData[id][PDATA_BULL_ID])) != -1 )
                {
                    g_ePlayerData[id][PDATA_BULL_ID] = 0
                    g_ePlayerData[id][PDATA_NEXT_BULL] = 0.0

                    bullBull(eBull, id)
                    ArraySetArray(g_aBull, iItem, eBull)
                }
            }
            else if ( fCurrentTime - g_ePlayerData[id][PDATA_NEXT_CHECK] > 0.1 )
            {
                bullBar(id, 0)
                g_ePlayerData[id][PDATA_BULL_ID] = 0
                g_ePlayerData[id][PDATA_NEXT_BULL] = 0.0
            }
        }
        else if ( g_ePlayerData[id][PDATA_NEXT_CLOSE] )
        {
            if ( fCurrentTime >= g_ePlayerData[id][PDATA_NEXT_CLOSE] )
            {
                if ( (iItem = bullGet(eBull, g_ePlayerData[id][PDATA_BULL_ID])) != -1 )
                {
                    if ( eBull[BULL_FLAGS] & FLAG_USED && is_user_alive(id) )
                    {
                        g_ePlayerData[id][PDATA_BULL_LOCKED] = true
                        g_ePlayerData[id][PDATA_BULL_DAMAGE][0] = eBull[BULL_DAMAGE][0]
                        g_ePlayerData[id][PDATA_BULL_DAMAGE][1] = eBull[BULL_DAMAGE][1]
                        g_ePlayerData[id][PDATA_BULL_DAMAGE_INTERVAL][0] = eBull[BULL_DAMAGE_INTERVAL][0]
                        g_ePlayerData[id][PDATA_BULL_DAMAGE_INTERVAL][1] = eBull[BULL_DAMAGE_INTERVAL][1]
                        g_ePlayerData[id][PDATA_BULL_DAMAGETYPE] = eBull[BULL_DAMAGETYPE]
                        set_pev(id, pev_effects, pev(id, pev_effects) | EF_NODRAW)
                        set_pev(eBull[BULL_FIRE], pev_renderamt, eBull[BULL_FIRE_ALPHA])
                        bullSound(eBull[BULL_ID], SOUND_FIRE, false, CHAN_VOICE)

                        set_task(random_float(eBull[BULL_DAMAGE_INTERVAL][0], eBull[BULL_DAMAGE_INTERVAL][1]), "bullDamage", id + BULL_LOCKED_KEY)
                    }

                    g_ePlayerData[id][PDATA_NEXT_CLOSE] = 0.0
                    bullSetSeq(eBull[BULL_ID], BULL_SEQ_CLOSED, eBull[BULL_FRAMERATE])
                    bullSound(eBull[BULL_ID], SOUND_CLOSE, false)
                    ArraySetArray(g_aBull, iItem, eBull)
                }
            }
        }
    }

    for ( new i = 0; i < g_iBull; i ++ )
    {
        ArrayGetArray(g_aBull, i, eBull)

        if ( eBull[BULL_NEXT_ACTIVE]
        && fCurrentTime >= eBull[BULL_NEXT_ACTIVE] )
        {
            bullSound(eBull[BULL_ID], SOUND_OPEN, false)
            bullSetSeq(eBull[BULL_ID], BULL_SEQ_OPEN, eBull[BULL_FRAMERATE])
            eBull[BULL_NEXT_ACTIVE] = 0.0
            eBull[BULL_NEXT_OPEN] = fCurrentTime + (BULL_DURATION_OPEN / eBull[BULL_FRAMERATE])

            ArraySetArray(g_aBull, i, eBull)
        }
        else if ( eBull[BULL_NEXT_OPEN]
        && fCurrentTime >= eBull[BULL_NEXT_OPEN] )
        {
            eBull[BULL_FLAGS] &= ~FLAG_USED
            bullSetSeq(eBull[BULL_ID], BULL_SEQ_OPENED, eBull[BULL_FRAMERATE])
            eBull[BULL_NEXT_OPEN] = 0.0

            ArraySetArray(g_aBull, i, eBull)
        }
    }
}

stock bullCreate(id, iItem)
{
    new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iEnt) )
        return

    new eBull[BULL]
    ArrayGetArray(g_aBullConfig, iItem, eBull)
    eBull[BULL_ID] = iEnt
    eBull[BULL_ITEM] = iItem
    if ( id )
    {
        EnableAction(id)
        g_ePlayerData[id][PDATA_BULL_GHOST] = eBull[BULL_ID]
        g_ePlayerData[id][PDATA_OFFSET] = BULL_OFFSET_BASE

        eBull[BULL_FLAGS] |= FLAG_GHOST
    }

    bullSelect(eBull, TARGET_GHOST)
    set_pev(iEnt, pev_classname, g_szCN)
    set_pev(iEnt, pev_impulse, BULL_KEY)
    set_pev(iEnt, BULL_ARRAY_ITEM, g_iBull)
    dllfunc(DLLFunc_Spawn, iEnt)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
    engfunc(EngFunc_SetModel, iEnt, g_eSettings[SETTING_DEFAULT_MODEL])

    ArrayPushArray(g_aBull, eBull)
    if ( ++ g_iBull == 1 )
    {
        set_task(g_eSettings[SETTING_BULL_TASK], "bullTask", BULL_KEY, .flags = "b")
        EnableBull()
    }
}

stock bullCreateView(eBull[BULL])
{
    new Float:fOrigin[3], Float:fAngles[3], Float:fRight[3], Float:fForward[3], Float:fDirection[3], Float:fFrac
    engfunc(EngFunc_AngleVectors, eBull[BULL_ANGLES], fForward, fRight, NULL_VECTOR)

    xs_vec_copy(eBull[BULL_ORIGIN], fOrigin)
    xs_vec_mul_scalar(fRight, VIEW_FORWARD_OFFSET, fRight)
    xs_vec_mul_scalar(fForward, -VIEW_RIGHT_OFFSET, fForward)
    xs_vec_add(fOrigin, fRight, fOrigin)
    xs_vec_add(fOrigin, fForward, fOrigin)
    fOrigin[2] += VIEW_UP_OFFSET

    engfunc(EngFunc_TraceLine, eBull[BULL_ORIGIN], fOrigin, IGNORE_MONSTERS, eBull[BULL_ID], 0)
    get_tr2(0, TR_flFraction, fFrac)
    if ( fFrac < 1.0 )
        get_tr2(0, TR_vecEndPos, fOrigin)

    fOrigin[2] -= VIEW_UP_OFFSET
    xs_vec_sub(eBull[BULL_ORIGIN], fOrigin, fDirection)
    engfunc(EngFunc_VecToAngles, fDirection, fAngles)

    new iView = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
    if ( !pev_valid(iView) )
        return

    new szCN[32]
    formatex(szCN, charsmax(szCN), "%s_view", g_szCN)
    set_pev(iView, pev_classname, szCN)
    set_pev(iView, pev_movetype, MOVETYPE_NONE)
    set_pev(iView, pev_solid, SOLID_NOT)
    engfunc(EngFunc_SetModel, iView, g_szModelRPG)
    set_pev(iView, pev_rendermode, kRenderTransTexture)
    set_pev(iView, pev_renderamt, 0.0)
    engfunc(EngFunc_SetOrigin, iView, fOrigin)
    set_pev(iView, pev_angles, fAngles)

    eBull[BULL_VIEW] = iView
}

stock bullCreateFire(eBull[BULL])
{
    new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
    if ( !pev_valid(iEnt) )
        return

    new Float:fOrigin[3], szCN[32]
    formatex(szCN, charsmax(szCN), "%s_fire", g_szCN)
    engfunc(EngFunc_GetAttachment, eBull[BULL_ID], 0, fOrigin, NULL_VECTOR)
    xs_vec_add(fOrigin, g_fFireOffset, fOrigin)
    set_pev(iEnt, pev_classname, szCN)
    set_pev(iEnt, pev_framerate, eBull[BULL_FIRE_FRAMERATE])
    set_pev(iEnt, pev_spawnflags, SF_SPRITE_STARTON)
    engfunc(EngFunc_SetModel, iEnt, eBull[BULL_SPRITE_FIRE])
    dllfunc(DLLFunc_Spawn, iEnt)

    engfunc(EngFunc_SetOrigin, iEnt, fOrigin)
    set_pev(iEnt, pev_solid, SOLID_NOT)
    set_pev(iEnt, pev_movetype, MOVETYPE_NONE)
    set_pev(iEnt, pev_scale, eBull[BULL_FIRE_SCALE])

    set_pev(iEnt, pev_rendermode, kRenderTransAdd)
    set_pev(iEnt, pev_rendercolor, eBull[BULL_FIRE_COLOR])
    set_pev(iEnt, pev_renderfx, kRenderFxNone)
    set_pev(iEnt, pev_renderamt, 0.0)
    eBull[BULL_FIRE] = iEnt
}

public bullRemove(iItem)
{
    new eBull[BULL]
    ArrayDeleteItem(g_aBull, iItem)

    if ( -- g_iBull == 0 )
    {
        remove_task(BULL_KEY)
        DisableBull()
    }

    for ( new i = iItem; i < g_iBull; i ++ )
    {
        ArrayGetArray(g_aBull, i, eBull)
        set_pev(eBull[BULL_ID], BULL_ARRAY_ITEM, i)
    }
}

public saveData(id)
{
    new eBull[BULL],
        szFile[128], iFile,
        szData[64]

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_BrazenBull.ini", szFile)

    iFile = fopen(szFile, "wt")
    if ( !iFile )
        return PLUGIN_HANDLED

    for ( new i = 0; i < g_iBull; i ++ )
    {
        ArrayGetArray(g_aBull, i, eBull)

        formatex(szData, charsmax(szData), "[%d]^n", i)
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "item = %d^n", eBull[BULL_ITEM])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "flags = %d^n", eBull[BULL_FLAGS])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "origin = %.2f %.2f %.2f^n",
        eBull[BULL_ORIGIN][0], eBull[BULL_ORIGIN][1], eBull[BULL_ORIGIN][2])
        fputs(iFile, szData)

        formatex(szData, charsmax(szData), "angles = %.2f %.2f %.2f^n",
        eBull[BULL_ANGLES][0], eBull[BULL_ANGLES][1], eBull[BULL_ANGLES][2])
        fputs(iFile, szData)
    }

    client_print_color(id, id, "%L %L", id, "BULL_CHAT_TAG", id, "BULL_CHAT_SAVE", szFile)
    fclose(iFile)

    bullSound(id, SOUND_MENU_NAV)
    bullMenu(id, MENU_ROOT)
    return PLUGIN_HANDLED
}

public loadData()
{
    new szFile[128], iFile,
        szData[64], szKey[32], szValue[32],
        Float:fOrigin[3], Float:fAngles[3], iItem, iFlags, iCount = -1

    get_mapname(szFile, charsmax(szFile))
    format(szFile, charsmax(szFile), "maps/%s_BrazenBull.ini", szFile)
    iFile = fopen(szFile, "rt")
    if ( !iFile )
        return

    while( !feof(iFile) )
    {
        fgets(iFile, szData, charsmax(szData))

        if ( szData[0] == '[' )
        {
            if ( iCount != -1 )
                LoadDataBull(iItem, iFlags, fOrigin, fAngles, iCount)

            iCount ++
        }
        else
        {
            strtok(szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=')
            trim(szKey)
            trim(szValue)

            if ( equal(szKey, "item") )
            {
                iItem = str_to_num(szValue)
            }
            else if ( equal(szKey, "flags") )
            {
                iFlags = str_to_num(szValue)
            }
            else if ( equal(szKey, "origin") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fOrigin[1] = str_to_float(szKey)
                fOrigin[2] = str_to_float(szValue)
            }
            else if ( equal(szKey, "angles") )
            {
                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[0] = str_to_float(szKey)

                strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ' ')
                fAngles[1] = str_to_float(szKey)
                fAngles[2] = str_to_float(szValue)
            }
        }
    }

    if ( iCount != -1 )
        LoadDataBull(iItem, iFlags, fOrigin, fAngles, iCount)

    fclose(iFile)
}

stock LoadDataBull(iItem, iFlags, Float:fOrigin[3], Float:fAngles[3], iCount)
{
    new eBull[BULL]
    bullCreate(0, iItem)
    ArrayGetArray(g_aBull, iCount, eBull)

    eBull[BULL_FLAGS] = iFlags
    fAngles[0] = -fAngles[0]
    xs_vec_copy(fOrigin, eBull[BULL_ORIGIN])
    xs_vec_copy(fAngles, eBull[BULL_ANGLES])

    bullSetBox(eBull)
    bullSetSize(eBull)
    bullSetState(eBull)
    ArraySetArray(g_aBull, iCount, eBull)
}

public bullNoClip(id)
{
    set_pev(id, pev_movetype, pev(id, pev_movetype) == MOVETYPE_NOCLIP ? MOVETYPE_WALK : MOVETYPE_NOCLIP)

    bullSound(id, SOUND_MENU_NAV)
    bullMenu(id, MENU_ROOT)
}

public bullGodMode(id)
{
    new Float:flTakeDamage
    pev(id, pev_takedamage, flTakeDamage)
    set_pev(id, pev_takedamage, flTakeDamage == DAMAGE_NO ? DAMAGE_AIM : DAMAGE_NO)

    bullSound(id, SOUND_MENU_NAV)
    bullMenu(id, MENU_ROOT)
}

public fwdEmitSound(iEnt, iChannel, const szSample[])
{
    if ( is_user_connected(iEnt) && g_ePlayerData[iEnt][PDATA_BULL_LOCKED] )
        return FMRES_SUPERCEDE

    return FMRES_IGNORED
}

public fwdUse(iEnt, iCaller, iActivator, iType, Float:fValue)
{
    if ( !isBull(iEnt)
    || !is_user_alive(iActivator) )
        return HAM_IGNORED

    new eBull[BULL]
    if ( bullGet(eBull, iEnt) == -1 )
        return HAM_IGNORED

    new Float:fCurrentTime = get_gametime()
    if ( !(eBull[BULL_FLAGS] & FLAG_ACTIVE)
    || (eBull[BULL_FLAGS] & FLAG_USED)
    || !(eBull[BULL_TEAM] & get_user_team(iActivator))
    || fCurrentTime < eBull[BULL_NEXT_ACTIVE] )
        return HAM_IGNORED

    g_ePlayerData[iActivator][PDATA_NEXT_CHECK] = fCurrentTime
    if ( !g_ePlayerData[iActivator][PDATA_NEXT_BULL] )
    {
        new iDuration
        iDuration = random_num(g_eSettings[SETTING_DEFAULT_HOLD_DURATION][0], g_eSettings[SETTING_DEFAULT_HOLD_DURATION][1])

        bullBar(iActivator, iDuration)
        g_ePlayerData[iActivator][PDATA_BULL_ID] = iEnt
        g_ePlayerData[iActivator][PDATA_NEXT_BULL] = fCurrentTime + iDuration
    }
    else if ( !fValue )
    {
        bullBar(iActivator, 0)
        g_ePlayerData[iActivator][PDATA_BULL_ID] = 0
        g_ePlayerData[iActivator][PDATA_NEXT_BULL] = 0.0
    }

    return HAM_IGNORED
}

public fwdObjectCaps(iEnt)
{
    if ( !isBull(iEnt) )
        return GetHamReturnStatus() == HAM_SUPERCEDE ? HAM_SUPERCEDE : HAM_IGNORED

    SetHamReturnInteger(FCAP_CONTINUOUS_USE | FCAP_ONOFF_USE)
    return HAM_SUPERCEDE
}

public fwdPostThink(id)
{
    if ( !is_user_alive(id)
    || !g_ePlayerData[id][PDATA_BULL_HELD] )
        return FMRES_IGNORED

    set_pev(id, pev_sequence, SEQ)
    set_pev(id, pev_gaitsequence, SEQ)
    set_pev(id, pev_framerate, 1.0)
    return FMRES_IGNORED
}

public fwdPreThink(id)
{
    if ( !is_user_alive(id) )
        return HAM_IGNORED

    static eBull[BULL], iButton, Float:fCurrentTime
    iButton = pev(id, pev_button)
    fCurrentTime = get_gametime()

    if ( bullGet(eBull, g_ePlayerData[id][PDATA_BULL_GHOST]) != -1 )
    {
        if ( g_ePlayerData[id][PDATA_BULL_GHOST] )
        {
            if ( fCurrentTime > g_ePlayerData[id][PDATA_NEXT_OFFSET] )
            {
                if ( iButton & IN_ATTACK )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      += BULL_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], BULL_OFFSET_MIN, BULL_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
                else if ( iButton & IN_ATTACK2 )
                {
                    g_ePlayerData[id][PDATA_OFFSET]      -= BULL_OFFSET_STEP
                    g_ePlayerData[id][PDATA_OFFSET]      = floatclamp(g_ePlayerData[id][PDATA_OFFSET], BULL_OFFSET_MIN, BULL_OFFSET_MAX)
                    g_ePlayerData[id][PDATA_NEXT_OFFSET] = fCurrentTime + 0.1
                }
            }

            set_pdata_float(id, PDATA_NEXT_ATTACK, fCurrentTime + 0.1, XO_CBASEPLAYER, XO_CBASEPLAYER)
            iButton &= ~(IN_ATTACK | IN_ATTACK2)
            set_pev(id, pev_button, iButton)

            bullTrace(eBull, id)
        }
    }
    else if ( g_ePlayerData[id][PDATA_BULL_ACTION] )
    {
        bullCheck(id)
    }

    return HAM_IGNORED
}

public fwdKilled(id, iAttacker, bGib)
{
    DisableAction(id)
    g_ePlayerData[id][PDATA_BULL_MENU] = 0
    if ( g_ePlayerData[id][PDATA_BULL_GHOST] )
    {
        new eBull[BULL], iItem
        if ( (iItem = bullGet(eBull, g_ePlayerData[id][PDATA_BULL_GHOST])) != -1 )
        {
            bullKill(eBull)
            bullRemove(iItem)
        }

        g_ePlayerData[id][PDATA_BULL_GHOST] = 0
    }

    if ( g_ePlayerData[id][PDATA_BULL_LOCKED] )
        set_pev(id, pev_deadflag, DEAD_DISCARDBODY)
}

stock bullTrace(eBull[BULL], id)
{
    new Float:fVec1[3]
    pev(id, pev_origin, eBull[BULL_ORIGIN])
    pev(id, pev_v_angle, fVec1)
    engfunc(EngFunc_MakeVectors, fVec1)
    global_get(glb_v_forward, fVec1)

    xs_vec_mul_scalar(fVec1, g_ePlayerData[id][PDATA_OFFSET], fVec1)
    xs_vec_add(fVec1, eBull[BULL_ORIGIN], fVec1)

    engfunc(EngFunc_TraceLine, eBull[BULL_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, id, 0)
    get_tr2(0, TR_vecEndPos, eBull[BULL_ORIGIN])

    bullSetBox(eBull)
    bullSetOffset(eBull)
    set_pev(eBull[BULL_ID], pev_origin, eBull[BULL_ORIGIN])
}

stock bullCheck(id)
{
    new eBull[BULL], Float:fVec1[3], Float:fVec2[3], Float:fVec3[3], Float:fMins[3], Float:fMaxs[3], Float:fNearest[3]
    new iBest, Float:fBestDist, Float:fDot, Float:fDist

    pev(id, pev_origin, fVec1)
    pev(id, pev_view_ofs, fVec2)
    xs_vec_add(fVec1, fVec2, fVec1)

    pev(id, pev_v_angle, fVec2)
    engfunc(EngFunc_MakeVectors, fVec2)
    global_get(glb_v_forward, fVec2)

    iBest = -1
    fBestDist = BULL_CHECK
    for ( new i = 0; i < g_iBull; i ++ )
    {
        ArrayGetArray(g_aBull, i, eBull)
        xs_vec_sub(eBull[BULL_ORIGIN], fVec1, fVec3)
        fDot = xs_vec_dot(fVec2, fVec3)

        if ( fDot < 0.0 )
            continue

        pev(eBull[BULL_ID], pev_absmin, fMins)
        pev(eBull[BULL_ID], pev_absmax, fMaxs)
        xs_vec_mul_scalar(fVec2, fDot, fVec3)
        xs_vec_add(fVec3, fVec1, fVec3)

        fNearest[0] = floatclamp(fVec3[0], fMins[0], fMaxs[0])
        fNearest[1] = floatclamp(fVec3[1], fMins[1], fMaxs[1])
        fNearest[2] = floatclamp(fVec3[2], fMins[2], fMaxs[2])
        fDist = get_distance_f(fVec3, fNearest)
        if ( fDist < fBestDist )
        {
            fBestDist = fDist
            iBest = i
        }
    }

    if ( iBest != -1
    && g_ePlayerData[id][PDATA_BULL_MENU] != iBest )
    {
        ArrayGetArray(g_aBull, g_ePlayerData[id][PDATA_BULL_MENU], eBull)
        bullSelect(eBull, eBull[BULL_FLAGS] & FLAG_SHOW ? TARGET_CLEAR : TARGET_GHOST)

        g_ePlayerData[id][PDATA_MENU_TRACE] = true
        g_ePlayerData[id][PDATA_BULL_MENU] = iBest
        bullMenu(id, g_ePlayerData[id][PDATA_MENU_TYPE])
    }
}

stock bullSetBox(eBull[BULL])
{
    new Float:fMins[3], Float:fMaxs[3],
        Float:fForward[3], Float:fRight[3], Float:fUp[3],
        Float:fCorners[8][3]

    eBull[BULL_ANGLES][0] = -eBull[BULL_ANGLES][0]
    engfunc(EngFunc_AngleVectors, eBull[BULL_ANGLES], fForward, fRight, fUp)
    xs_vec_copy(g_eSettings[SETTING_MINS], fMins)
    xs_vec_copy(g_eSettings[SETTING_MAXS], fMaxs)

    for ( new i = 0; i < 8; i ++ )
    {
        fCorners[i][0] = (i & 1) ? fMaxs[0] : fMins[0]
        fCorners[i][1] = (i & 2) ? fMaxs[1] : fMins[1]
        fCorners[i][2] = (i & 4) ? fMaxs[2] : fMins[2]

        boxRotate(fCorners[i], fForward, fRight, fUp)
    }

    xs_vec_copy(fCorners[0], fMins)
    xs_vec_copy(fCorners[0], fMaxs)
    for ( new i = 1; i < 8; i ++ )
    {
        fMins[0] = floatmin(fMins[0], fCorners[i][0])
        fMins[1] = floatmin(fMins[1], fCorners[i][1])
        fMins[2] = floatmin(fMins[2], fCorners[i][2])

        fMaxs[0] = floatmax(fMaxs[0], fCorners[i][0])
        fMaxs[1] = floatmax(fMaxs[1], fCorners[i][1])
        fMaxs[2] = floatmax(fMaxs[2], fCorners[i][2])
    }

    xs_vec_copy(fMins, eBull[BULL_MINS])
    xs_vec_copy(fMaxs, eBull[BULL_MAXS])
}

stock boxRotate(Float:fLocal[3], Float:fForward[3], Float:fRight[3], Float:fUp[3])
{
    new Float:fOut[3]
    fOut[0] = fLocal[0] * fForward[0] - fLocal[1] * fRight[0] + fLocal[2] * fUp[0]
    fOut[1] = fLocal[0] * fForward[1] - fLocal[1] * fRight[1] + fLocal[2] * fUp[1]
    fOut[2] = fLocal[0] * fForward[2] - fLocal[1] * fRight[2] + fLocal[2] * fUp[2]

    xs_vec_copy(fOut, fLocal)
}

stock bullSetOffset(eBull[BULL])
{
    new Float:fGaps[6], Float:fVec1[3], Float:fCurrentGap
    fGaps[0] = -eBull[BULL_MINS][0]
    fGaps[1] = eBull[BULL_MAXS][0]
    fGaps[2] = -eBull[BULL_MINS][1]
    fGaps[3] = eBull[BULL_MAXS][1]
    fGaps[4] = -eBull[BULL_MINS][2]
    fGaps[5] = eBull[BULL_MAXS][2]

    if ( eBull[BULL_FLAGS] & FLAG_GROUND )
    {
        xs_vec_sub(eBull[BULL_ORIGIN], Float:{0.0, 0.0, 9999.9}, fVec1)
        engfunc(EngFunc_TraceLine, eBull[BULL_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eBull[BULL_ID], 0)
        get_tr2(0, TR_vecEndPos, eBull[BULL_ORIGIN])
    }

    for ( new i = 5; i >= 0; i -- )
    {
        xs_vec_mul_scalar(g_fDirections[i], 9999.9, fVec1)
        xs_vec_add(fVec1, eBull[BULL_ORIGIN], fVec1)
        engfunc(EngFunc_TraceLine, eBull[BULL_ORIGIN], fVec1, DONT_IGNORE_MONSTERS, eBull[BULL_ID], 0)
        get_tr2(0, TR_vecEndPos, fVec1)
        fCurrentGap = xs_vec_distance(eBull[BULL_ORIGIN], fVec1)

        if ( fCurrentGap < fGaps[i] )
        {
            get_tr2(0, TR_vecPlaneNormal, fVec1)
            xs_vec_mul_scalar(fVec1, fGaps[i] - fCurrentGap, fVec1)
            xs_vec_add(eBull[BULL_ORIGIN], fVec1, eBull[BULL_ORIGIN])
        }
    }
}

stock bullSetSeq(iEnt, iSeq, Float:fFramerate)
{
    set_pev(iEnt, pev_sequence, iSeq)
    set_pev(iEnt, pev_frame, 0.0)
    set_pev(iEnt, pev_framerate, fFramerate)
    set_pev(iEnt, pev_animtime, get_gametime())
}

stock bullSetSize(eBull[BULL])
{
    bullSelect(eBull, TARGET_CLEAR)
    engfunc(EngFunc_SetOrigin, eBull[BULL_ID], eBull[BULL_ORIGIN])
    set_pev(eBull[BULL_ID], pev_angles, eBull[BULL_ANGLES])
    set_pev(eBull[BULL_ID], pev_solid, eBull[BULL_FLAGS] & FLAG_SHOW ? SOLID_BBOX : SOLID_NOT)
    set_pev(eBull[BULL_ID], pev_movetype, MOVETYPE_NONE)

    engfunc(EngFunc_SetSize, eBull[BULL_ID], eBull[BULL_MINS], eBull[BULL_MAXS])
    bullCreateView(eBull)
    bullCreateFire(eBull)
}

stock bullSetState(eBull[BULL])
{
    if ( eBull[BULL_FLAGS] & FLAG_SHOW )
    {
        set_pev(eBull[BULL_ID], pev_solid, SOLID_BBOX)
        bullSelect(eBull, TARGET_CLEAR)
    }
    else
    {
        set_pev(eBull[BULL_ID], pev_solid, SOLID_NOT)
        bullSelect(eBull, TARGET_HIDE)
    }
}

stock bullStrip(id)
{
    new iWeapons[32], iNum, szName[32], iEnt
    get_user_weapons(id, iWeapons, iNum)
    for ( new i; i < iNum; i ++ )
    {
        if ( !get_weaponname(iWeapons[i], szName, charsmax(szName)) )
            continue

        iEnt = -1
        while ( (iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", szName)) > 0 )
        {
            if ( pev(iEnt, pev_owner) != id )
                continue

            ExecuteHam(Ham_RemovePlayerItem, id, iEnt)
            user_has_weapon(id, iWeapons[i], 0)
            ExecuteHamB(Ham_Item_Kill, iEnt)
            break
        }
    }
}

stock bullOffset(eBull[BULL], id)
{
    new Float:fAng[3], Float:fFwd[3], Float:fRight[3], Float:fOrigin[3]
    xs_vec_copy(eBull[BULL_ANGLES], fAng)
    fAng[0] = 0.0
    fAng[2] = 0.0
    fAng[1] -= 90.0
    if ( fAng[1] <= -180.0 )
        fAng[1] += 360.0
    engfunc(EngFunc_AngleVectors, fAng, fFwd, fRight, NULL_VECTOR)

    xs_vec_copy(eBull[BULL_ORIGIN], fOrigin)
    xs_vec_add_scaled(fOrigin, fFwd, g_fPlayerOffset[0], fOrigin)
    xs_vec_add_scaled(fOrigin, fRight, g_fPlayerOffset[1], fOrigin)
    fOrigin[2] += g_fPlayerOffset[2]

    engfunc(EngFunc_SetOrigin, id, fOrigin)
    set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
    set_pev(id, pev_angles, fAng)
    set_pev(id, pev_v_angle, fAng)
    set_pev(id, pev_fixangle, 1)
}

stock bullBull(eBull[BULL], id, bool:bForced = false)
{
    if ( !pev_valid(eBull[BULL_VIEW]) )
        return

    bullStrip(id)
    bullOffset(eBull, id)
    bullSetSeq(eBull[BULL_ID], BULL_SEQ_CLOSE, eBull[BULL_FRAMERATE])
    bullSound(eBull[BULL_ID], SOUND_OPEN, false)
    eBull[BULL_FLAGS] |= FLAG_USED
    eBull[BULL_NEXT_OPEN] = 0.0
    g_ePlayerData[id][PDATA_BULL_ID] = eBull[BULL_ID]
    g_ePlayerData[id][PDATA_NEXT_CLOSE] = get_gametime() + (BULL_DURATION_CLOSE / eBull[BULL_FRAMERATE])
    g_ePlayerData[id][PDATA_BULL_HELD] = true
    set_pev(id, pev_movetype, MOVETYPE_NONE)
    set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN)
    if ( g_eSettings[SETTING_SET_CAMERA_ON_VICTIM] )
        engfunc(EngFunc_SetView, id, eBull[BULL_VIEW])

    if ( g_eSettings[SETTING_WRITE_MESSAGE_ON_DEATH] )
        bullMessage(id, bForced)

    if ( g_eSettings[SETTING_PLAY_SOUND_ON_DEATH] )
        for ( new i = 1; i <= g_iMaxPlayers; i ++ )
            bullSound(i, SOUND_BULL)
}

stock bullBar(id, iDuration)
{
    message_begin_f(MSG_ONE_UNRELIABLE, g_iBarTime, .player = id)
    write_short(iDuration)
    message_end()
}

public bullDamage(iTask)
{
    new id = iTask - BULL_LOCKED_KEY
    if ( !is_user_alive(id)
    || !(pev(id, pev_flags) & FL_FROZEN) )
    {
        new eBull[BULL], iItem
        if ( (iItem = bullGet(eBull, g_ePlayerData[id][PDATA_BULL_ID])) != -1 )
        {
            eBull[BULL_FLAGS] &= ~FLAG_USED
            eBull[BULL_NEXT_ACTIVE] = get_gametime() + random_float(eBull[BULL_COOLDOWN][0], eBull[BULL_COOLDOWN][1])
            set_pev(eBull[BULL_FIRE], pev_renderamt, 0.0)
            ArraySetArray(g_aBull, iItem, eBull)
        }

        engfunc(EngFunc_EmitSound, id, CHAN_VOICE, g_ePlayerData[id][PDATA_CURRENT_SCREAM], VOL_NORM, ATTN_NORM, SND_STOP, PITCH_NORM)
        g_ePlayerData[id][PDATA_BULL_ID] = 0
        g_ePlayerData[id][PDATA_BULL_HELD] = false
        g_ePlayerData[id][PDATA_BULL_LOCKED] = false
        g_ePlayerData[id][PDATA_NEXT_SCREAM] = 0.0
        return
    }
    else if ( get_gametime() >= g_ePlayerData[id][PDATA_NEXT_SCREAM] )
    {
        new szSound[MAX_VALUE_LENGTH], iScream
        while ( (iScream = random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_SCREAM]))) == g_ePlayerData[id][PDATA_CURRENT_SCREAM_ID] ) {}
        g_ePlayerData[id][PDATA_CURRENT_SCREAM_ID] = iScream
        ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_SCREAM], g_ePlayerData[id][PDATA_CURRENT_SCREAM_ID], szSound, charsmax(szSound))
        copy(g_ePlayerData[id][PDATA_CURRENT_SCREAM], charsmax(g_ePlayerData[][PDATA_CURRENT_SCREAM]), szSound)
        engfunc(EngFunc_EmitSound, id, CHAN_VOICE, szSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

        g_ePlayerData[id][PDATA_NEXT_SCREAM] = get_gametime() + random_float(g_eSettings[SETTING_DEFAULT_SCREAM_INTERVAL][0], g_eSettings[SETTING_DEFAULT_SCREAM_INTERVAL][1])
    }

    ExecuteHamB(Ham_TakeDamage, id, g_ePlayerData[id][PDATA_BULL_ID], g_ePlayerData[id][PDATA_BULL_ID], float(random_num(g_ePlayerData[id][PDATA_BULL_DAMAGE][0], g_ePlayerData[id][PDATA_BULL_DAMAGE][1])), g_ePlayerData[id][PDATA_BULL_DAMAGETYPE])
    set_task(random_float(g_ePlayerData[id][PDATA_BULL_DAMAGE_INTERVAL][0], g_ePlayerData[id][PDATA_BULL_DAMAGE_INTERVAL][1]), "bullDamage", id + BULL_LOCKED_KEY)
}

stock bullSelect(eBull[BULL], iAction)
{
    if ( iAction == TARGET_SELECT )
    {
        if ( eBull[BULL_FLAGS] & FLAG_ACTIVE )  { set_pev(eBull[BULL_ID], pev_rendercolor, Float:{0.0, 255.0, 0.0}); }
        else                                    { set_pev(eBull[BULL_ID], pev_rendercolor, Float:{255.0, 0.0, 0.0}); }

        set_pev(eBull[BULL_ID], pev_renderfx, kRenderFxGlowShell)
        set_pev(eBull[BULL_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eBull[BULL_ID], pev_renderamt, 16.0)
    }
    else if ( iAction == TARGET_GHOST )
    {
        set_pev(eBull[BULL_ID], pev_renderfx, kRenderFxNone)
        set_pev(eBull[BULL_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eBull[BULL_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eBull[BULL_ID], pev_renderamt, float(BULL_GHOST_ALPHA))
    }
    else if ( iAction == TARGET_HIDE )
    {
        set_pev(eBull[BULL_ID], pev_renderfx, kRenderFxNone)
        set_pev(eBull[BULL_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eBull[BULL_ID], pev_rendermode, kRenderTransAlpha)
        set_pev(eBull[BULL_ID], pev_renderamt, 0.0)
    }
    else if ( iAction == TARGET_CLEAR )
    {
        set_pev(eBull[BULL_ID], pev_renderfx, kRenderFxNone)
        set_pev(eBull[BULL_ID], pev_rendercolor, Float:{255.0, 255.0, 255.0})
        set_pev(eBull[BULL_ID], pev_rendermode, kRenderNormal)
        set_pev(eBull[BULL_ID], pev_renderamt, 255.0)
    }
}

stock bullMessage(id, bool:bForced = false)
{
    new szName[MAX_NAME_LENGTH], szMessage[128], iHudObject
    get_user_name(id, szName, charsmax(szName))

    if ( bForced )
        ArrayGetString(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED], random(ArraySize(g_eSettings[SETTING_DEFAULT_MESSAGE_FORCED])), szMessage, charsmax(szMessage))
    else
        ArrayGetString(g_eSettings[SETTING_DEFAULT_MESSAGE], random(ArraySize(g_eSettings[SETTING_DEFAULT_MESSAGE])), szMessage, charsmax(szMessage))

    switch ( g_iHudSlot )
    {
        case 0:  iHudObject = g_iHudObject_1
        case 1:  iHudObject = g_iHudObject_2
        default: iHudObject = g_iHudObject_3
    }

    set_hudmessage(g_eSettings[SETTING_HUD_COLOR][0], g_eSettings[SETTING_HUD_COLOR][1], g_eSettings[SETTING_HUD_COLOR][2], g_eSettings[SETTING_HUD_X], g_iHudCurrentY,
    g_eSettings[SETTING_HUD_EFFECT], g_eSettings[SETTING_HUD_FXTIME], g_eSettings[SETTING_HUD_HOLDTIME], g_eSettings[SETTING_HUD_FADEIN], g_eSettings[SETTING_HUD_FADEOUT])
    ShowSyncHudMsg(0, iHudObject, "%s%s", szName, szMessage)

    g_iHudSlot ++
    g_iHudCurrentY += HUD_Y_STEP
    if ( g_iHudCurrentY > HUD_Y_MAX )
    {
        g_iHudCurrentY = g_eSettings[SETTING_HUD_Y]
        g_iHudSlot = 0
    }
}

stock bullSound(iEnt, iSound, bool:bPlayer = true, iChannel = CHAN_ITEM)
{
    new szSample[64]
    switch( iSound )
    {
        case SOUND_MENU_NAV:    copy(szSample, charsmax(szSample), SOUND_NAV)
        case SOUND_MENU_REMOVE: copy(szSample, charsmax(szSample), SOUND_REMOVE)
        case SOUND_MENU_ALERT:  copy(szSample, charsmax(szSample), SOUND_ALERT)
        case SOUND_BULL:        ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND])), szSample, charsmax(szSample))
        case SOUND_FIRE:        ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_FIRE], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_FIRE])), szSample, charsmax(szSample))
        case SOUND_OPEN:        ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_OPEN], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_OPEN])), szSample, charsmax(szSample))
        case SOUND_CLOSE:       ArrayGetString(g_eSettings[SETTING_DEFAULT_SOUND_CLOSE], random(ArraySize(g_eSettings[SETTING_DEFAULT_SOUND_CLOSE])), szSample, charsmax(szSample))
    }

    if ( bPlayer )
        client_cmd(iEnt, "spk %s", szSample)
    else
        engfunc(EngFunc_EmitSound, iEnt, iChannel, szSample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

stock bullReset()
{
    new eBull[BULL]
    for ( new i = 0; i < g_iBull; i ++ )
    {
        ArrayGetArray(g_aBull, i, eBull)
        eBull[BULL_FLAGS] &= ~FLAG_USED
        ArraySetArray(g_aBull, i, eBull)
    }

    for ( new id = 1; id <= g_iMaxPlayers; id ++ )
    {
        g_ePlayerData[id][PDATA_NEXT_BULL] = 0.0
        g_ePlayerData[id][PDATA_NEXT_CHECK] = 0.0
        g_ePlayerData[id][PDATA_NEXT_SCREAM] = 0.0
    }
}

stock bullGet(eBull[BULL], iEnt)
{
    if ( !isBull(iEnt) )
        return -1

    new iItem
    iItem = pev(iEnt, BULL_ARRAY_ITEM)
    if ( iItem < 0 || iItem >= g_iBull )
        return -1

    ArrayGetArray(g_aBull, iItem, eBull)
    return iItem
}

stock bool:isBull(iEnt)
{
    return pev_valid(iEnt) && pev(iEnt, pev_impulse) == BULL_KEY
}

stock bullKill(eBull[BULL])
{
    if ( pev_valid(eBull[BULL_ID]) )
        set_pev(eBull[BULL_ID], pev_flags, pev(eBull[BULL_ID], pev_flags) | FL_KILLME)

    if ( pev_valid(eBull[BULL_VIEW]) )
        set_pev(eBull[BULL_VIEW], pev_flags, pev(eBull[BULL_VIEW], pev_flags) | FL_KILLME)

    if ( pev_valid(eBull[BULL_FIRE]) )
        set_pev(eBull[BULL_FIRE], pev_flags, pev(eBull[BULL_FIRE], pev_flags) | FL_KILLME)
}

stock parseSetting(iType, szValue[], iValueLen, any:aOutput[], iOutputLength)
{
    switch ( iType )
    {
        case DTYPE_INT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_num(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLOAT:
        {
            new szTok[MAX_VALUE_LENGTH], szTmp[MAX_VALUE_LENGTH], iCounter
            copy(szTmp, charsmax(szTmp), szValue)

            strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
            trim(szTok)
            while ( szTok[0] )
            {
                aOutput[iCounter ++] = str_to_float(szTok)

                strtok(szTmp, szTok, charsmax(szTok), szTmp, charsmax(szTmp), ' ')
                trim(szTok)
            }
        }
        case DTYPE_FLAGS:
        {
            aOutput[0] = read_flags(szValue)
        }
        case DTYPE_STRING_MODEL:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_model(szValue)
        }
        case DTYPE_STRING_SOUND:
        {
            copy(aOutput, iOutputLength, szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_ARRAY_MESSAGE:
        {
            replace_all(szValue, iValueLen, "^"", " ")
            replace_all(szValue, iValueLen, "^^n", "^n")
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_MODEL:
        {
            precache_model(szValue)
            ArrayPushString(aOutput[0], szValue)
        }
        case DTYPE_ARRAY_SOUND:
        {
            ArrayPushString(aOutput[0], szValue)
            if ( !g_bFileWasRead ) precache_sound(szValue)
        }
        case DTYPE_STRING_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                aOutput[0] = precache_model(szValue)
        }
        case DTYPE_ARRAY_MODEL_ID:
        {
            if ( !g_bFileWasRead )
                ArrayPushCell(aOutput[0], precache_model(szValue))
        }
    }
}

stock EnableAction(id)
{
    if ( !g_ePlayerData[id][PDATA_BULL_ACTION] )
    {
        new eBull[BULL]
        for ( new i = 0; i < g_iBull; i ++ )
        {
            ArrayGetArray(g_aBull, i, eBull)
            if ( eBull[BULL_FLAGS] & FLAG_SHOW )
                continue

            bullSelect(eBull, TARGET_GHOST)
        }

        g_ePlayerData[id][PDATA_BULL_ACTION] = true
        if ( ++ g_iActivePlayers == 1 )
            EnableForward()
    }
}

stock DisableAction(id)
{
    if ( g_ePlayerData[id][PDATA_BULL_ACTION] )
    {
        new eBull[BULL]
        for ( new i = 0; i < g_iBull; i ++ )
        {
            ArrayGetArray(g_aBull, i, eBull)
            if ( eBull[BULL_FLAGS] & FLAG_SHOW )
                continue

            bullSelect(eBull, TARGET_HIDE)
        }

        g_ePlayerData[id][PDATA_BULL_ACTION] = false
        if ( -- g_iActivePlayers == 0 )
            DisableForward()
    }
}

stock EnableForward()
{
    EnableHamForward(g_iFwdPreThink)
}

stock DisableForward()
{
    DisableHamForward(g_iFwdPreThink)
}

stock EnableBull()
{
    g_iFwdEmitSound = register_forward(FM_EmitSound, "fwdEmitSound")
    EnableHamForward(g_iFwdUse)
    EnableHamForward(g_iFwdObjectCaps)
    EnableHamForward(g_iFwdPostThink)
}

stock DisableBull()
{
    unregister_forward(FM_EmitSound, g_iFwdEmitSound)
    DisableHamForward(g_iFwdUse)
    DisableHamForward(g_iFwdObjectCaps)
    DisableHamForward(g_iFwdPostThink)
}

stock LogConfigError(const iLine, const szText[], any:...)
{
    new szError[MAX_PLATFORM_PATH_LENGTH]
    vformat(szError, charsmax(szError), szText, 3)

    log_to_file(ERROR_FILE, "^nLine %d: %s", iLine, szError)
}





