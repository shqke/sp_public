#include <sourcemod>

enum PlayerConnectedState
{
    PlayerConnected,
    PlayerDisconnecting,
    PlayerDisconnected,
};

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

void SetHLTVBotConnectedState(PlayerConnectedState newState)
{
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && IsClientSourceTV(i)) {
            SetPlayerConnectedState(i, newState);
            return;
        }
    }
}

public void Event_player_activate(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsClientSourceTV(client)) {
        return;
    }
    
    SetPlayerConnectedState(client, PlayerDisconnected);
}

public void OnPluginStart()
{
    SetHLTVBotConnectedState(PlayerDisconnected);
    
    HookEvent("player_activate", Event_player_activate, EventHookMode_Post);
}

public void OnPluginEnd()
{
    SetHLTVBotConnectedState(PlayerConnected);
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
    version = "1.1",
    url = "https://github.com/shqke/sp_public"
};
