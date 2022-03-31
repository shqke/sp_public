#if defined _hltv_cameras_cache_included
  #endinput
#endif
#define _hltv_cameras_cache_included

#define MAX_CAMERA_NAME 128

#define CONFIG_PATH_FMT "configs/hltv_cameras/%s.cfg"

const int CameraSlot_Name = 0;
const int CameraSlot_Origin = ( MAX_CAMERA_NAME / 4 ) + 1;
const int CameraSlot_EntityRef = CameraSlot_Origin + 3;
const int CameraSlot_Max = CameraSlot_EntityRef + 1;

ArrayList s_hCameras = null;

int CreateCameraEntity(const float origin[3])
{
    int entity = CreateEntityByName("point_viewcontrol");
    if (entity == -1) {
        LogError("Unable to create a new point_viewcontrol entity");
        
        return INVALID_ENT_REFERENCE;
    }
    
    TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
    DispatchSpawn(entity);
    
    return EntIndexToEntRef(entity);
}

int CameraCache_IndexFromName(const char[] cameraName)
{
    return s_hCameras.FindString(cameraName);
}

void CameraCache_GetOrigin(int index, float originOut[3])
{
    for (int i = 0; i < 3; i++) {
        originOut[i] = s_hCameras.Get(index, CameraSlot_Origin + i);
    }
}

void CameraCache_Save()
{
    char levelName[128];
    GetCurrentMap(levelName, sizeof(levelName));
    
    char tempPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, tempPath, sizeof(tempPath), CONFIG_PATH_FMT ... ".temp", levelName);
    
    File file = OpenFile(tempPath, "wb");
    if (file == null) {
        LogError("Unable to open file (path: \"%s\") for writing", tempPath);
        
        return;
    }
    
    int total = s_hCameras.Length;
    for (int i = 0; i < total; i++) {
        char cameraName[MAX_CAMERA_NAME];
        s_hCameras.GetString(i, cameraName, sizeof(cameraName));
        
        float origin[3];
        CameraCache_GetOrigin(i, origin);
        
        file.WriteLine(
            "\"%s\"\n"
            ... "{\n"
            ... "\t\"origin\"\t\"%f %f %f\"\n"
            ... "}%s",
            cameraName,
            origin[0], origin[1], origin[2],
            i + 1 != total ? "\n" : ""
        );
    }
    
    file.Close();
    
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), CONFIG_PATH_FMT, levelName);
    
    if (!RenameFile(path, tempPath)) {
        LogError("Unable to move file (oldpath: \"%s\", newpath: \"%s\") for writing", tempPath, path);
        
        return;
    }
}

void CameraCache_GenerateName(char[] cameraName, int maxlength, const char[] baseCameraName)
{
    if (s_hCameras.FindString(baseCameraName) == -1) {
        strcopy(cameraName, maxlength, baseCameraName);
        
        return;
    }
    
    int maxCameraNum = s_hCameras.Length + 1;
    for (int n = 1; n <= maxCameraNum; n++) {
        Format(cameraName, maxlength, "%s_%02d", baseCameraName, n);
        if (s_hCameras.FindString(cameraName) == -1) {
            break;
        }
    }
}

int CameraCache_AddCamera(const char[] cameraName, const float origin[3])
{
    int cameraRef = INVALID_ENT_REFERENCE;
    
    int index = s_hCameras.FindString(cameraName);
    if (index == -1) {
        index = s_hCameras.PushString(cameraName);
    }
    else {
        cameraRef = s_hCameras.Get(index, CameraSlot_EntityRef);
        if (IsValidEdict(cameraRef)) {
            // Move camera to a new place
            TeleportEntity(cameraRef, origin, NULL_VECTOR, NULL_VECTOR);
        }
    }
    
    if (!IsValidEdict(cameraRef)) {
        cameraRef = CreateCameraEntity(origin);
    }
    
    s_hCameras.Set(index, cameraRef, CameraSlot_EntityRef);
    
    for (int i = 0; i < 3; i++) {
        s_hCameras.Set(index, origin[i], CameraSlot_Origin + i);
    }
    
    CameraCache_Save();
    
    return s_hCameras.Length;
}

void CameraCache_MoveCamera(int index, const float origin[3])
{
    for (int i = 0; i < 3; i++) {
        s_hCameras.Set(index, origin[i], CameraSlot_Origin + i);
    }
    
    int cameraRef = s_hCameras.Get(index, CameraSlot_EntityRef);
    if (IsValidEdict(cameraRef)) {
        TeleportEntity(cameraRef, origin, NULL_VECTOR, NULL_VECTOR);
    }
    
    CameraCache_Save();
}

void CameraCache_DeleteCamera(int index)
{
    int cameraRef = s_hCameras.Get(index, CameraSlot_EntityRef);
    if (IsValidEdict(cameraRef)) {
        RemoveEntity(cameraRef);
    }
    
    s_hCameras.Erase(index);
}

void CameraCache_List(int client)
{
    int total = s_hCameras.Length;
    for (int n = 0; n < total; n++) {
        char cameraName[MAX_CAMERA_NAME];
        s_hCameras.GetString(n, cameraName, sizeof(cameraName));
        
        float origin[3];
        CameraCache_GetOrigin(n, origin);
        
        ReplyToCommand(client, "#%02d \"%s\" | %f %f %f", n, cameraName, origin[0], origin[1], origin[2]);
    }
}

void CameraCache_Clear()
{
    int totalCameras = s_hCameras.Length;
    for (int n = 0; n < totalCameras; n++) {
        int cameraRef = s_hCameras.Get(n, CameraSlot_EntityRef);
        if (IsValidEdict(cameraRef)) {
            RemoveEntity(cameraRef);
        }
    }
    
    s_hCameras.Clear();
}

void CameraCache_Init()
{
    s_hCameras = new ArrayList(CameraSlot_Max, 100);
    s_hCameras.Clear();
}