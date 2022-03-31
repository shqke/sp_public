#if defined _hltv_cameras_util_included
  #endinput
#endif
#define _hltv_cameras_util_included

void StringToVector(const char[] strIn, float vecOut[3])
{
    int pos = 0;
    
    for (int n = 0; n < 3; n++) {
        pos += StringToFloatEx(strIn[pos], vecOut[n]);
    }
}
