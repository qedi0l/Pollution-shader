uniform int fogMode;
uniform int isEyeInWater;

float TerrainFog(float distanceFromCamera) {
    // Environmental fog
    if (fogMode == 2048) {
        return 1.0 - exp(-distanceFromCamera * gl_Fog.density);
    }
    if (fogMode == 2049) {
        float density = distanceFromCamera * gl_Fog.density;
        return 1.0 - exp(-density * density);
    }
    if (fogMode == 9729) {
        float start = gl_Fog.start;
        float end = gl_Fog.end;
        return clamp((distanceFromCamera - start) / max(end - start, 0.001), 0.0, 1.0);
    }
    return 0.0;
}
