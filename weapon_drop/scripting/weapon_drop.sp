#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

#define GAMEDATA_FILE "weapon_drop"
#define TEAM_SURVIVOR 2

Handle g_hCCSPlayer_CSWeaponDrop;

bool CCSPlayer_CSDropWeapon(int client, int weapon, bool toss = false)
{
    return SDKCall(g_hCCSPlayer_CSWeaponDrop, client, weapon, false, toss, NULL_VECTOR);
}

void DropWeapon(int client)
{
    if (!IsClientInGame(client)) {
        return;
    }

    if (GetClientTeam(client) != TEAM_SURVIVOR) {
        return;
    }

    if (!IsPlayerAlive(client)) {
        return;
    }

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (!IsValidEdict(weapon)) {
        return;
    }

    bool bHadDualWeapons = false;

    char cls[64];
    GetEdictClassname(weapon, cls, sizeof(cls));
    if (strncmp(cls, "weapon_pistol", 13) == 0) {
        bHadDualWeapons = GetEntProp(weapon, Prop_Send, "m_hasDualWeapons") != 0;
        if (!bHadDualWeapons) {
            PrintHintText(client, "You can't drop a pistol");
            
            return;
        }
    }
    else if (strcmp(cls, "weapon_melee") == 0) {
        PrintHintText(client, "You can't drop a melee");
        
        return;
    }
    else if (strcmp(cls, "weapon_chainsaw") == 0) {
        PrintHintText(client, "You can't drop a chainsaw");
        
        return;
    }

    if (bHadDualWeapons) {
        // Other pistol should get absorbed by spawn
        // ref: CPistol::Drop(CPistol *this, const Vector *a2)
        SDKHooks_DropWeapon(client, weapon);
    }
    else {
        // Weapon gets absorbed by spawn (if there's any nearby)
        // ref: CCSPlayer::CSWeaponDrop(CCSPlayer *this, CBaseCombatWeapon *a2, bool drop_shield, bool throw_forward, Vector *throw_direction)
        CCSPlayer_CSDropWeapon(client, weapon, true);
    }

    if (bHadDualWeapons) {
        // Unset dual wielding
        SetEntProp(weapon, Prop_Send, "m_hasDualWeapons", 0);
        SetEntProp(weapon, Prop_Send, "m_isDualWielding", 0);
        
        // Two weapons will fall - equip available
        EquipPlayerWeapon(client, weapon);
    }
}

public Action sm_drop(int client, int args)
{
    DropWeapon(client);

    return Plugin_Handled;
}

void LoadGameConfigOrFail()
{
    Handle gc = LoadGameConfigFile(GAMEDATA_FILE);
    if (gc == null) {
        SetFailState("Failed to load gamedata file \"" ... GAMEDATA_FILE ... ".txt\"");
    }

    StartPrepSDKCall(SDKCall_Player);
    if (PrepSDKCall_SetFromConf(gc, SDKConf_Signature, "CCSPlayer::CSWeaponDrop")) {
        PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
        g_hCCSPlayer_CSWeaponDrop = EndPrepSDKCall();
    }

    delete gc;

    if (g_hCCSPlayer_CSWeaponDrop == null) {
        SetFailState("Failed to prepare SDKCall for \"CCSPlayer::CSWeaponDrop\" (gamedata file: \"" ... GAMEDATA_FILE ... ".txt\")");
    }
}

public void OnPluginStart()
{
    LoadGameConfigOrFail();

    RegConsoleCmd("sm_drop", sm_drop);
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
    name = "[L4D/2] Weapon Drop",
    author = "shqke",
    description = "Allows you to drop your weapon with command sm_drop",
    version = "1.1",
    url = "https://github.com/shqke/sp_public"
};
