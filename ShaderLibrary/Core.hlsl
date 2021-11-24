#ifndef UNIVERSAL_PIPELINE_CORE_INCLUDED
#define UNIVERSAL_PIPELINE_CORE_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

#if !defined(SHADER_HINT_NICE_QUALITY)
#if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
#define SHADER_HINT_NICE_QUALITY 0
#else
#define SHADER_HINT_NICE_QUALITY 1
#endif
#endif

// Shader Quality Tiers in Universal. 
// SRP doesn't use Graphics Settings Quality Tiers.
// We should expose shader quality tiers in the pipeline asset.
// Meanwhile, it's forced to be:
// High Quality: Non-mobile platforms or shader explicit defined SHADER_HINT_NICE_QUALITY
// Medium: Mobile aside from GLES2
// Low: GLES2 
#if SHADER_HINT_NICE_QUALITY
#define SHADER_QUALITY_HIGH
#elif defined(SHADER_API_GLES)
#define SHADER_QUALITY_LOW
#else
#define SHADER_QUALITY_MEDIUM
#endif

#ifndef BUMP_SCALE_NOT_SUPPORTED
#define BUMP_SCALE_NOT_SUPPORTED !SHADER_HINT_NICE_QUALITY
#endif

#if UNITY_REVERSED_Z
    #if SHADER_API_OPENGL || SHADER_API_GLES || SHADER_API_GLES3
        //GL with reversed z => z clip range is [near, -far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
        #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) max(-(coord), 0)
    #else
        //D3d with reversed Z => z clip range is [near, 0] -> remapping to [0, far]
        //max is required to protect ourselves from near plane not being correct/meaningfull in case of oblique matrices.
        #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) max(((1.0-(coord)/_ProjectionParams.y)*_ProjectionParams.z),0)
    #endif
#elif UNITY_UV_STARTS_AT_TOP
    //D3d without reversed z => z clip range is [0, far] -> nothing to do
    #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
#else
    //Opengl => z clip range is [-near, far] -> should remap in theory but dont do it in practice to save some perf (range is close enough)
    #define UNITY_Z_0_FAR_FROM_CLIPSPACE(coord) (coord)
#endif


// A word on normalization of normals:
// For better quality normals should be normalized before and after
// interpolation. 
// 1) In vertex, skinning or blend shapes might vary significantly the lenght of normal. 
// 2) In fragment, because even outputting unit-length normals interpolation can make it non-unit.
// 3) In fragment when using normal map, because mikktspace sets up non orthonormal basis. 
// However we will try to balance performance vs quality here as also let users configure that as 
// shader quality tiers. 
// Low Quality Tier: Normalize either per-vertex or per-pixel depending if normalmap is sampled.
// Medium Quality Tier: Always normalize per-vertex. Normalize per-pixel only if using normal map
// High Quality Tier: Normalize in both vertex and pixel shaders.


// TODO: A similar function should be already available in SRP lib on master. Use that instead
float4 ComputeScreenPos(float4 positionCS)
{
    float4 o = positionCS * 0.5f;
    o.xy = float2(o.x, o.y) + o.w;
    o.zw = positionCS.zw;
    return o;
}


// Stereo-related bits
#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)

    #define SLICE_ARRAY_INDEX   unity_StereoEyeIndex

    #define TEXTURE2D_X                 TEXTURE2D_ARRAY
    #define TEXTURE2D_X_PARAM           TEXTURE2D_ARRAY_PARAM
    #define TEXTURE2D_X_ARGS            TEXTURE2D_ARRAY_ARGS
    #define TEXTURE2D_X_HALF            TEXTURE2D_ARRAY_HALF
    #define TEXTURE2D_X_FLOAT           TEXTURE2D_ARRAY_FLOAT

    #define LOAD_TEXTURE2D_X(textureName, unCoord2)                         LOAD_TEXTURE2D_ARRAY(textureName, unCoord2, SLICE_ARRAY_INDEX)
    #define LOAD_TEXTURE2D_X_LOD(textureName, unCoord2, lod)                LOAD_TEXTURE2D_ARRAY_LOD(textureName, unCoord2, SLICE_ARRAY_INDEX, lod)    
    #define SAMPLE_TEXTURE2D_X(textureName, samplerName, coord2)            SAMPLE_TEXTURE2D_ARRAY(textureName, samplerName, coord2, SLICE_ARRAY_INDEX)
    #define SAMPLE_TEXTURE2D_X_LOD(textureName, samplerName, coord2, lod)   SAMPLE_TEXTURE2D_ARRAY_LOD(textureName, samplerName, coord2, SLICE_ARRAY_INDEX, lod)
    #define GATHER_TEXTURE2D_X(textureName, samplerName, coord2)            GATHER_TEXTURE2D_ARRAY(textureName, samplerName, coord2, SLICE_ARRAY_INDEX)
    #define GATHER_RED_TEXTURE2D_X(textureName, samplerName, coord2)        GATHER_RED_TEXTURE2D(textureName, samplerName, float3(coord2, SLICE_ARRAY_INDEX))
    #define GATHER_GREEN_TEXTURE2D_X(textureName, samplerName, coord2)      GATHER_GREEN_TEXTURE2D(textureName, samplerName, float3(coord2, SLICE_ARRAY_INDEX))
    #define GATHER_BLUE_TEXTURE2D_X(textureName, samplerName, coord2)       GATHER_BLUE_TEXTURE2D(textureName, samplerName, float3(coord2, SLICE_ARRAY_INDEX))

#else

    #define SLICE_ARRAY_INDEX       0

    #define TEXTURE2D_X                 TEXTURE2D
    #define TEXTURE2D_X_PARAM           TEXTURE2D_PARAM
    #define TEXTURE2D_X_ARGS            TEXTURE2D_ARGS
    #define TEXTURE2D_X_HALF            TEXTURE2D_HALF
    #define TEXTURE2D_X_FLOAT           TEXTURE2D_FLOAT

    #define LOAD_TEXTURE2D_X            LOAD_TEXTURE2D
    #define LOAD_TEXTURE2D_X_LOD        LOAD_TEXTURE2D_LOD
    #define SAMPLE_TEXTURE2D_X          SAMPLE_TEXTURE2D
    #define SAMPLE_TEXTURE2D_X_LOD      SAMPLE_TEXTURE2D_LOD
    #define GATHER_TEXTURE2D_X          GATHER_TEXTURE2D
    #define GATHER_RED_TEXTURE2D_X      GATHER_RED_TEXTURE2D
    #define GATHER_GREEN_TEXTURE2D_X    GATHER_GREEN_TEXTURE2D
    #define GATHER_BLUE_TEXTURE2D_X     GATHER_BLUE_TEXTURE2D

#endif

#if defined(UNITY_SINGLE_PASS_STEREO)
float2 TransformStereoScreenSpaceTex(float2 uv, float w)
{
    // TODO: RVS support can be added here, if Universal decides to support it
    float4 scaleOffset = unity_StereoScaleOffset[unity_StereoEyeIndex];
    return uv.xy * scaleOffset.xy + scaleOffset.zw * w;
}

float2 UnityStereoTransformScreenSpaceTex(float2 uv)
{
    return TransformStereoScreenSpaceTex(saturate(uv), 1.0);
}

#else

#define UnityStereoTransformScreenSpaceTex(uv) uv

#endif // defined(UNITY_SINGLE_PASS_STEREO)


#endif
