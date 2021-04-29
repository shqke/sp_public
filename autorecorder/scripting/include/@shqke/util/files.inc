#if defined _shqke_util_files_included
  #endinput
#endif
#define _shqke_util_files_included

stock bool Util_IsValidPath(const char[] path)
{
    if (path[0] == '\0') {
        return false;
    }
    
    if (path[0] == '/' || path[0] == '\\') {
        // Protect absolute paths
        return false;
    }
    
    bool hadDot = false;
    bool hadBackslash = false;
    
    for (int i = 0; path[i] != '\0'; i++) {
        switch (path[i]) {
            case '.':
            {
                if (hadDot) {
                    // Protect relative paths
                    return false;
                }
                
                hadDot = true;
            }
            case '\\':
            {
                if (hadBackslash) {
                    // Protect network paths
                    return false;
                }
                
                hadBackslash = true;
            }
            case ':', '\n', '\r':
            {
                // Protect absolute paths and disallow invalid symbols
                return false;
            }
            default:
            {
                hadDot = false;
                hadBackslash = false;
            }
        }
    }
    
    return true;
}

stock bool Util_CreateDirHierarchy(const char[] path, int mode = 0x1FF)
{
    int pos = 0;
    char dir[PLATFORM_MAX_PATH];

    for (int i = 0; i < sizeof(dir) && path[i] != '\0'; i++) {
        if (path[i] == '/' || path[i] == '\\') {
            pos += strcopy(dir[pos], i + 1 - pos, path[pos]);
            if (DirExists(dir)) {
                continue;
            }
            
            if (!CreateDirectory(dir, mode)) {
                return false;
            }
        }
    }

    return true;
}

stock bool Util_DefaultExtension(char[] path, int maxlength, const char[] ext)
{
    int pathlen = strlen(path);
    if (pathlen >= maxlength) {
        pathlen = maxlength - 1;
    }
    
    int extlen = strlen(ext);
    if (pathlen < extlen) {
        // Sane length check
        return false;
    }
    
    // Check if already have extension
    if (strcmp(path[pathlen - extlen], ext) != 0) {
        // Check if have enough to append extension
        if (maxlength <= pathlen + extlen) {
            // Don't want to be replacing existing symbols
            return false;
        }
        
        // Append extension
        strcopy(path[pathlen], maxlength - pathlen, ext);
    }
    
    return true;
}
