#include <sourcemod>
#pragma newdecls required

#define REQUIRE_EXTENSIONS
#include <imatchext>

#include <@shqke/util/string>

ConVar z_difficulty = null;

bool g_bValidMission = false;
char g_szCurrentMission[64];

bool g_bValidGamemode = false;
char g_szCurrentMode[64];

bool g_bValidBaseGamemode = false;
char g_szCurrentBaseMode[64];

bool g_bHasDifficulty = false;

void ExecuteConfig(const char[] fmtName, any ...)
{
    char name[PLATFORM_MAX_PATH];
    VFormat(name, sizeof(name), fmtName, 2);
    
    // PrintToServer("ExecuteConfig(\"%s\")", name);
    
    char path[PLATFORM_MAX_PATH];
    Format(path, sizeof(path), "//*/cfg/presets/%s.cfg", name);
    if (!FileExists(path, true, "*")) {
        // Do not attempt to execute if file doesn't exist.
        return;
    }
    
    ServerCommand("exec \"presets/%s\" *", name);
}

void HandleDifficultySetting()
{
    char szDifficulty[32];
    z_difficulty.GetString(szDifficulty, sizeof(szDifficulty));
    Util_LowerCase(szDifficulty);
    
    static char s_difficulties[][] = {
        "easy",
        "hard",
        "impossible",
    };
    
    for (int i = 0; i < sizeof(s_difficulties); i++) {
        if (strcmp(szDifficulty, s_difficulties[i]) != 0) {
            continue;
        }
        
        ExecuteConfig("mode_%s_%s", g_szCurrentMode, s_difficulties[i]);
        
        return;
    }
    
    ExecuteConfig("mode_%s_normal", g_szCurrentMode);
}

public void Event_difficulty_changed(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bValidGamemode) {
        return;
    }
    
    if (!g_bHasDifficulty) {
        return;
    }
    
    HandleDifficultySetting();
}

public void OnMapStart()
{
    ExecuteConfig("level_start");
    
    char levelName[128];
    GetCurrentMap(levelName, sizeof(levelName));
    
    ExecuteConfig("map_%s", levelName);
}

public void OnConfigsExecuted()
{
    g_bValidMission = MissionSymbol.IsValid(CurrentMission) && !CurrentMission.IsDisabled;
    if (g_bValidMission) {
        CurrentMission.GetName(g_szCurrentMission, sizeof(g_szCurrentMission));
        Util_LowerCase(g_szCurrentMission);
        
        ExecuteConfig("mission_%s", g_szCurrentMission);
    }
    else if (CurrentMission.IsDisabled) {
        ExecuteConfig("disabled_mission");
    }
    
    g_bValidGamemode = ModeSymbol.IsValid(CurrentMode) && !CurrentMode.IsDisabled;
    if (g_bValidGamemode) {
        CurrentMode.GetName(g_szCurrentMode, sizeof(g_szCurrentMode));
        Util_LowerCase(g_szCurrentMode);
        
        ExecuteConfig("mode_%s", g_szCurrentMode);
        if (g_bValidMission) {
            ExecuteConfig("modemission_%s_%s", g_szCurrentMode, g_szCurrentMission);
        }
        
        ModeSymbol baseMode = CurrentMode.Base;
        
        g_bValidBaseGamemode = ModeSymbol.IsValid(baseMode);
        if (g_bValidBaseGamemode) {
            baseMode.GetName(g_szCurrentBaseMode, sizeof(g_szCurrentBaseMode));
            Util_LowerCase(g_szCurrentBaseMode);
            
            ExecuteConfig("basemode_%s", g_szCurrentBaseMode);
            if (g_bValidMission) {
                ExecuteConfig("basemodemission_%s_%s", g_szCurrentBaseMode, g_szCurrentMission);
            }
        }
        
        g_bHasDifficulty = CurrentMode.HasConfigurableDifficultySetting;
        if (g_bHasDifficulty) {
            ExecuteConfig("mode_has_difficulty");
            
            HandleDifficultySetting();
        }
        
        if (CurrentMode.HasPlayerControlledZombies) {
            ExecuteConfig("mode_has_pz");
        }
        
        if (CurrentMode.IsSingleChapterMode) {
            ExecuteConfig("mode_single_chapter");
        }
    }
    else if (CurrentMode.IsDisabled) {
        ExecuteConfig("disabled_mode");
    }
}

public void OnMapEnd()
{
    ExecuteConfig("level_end");
}

public void OnPluginStart()
{
    z_difficulty = FindConVar("z_difficulty");

    HookEvent("difficulty_changed", Event_difficulty_changed, EventHookMode_PostNoCopy);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (GetEngineVersion() == Engine_Left4Dead2) {
        return APLRes_Success;
    }

    strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");

    return APLRes_SilentFailure;
}

public Plugin myinfo =
{
    name = "[L4D2] Config Presets",
    author = "shqke",
    description = "Execute relevant configs at level init",
    version = "1.2",
    url = "https://github.com/shqke/sp_public"
};
