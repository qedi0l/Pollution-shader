layout(location = 0) out vec4 voxy_colour0;
layout(location = 1) out vec4 auxDataOut;
layout(location = 2) out vec4 voxyMarkerOut; // dedicated buffer, colortex17 — see voxy.json

// Standard 2-channel normal encoder
vec2 encodeNormal(vec3 normal) {
    return normal.xy * 0.5 + 0.5;
}

vec3 voxy_reconstructPosition(vec2 fragCoord, float depth) {
    vec2 ndcXY = fragCoord / vec2(viewWidth, viewHeight) * 2.0 - 1.0;
    float ndcZ = depth * 2.0 - 1.0;
    vec4 clipPos = vec4(ndcXY, ndcZ, 1.0);
    vec4 pos = vxViewProjInv * clipPos;
    return pos.xyz / pos.w;
}

// ---------------------------------------------------------------------------
// Fog shape constants + tunables
// ---------------------------------------------------------------------------
#define FOG_SHAPE_SPHERICAL 0
#define FOG_SHAPE_CYLINDRICAL 1

#define fogShape FOG_SHAPE_SPHERICAL
#define fogDensity 0.0
#define fogIntensity 1.0
#define fogParams vec2(0.0, vxRenderDistance * 16.0)

float voxy_getFragDistance(int shape, vec3 position) {
    switch (shape) {
        case FOG_SHAPE_SPHERICAL: return length(position);
        case FOG_SHAPE_CYLINDRICAL: return max(length(position.xz), abs(position.y));
        default: return length(position);
    }
}

void voxy_emitFragment(VoxyFragmentParameters parameters) {
    uint encodedData = uint(max(parameters.customId - (1u << 13u), 0) + (1u << 13u));
    uint blockId = encodedData & 0x1FFF;

    if (parameters.customId == 2) {
        discard;
    }
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
        float fogLerp = clamp((dist - vxRenderDistance * 16.0 * 0.1) / max(fogParams.y - vxRenderDistance * 16.0 * 0.1, 0.0001), 0.0, 1.0);
        #else
        float fogLerp = smoothstep(0.0, fogParams.y, dist);
        if (fogDensity > 0.0) fogLerp = (exp(fogDensity * fogLerp) - 1.0) / (exp(fogDensity) - 1.0);
        fogLerp = max(0.07, fogLerp);
        #endif

        fogFactor = clamp(fogLerp * fogIntensity*2, 0.0, 1.0);
        colour = mix(colour, fogColor, fogFactor);
    }

    voxy_colour0 = vec4(colour, parameters.sampledColour.a * parameters.tinting.a);
    auxDataOut = vec4(0.0, 0.0, encodeNormal(viewNormal));

    float aoEnable = (blockId == 1u) ? 0.0 : 1.0;

    // Fixed: Pass fogFactor into the 4th component, matching your opaque shader
    voxyMarkerOut = vec4(float(parameters.face + 1u) / 8.0 * aoEnable, 0.0, 0.0, fogFactor);

    // If submersed, handle water tint gracefully instead of a hard color override that kills alpha/translucency
    if (isEyeInWater > 0.0) {
        voxy_colour0.rgb = mix(voxy_colour0.rgb, fogColor, 0.5); // Blends water tint without destroying transparency
    }
}
