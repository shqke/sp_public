#include <sourcemod>

#define REQUIRE_EXTENSIONS
#include <sourcetvmanager>

enum PlayerConnectedState
{
    PlayerConnected,
    PlayerDisconnecting,
    PlayerDisconnected,
};

bool IsValidSourceTVBot(int client)
{
    if (client < 1 || client > MaxClients) {
        return false;
    }
    
    if (!IsClientInGame(client)) {
        return false;
    }
    
    return IsClientSourceTV(client);
}

void SetPlayerConnectedState(int client, PlayerConnectedState value)
{
    // Compute offset, relative to other prop
    // CBasePlayer::m_iConnected is located before CBasePlayer::m_ArmorValue
    static int m_iConnected = -1;
    if (m_iConnected == -1) {
        // CBasePlayer doesn't send this but CCSPlayer does.
        m_iConnected = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
        if (m_iConnected <= 0) {
            SetFailState("Unable to find offset for \"CCSPlayer::m_ArmorValue\"");
        }
        
        m_iConnected -= 4;
    }

    SetEntData(client, m_iConnected, value);
}

public void Event_player_activate(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidSourceTVBot(client)) {
        return;
    }
    
    SetPlayerConnectedState(client, PlayerDisconnected);
}

public void OnPluginStart()
{
    int client = SourceTV_GetBotIndex();
    if (IsValidSourceTVBot(client)) {
        SetPlayerConnectedState(client, PlayerDisconnected);
    }
    
    HookEvent("player_activate", Event_player_activate, EventHookMode_Post);
}

public void OnPluginEnd()
{
    int client = SourceTV_GetBotIndex();
    if (IsValidSourceTVBot(client)) {
        SetPlayerConnectedState(client, PlayerConnected);
    }
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    switch (GetEngineVersion()) {
        case Engine_Left4Dead2, Engine_Left4Dead:
        {
            return APLRes_Success;
        }
    }

    strcopy(error, err_max, "Plugin only supports Left 4 Dead and Left 4 Dead 2.");

    return APLRes_SilentFailure;
}

public Plugin myinfo =
{
    name = "[L4D/2] Hide SourceTV Bot",
    author = "shqke",
    description = "Hides SourceTV bot from scoreboard",
    version = "1.0",
    url = "https://github.com/shqke/sp_public"
};
