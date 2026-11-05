layout(location = 0) out vec4 voxy_colour0;
layout(location = 1) out vec4 auxDataOut;
layout(location = 2) out vec4 voxyMarkerOut; // dedicated buffer, colortex9 — see voxy.json

// Standard 2-channel normal encoder
vec2 encodeNormal(vec3 normal) {
    return normal.xy * 0.5 + 0.5; 
}

// Reconstructs a camera-relative world-space position from the fragment's
// depth using vxViewProjInv (inverse of the voxel view-projection matrix).
vec3 voxy_reconstructPosition(vec2 fragCoord, float depth) {
    vec2 ndcXY = fragCoord / vec2(viewWidth, viewHeight) * 2.0 - 1.0;
    float ndcZ = depth * 2.0 - 1.0;
    vec4 clipPos = vec4(ndcXY, ndcZ, 1.0);
    vec4 pos = vxViewProjInv * clipPos;
    return pos.xyz / pos.w;
}

// ---------------------------------------------------------------------------
// Fog shape constants + tunables — not part of voxy's uniform set, so
// defined locally instead of relying on the composite pass's globals.
// ---------------------------------------------------------------------------
#define FOG_SHAPE_SPHERICAL 0
#define FOG_SHAPE_CYLINDRICAL 1

#define fogShape FOG_SHAPE_SPHERICAL // 0 = spherical, 1 = cylindrical (height-independent, vanilla-style) [FOG_SHAPE_SPHERICAL FOG_SHAPE_CYLINDRICAL]
#define fogDensity 0.0               // 0 = pure smoothstep falloff; higher biases the fade toward the far edge [0.0 0.5 1.0 1.5 2.0 3.0 4.0 6.0]
#define fogIntensity 1.0             // caps how strong the fog can get, even past the far distance [0.0 0.25 0.5 0.75 1.0]
#define fogParams vec2(0.0, vxRenderDistance * 16.0) // start/end distance in blocks, from vxRenderDistance (chunks)

// Same shape logic as the env fog composite pass: spherical is straight-line
// distance, cylindrical ignores height so tall nearby geometry doesn't fog
// out the way distant ground does.
float voxy_getFragDistance(int shape, vec3 position) {
    switch (shape) {
        case FOG_SHAPE_SPHERICAL: return length(position);
        case FOG_SHAPE_CYLINDRICAL: return max(length(position.xz), abs(position.y));
        default: return length(position);
    }
}

void voxy_emitFragment(VoxyFragmentParameters parameters) {


uint encodedData = uint(max(parameters.customId - (1u << 13u), 0) + (1u << 13u));
// If they are Grey (Cat 0), do this instead:
uint blockId = encodedData & 0x1FFF; 
bool isFoliage = blockId == 1u;

    vec3 worldNormal = vec3(uint((parameters.face >> 1) == 2u), uint((parameters.face >> 1) == 0u), uint((parameters.face >> 1) == 1u)) * (float(int(parameters.face) & 1) * 2.0 - 1.0);
    if (isFoliage) worldNormal = vec3(0.0, 1.0, 0.0);
    
    vec3 viewNormal = mat3(gbufferModelView) * worldNormal;
    float lightIntensity = (isFoliage || parameters.lightMap.x > 0.8) ? 1.0 : min(worldNormal.x * worldNormal.x * 0.6 + worldNormal.y * worldNormal.y * 0.25 * (3.0 + worldNormal.y) + worldNormal.z * worldNormal.z * 0.8, 1.0);

    vec3 colour = parameters.sampledColour.rgb * parameters.tinting.rgb * lightIntensity * texture(lightmap, parameters.lightMap).rgb;

    float fogFactor = 0.0;
    if (fogIntensity > 0.0) {
        vec3 relPos = voxy_reconstructPosition(gl_FragCoord.xy, gl_FragCoord.z);
        float dist = voxy_getFragDistance(fogShape, relPos);

        #if MC_VERSION != 12111
            // Linear fog: straight ramp between start/end distance.
            float fogLerp = clamp((dist - vxRenderDistance * 16.0 * 0.1) / max(fogParams.y - vxRenderDistance * 16.0 * 0.1, 0.0001), 0.0, 1.0);
//fogLerp = max(0.02,fogLerp);
        #else
            // Pre-existing fog behaviour, kept for MC_VERSION == 12111.
            float fogLerp = smoothstep(0.0, fogParams.y, dist);
            if (fogDensity > 0.0) fogLerp = (exp(fogDensity * fogLerp) - 1.0) / (exp(fogDensity) - 1.0);
        if(true){fogLerp = max(0.07,fogLerp);}

        #endif

        fogFactor = clamp(fogLerp * fogIntensity, 0.0, 1.0);
        colour = mix(colour, fogColor, fogFactor);
    }

    voxy_colour0 = vec4(colour, parameters.sampledColour.a * parameters.tinting.a);
    auxDataOut = vec4(0.0, 0.0, encodeNormal(viewNormal));

    // Dedicated AO marker: (face+1)/8 so 0.0 unambiguously means "no AO here".
    // blockId 1 is excluded from AO entirely by forcing the marker to 0 for it
    // (still gets drawn/lit normally, just never gets darkened by the AO pass).
    float aoEnable = (blockId == 1u) ? 0.0 : 1.0;
    voxyMarkerOut = vec4(float(parameters.face + 1u) / 8.0 * aoEnable, 0.0, 0.0, fogFactor);
if(isEyeInWater > 0.0){voxy_colour0 = vec4(fogColor,1);}
}
