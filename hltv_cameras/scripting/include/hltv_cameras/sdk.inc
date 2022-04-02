#if defined _hltv_cameras_sdk_included
  #endinput
#endif
#define _hltv_cameras_sdk_included

#include <sdktools>

#define GAMEDATA_FILE "hltv_cameras"

#define INTERFACEVERSION_HLTVDIRECTOR "HLTVDirector001"

static Handle s_hCHLTVDirector_BuildCameraList = null;
static Handle s_hCHLTVDirector_RemoveEventsFromHistory = null;
static Address s_pHLTVDirector = Address_Null;

void HLTVDirector_BuildCameraList()
{
    // Force rebuild camera list in place
    SDKCall(s_hCHLTVDirector_BuildCameraList, s_pHLTVDirector);
    
    // Need this one to avoid conditional crashes in CHLTVDirector::StartFixedCameraShot
    // dereferencing raw pointer of CBaseEntity (m_pFixedCameras[iCamera])
    // NOTE: it can still crash (without plugin), if a tracked camera entity was killed at certain point
    SDKCall(s_hCHLTVDirector_RemoveEventsFromHistory, s_pHLTVDirector, -1);
}

void GameConfig_LoadOrFail()
{
    Handle gc = LoadGameConfigFile(GAMEDATA_FILE);
    if (gc == null) {
        SetFailState("Failed to load gamedata file \"" ... GAMEDATA_FILE ... "\"");
    }

    Handle hCreateInterface = null;

    StartPrepSDKCall(SDKCall_Static);
    if (PrepSDKCall_SetFromConf(gc, SDKConf_Signature, "CreateInterface")) {
        PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByRef);
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        hCreateInterface = EndPrepSDKCall();
    }
    
    StartPrepSDKCall(SDKCall_Raw);
    if (PrepSDKCall_SetFromConf(gc, SDKConf_Signature, "CHLTVDirector::BuildCameraList")) {
        s_hCHLTVDirector_BuildCameraList = EndPrepSDKCall();
    }
    
    StartPrepSDKCall(SDKCall_Raw);
    if (PrepSDKCall_SetFromConf(gc, SDKConf_Signature, "CHLTVDirector::RemoveEventsFromHistory")) {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        s_hCHLTVDirector_RemoveEventsFromHistory = EndPrepSDKCall();
    }
    
    int offset = GameConfGetOffset(gc, "CHLTVDirector::IHLTVDirector");

    delete gc;

    if (hCreateInterface == null) {
        SetFailState("Failed to prepare SDKCall for \"CreateInterface\" (gamedata file: \"" ... GAMEDATA_FILE ... ".txt\")");
    }
    else if (s_hCHLTVDirector_BuildCameraList == null) {
        SetFailState("Failed to prepare SDKCall for \"CHLTVDirector::BuildCameraList\" (gamedata file: \"" ... GAMEDATA_FILE ... ".txt\")");
    }
    else if (s_hCHLTVDirector_RemoveEventsFromHistory == null) {
        SetFailState("Failed to prepare SDKCall for \"CHLTVDirector::RemoveEventsFromHistory\" (gamedata file: \"" ... GAMEDATA_FILE ... ".txt\")");
    }
    
    s_pHLTVDirector = SDKCall(hCreateInterface, INTERFACEVERSION_HLTVDIRECTOR, Address_Null) - view_as<Address>( offset );
    
    delete hCreateInterface;
}
