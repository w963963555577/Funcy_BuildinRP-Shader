// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "ZDShader/Build-in RP/PBR Base(SSS)"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" { }
        
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        
        _Glossiness ("Smoothness", Range(0.0, 1.0)) = 0.5
        _GlossMapScale ("Smoothness Scale", Range(0.0, 1.0)) = 1.0
        [Enum(Metallic Alpha, 0, Albedo Alpha, 1)] _SmoothnessTextureChannel ("Smoothness texture channel", Float) = 0
        
        [Gamma] _Metallic ("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicGlossMap ("Metallic", 2D) = "white" { }
        
        [ToggleOff] _SpecularHighlights ("Specular Highlights", Float) = 1.0
        [ToggleOff] _GlossyReflections ("Glossy Reflections", Float) = 1.0
        
        _BumpScale ("Scale", Float) = 1.0
        [Normal] _BumpMap ("Normal Map", 2D) = "bump" { }
        
        _Parallax ("Height Scale", Range(0.005, 0.08)) = 0.02
        _ParallaxMap ("Height Map", 2D) = "black" { }
        
        _OcclusionStrength ("Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap ("Occlusion", 2D) = "white" { }
        
        _EmissionColor ("Color", Color) = (0, 0, 0)
        _EmissionMap ("Emission", 2D) = "white" { }
        
        _DetailMask ("Detail Mask", 2D) = "white" { }
        
        _DetailAlbedoMap ("Detail Albedo x2", 2D) = "grey" { }
        _DetailNormalMapScale ("Scale", Float) = 1.0
        [Normal] _DetailNormalMap ("Normal Map", 2D) = "bump" { }
        
        _SubsurfaceScattering ("Scatter", Range(0, 1)) = 0.0
        _SubsurfaceRadius ("Radius", Float) = 2.0
        [HDR]_SubsurfaceColor ("Color", Color) = (1, 1, 1)
        _SubsurfaceMap ("SSS Map", 2D) = "White" { }
        
        [HDR]_RimLightColor ("Color", Color) = (.7, .85, 1.0)
        _RimLightSoftness ("Softness", Range(0.0, 1.0)) = 0.6
        _MaxHDR ("Max HDR", Range(0.0, 10.0)) = 10.0
        
        [HDR]_FlashingColor ("Flash Color", Color) = (0.75, 0.3, 0.2, 1)
        
        // _DiscolorationSystem
        [Toggle] _Discoloration ("Enable Discoloration System", float) = 0
        _DiscolorationColorCount ("Use Color Count", Range(1, 6)) = 2
        [HDR]_DiscolorationColor_0 ("DiscolorationColor_0", Color) = (1, 1, 1, 1)
        [HDR]_DiscolorationColor_1 ("DiscolorationColor_1", Color) = (1, 1, 1, 1)
        [HDR]_DiscolorationColor_2 ("DiscolorationColor_2", Color) = (1, 1, 1, 1)
        [HDR]_DiscolorationColor_3 ("DiscolorationColor_3", Color) = (1, 1, 1, 1)
        [HDR]_DiscolorationColor_4 ("DiscolorationColor_4", Color) = (1, 1, 1, 1)
        [HDR]_DiscolorationColor_5 ("DiscolorationColor_5", Color) = (1, 1, 1, 1)
        
        
        //Effective Disslove
        [HDR]_EffectiveColor ("_EffectiveColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _EffectiveMap ("Effective Map", 2D) = "white" { }
        
        [Enum(UV0, 0, UV1, 1)] _UVSec ("UV Set for secondary textures", Float) = 0
        
        // Blending state
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst", Float) = 0.0
        [Enum(Off, 0, On, 1)]  _ZWrite ("ZWrite", Float) = 1.0
    }
    
    CGINCLUDE
    #define UNITY_SETUP_BRDF_INPUT MetallicSetup
    ENDCG
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "PerformanceChecks" = "False" }
        LOD 300
        
        
        // ------------------------------------------------------------------
        //  Base forward pass (directional light, emission, lightmaps, ...)
        
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
            
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            
            CGPROGRAM
            
            #pragma target 3.0
            
            // -------------------------------------
            
            #define _NORMALMAP 1
            //#pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #define _EMISSION 1
            //#pragma shader_feature _EMISSION
            //#define _METALLICGLOSSMAP 1
            #pragma shader_feature_local _METALLICGLOSSMAP
            //#pragma shader_feature_local _DETAIL_MULX2
            //#pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            //#pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
            //#pragma shader_feature_local _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature_local _PARALLAXMAP
            
            #define DIRECTIONAL 1
            #define LIGHTPROBE_SH 1
            #define SHADOWS_SCREEN 1
            
            #define VERTEXLIGHT_ON 0
            #define DIRLIGHTMAP_COMBINED 1
            #define DYNAMICLIGHTMAP_ON 1
            #define LIGHTMAP_SHADOW_MIXING 1
            #define SHADOWS_SHADOWMASK 1
            
            //#pragma multi_compile_fwdbase
            
            #define FOG_LINEAR 1
            //#define FOG_EXP 0
            //#define FOG_EXP2 0
            //#pragma multi_compile_fog
            #define INSTANCING_ON 1
            //#pragma multi_compile_instancing
            
            #define _DiscolorationSystem 1
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE
            
            #pragma vertex vertBase
            #pragma fragment fragBase
            
            #include "../../ShaderLibrary/UnityStandardConfig.cginc"
            #include "../../ShaderLibrary/UnityStandardCore.cginc"
            
            sampler2D _SubsurfaceMap;
            sampler2D _EffectiveMap;
            
            half4 _SubsurfaceColor;
            half _SubsurfaceScattering;
            half _SubsurfaceRadius;
            half4 _RimLightColor;
            half _RimLightSoftness;
            half _MaxHDR;
            
            half4 _FlashingColor;
            
            //Discoloration System
            half _Discoloration;
            float4 _DiscolorationColor_0;
            float4 _DiscolorationColor_1;
            float4 _DiscolorationColor_2;
            float4 _DiscolorationColor_3;
            float4 _DiscolorationColor_4;
            float4 _DiscolorationColor_5;
            
            half4 _EffectiveColor;
            
            struct VertexOutput
            {
                UNITY_POSITION(pos);
                float4 tex: TEXCOORD0;
                float4 eyeVec: TEXCOORD1;    // eyeVec.xyz | fogCoord
                float4 tangentToWorldAndPackedData[3]: TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
                half4 ambientOrLightmapUV: TEXCOORD5;    // SH or Lightmap UV
                UNITY_LIGHTING_COORDS(6, 7)
                
                // next ones would not fit into SM2.0 limits, but they are always for SM3.0+
                #if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
                    float3 posWorld: TEXCOORD8;
                #endif
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            VertexOutput vertBase(VertexInput v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                VertexOutput o;
                UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
                #if UNITY_REQUIRE_FRAG_WORLDPOS
                    #if UNITY_PACK_WORLDPOS_WITH_TANGENT
                        o.tangentToWorldAndPackedData[0].w = posWorld.x;
                        o.tangentToWorldAndPackedData[1].w = posWorld.y;
                        o.tangentToWorldAndPackedData[2].w = posWorld.z;
                    #else
                        o.posWorld = posWorld.xyz;
                    #endif
                #endif
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.tex = TexCoords(v);
                o.eyeVec.xyz = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
                float3 normalWorld = UnityObjectToWorldNormal(v.normal);
                #ifdef _TANGENT_TO_WORLD
                    float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                    
                    float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
                    o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
                    o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
                    o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
                #else
                    o.tangentToWorldAndPackedData[0].xyz = 0;
                    o.tangentToWorldAndPackedData[1].xyz = 0;
                    o.tangentToWorldAndPackedData[2].xyz = normalWorld;
                #endif
                
                //We need this for shadow receving
                UNITY_TRANSFER_LIGHTING(o, v.uv1);
                
                o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);
                
                #ifdef _PARALLAXMAP
                    TANGENT_SPACE_ROTATION;
                    half3 viewDirForParallax = mul(rotation, ObjSpaceViewDir(v.vertex));
                    o.tangentToWorldAndPackedData[0].w = viewDirForParallax.x;
                    o.tangentToWorldAndPackedData[1].w = viewDirForParallax.y;
                    o.tangentToWorldAndPackedData[2].w = viewDirForParallax.z;
                #endif
                
                UNITY_TRANSFER_FOG_COMBINED_WITH_EYE_VEC(o, o.pos);
                return o;
            }
            
            half GetColorHDRValue(half3 color)
            {
                half scaleFactor = 191.0 / max(color.r, max(color.b, color.g));
                half hdr = log(255.0 / scaleFactor) / log(2.0);
                return max(0.0, hdr);
            }
            
            // Calculates the subsurface light radiating out from the current fragment. This is a simple approximation using wrapped lighting.
            // Note: This does not use distance attenuation, as it is intented to be used with a sun light.
            // Note: This does not subtract out cast shadows (light.shadowAttenuation), as it is intended to be used on non-shadowed objects. (for now)
            half3 LightingSubsurface(UnityLight light, half3 normalWS, half3 subsurfaceColor, half subsurfaceRadius, out half NdotL)
            {
                // Calculate normalized wrapped lighting. This spreads the light without adding energy.
                // This is a normal lambertian lighting calculation (using N dot L), but warping NdotL
                // to wrap the light further around an object.
                //
                // A normalization term is applied to make sure we do not add energy.
                // http://www.cim.mcgill.ca/~derek/files/jgt_wrap.pdf
                
                NdotL = dot(normalWS, light.dir);
                half alpha = subsurfaceRadius;
                //half theta_m = acos(-alpha); // boundary of the lighting function
                
                half theta = max(0, NdotL + alpha) - alpha;
                half normalization_jgt = (2 + alpha) / (2 * (1 + alpha));
                half wrapped_jgt = (pow(((theta + alpha) / (1 + alpha)), 1.0 + alpha)) * normalization_jgt;
                
                //half wrapped_valve = 0.25 * (NdotL + 1) * (NdotL + 1);
                //half wrapped_simple = (NdotL + alpha) / (1 + alpha);
                
                half3 subsurface_radiance = subsurfaceColor * wrapped_jgt;
                
                return subsurface_radiance;
            }
            half4 BuildinFragmentPBR(half3 diffColor, half3 specColor, half oneMinusReflectivity, half metallic, half smoothness, float3 normal, float3 viewDir, UnityLight light, UnityIndirect gi, half3 sssColor, half3 emission)
            {
                float perceptualRoughness = 1.0 - smoothness;
                float3 halfDir = Unity_SafeNormalize(float3(light.dir) + viewDir);
                
                // NdotV should not be negative for visible pixels, but it can happen due to perspective projection and normal mapping
                // In this case normal should be modified to become valid (i.e facing camera) and not cause weird artifacts.
                // but this operation adds few ALU and users may not want it. Alternative is to simply take the abs of NdotV (less correct but works too).
                // Following define allow to control this. Set it to 0 if ALU is critical on your platform.
                // This correction is interesting for GGX with SmithJoint visibility function because artifacts are more visible in this case due to highlight edge of rough surface
                // Edit: Disable this code by default for now as it is not compatible with two sided lighting used in SpeedTree.
                #define UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV 0
                
                #if UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV
                    // The amount we shift the normal toward the view vector is defined by the dot product.
                    half shiftAmount = dot(normal, viewDir);
                    normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f): normal;
                    // A re-normalization should be applied here but as the shift is small we don't do it to save ALU.
                    //normal = normalize(normal);
                    
                    float nv = saturate(dot(normal, viewDir)); // TODO: this saturate should no be necessary here
                #else
                    half nv = abs(dot(normal, viewDir));    // This abs allow to limit artifact
                #endif
                
                float nl = saturate(dot(normal, light.dir));
                float nh = saturate(dot(normal, halfDir));
                
                half lv = saturate(dot(light.dir, viewDir));
                half lh = saturate(dot(light.dir, halfDir));
                
                // Diffuse term
                half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;
                
                // Specular term
                // HACK: theoretically we should divide diffuseTerm by Pi and not multiply specularTerm!
                // BUT 1) that will make shader look significantly darker than Legacy ones
                // and 2) on engine side "Non-important" lights have to be divided by Pi too in cases when they are injected into ambient SH
                float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
                #if UNITY_BRDF_GGX
                    // GGX with roughtness to 0 would mean no specular at all, using max(roughness, 0.002) here to match HDrenderloop roughtness remapping.
                    roughness = max(roughness, 0.002);
                    float V = SmithJointGGXVisibilityTerm(nl, nv, roughness);
                    float D = GGXTerm(nh, roughness);
                #else
                    // Legacy
                    half V = SmithBeckmannVisibilityTerm(nl, nv, roughness);
                    half D = NDFBlinnPhongNormalizedTerm(nh, PerceptualRoughnessToSpecPower(perceptualRoughness));
                #endif
                
                float specularTerm = V * D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later
                
                #ifdef UNITY_COLORSPACE_GAMMA
                    specularTerm = sqrt(max(1e-4h, specularTerm));
                #endif
                
                // specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
                specularTerm = max(0, specularTerm * nl);
                #if defined(_SPECULARHIGHLIGHTS_OFF)
                    specularTerm = 0.0;
                #endif
                
                // surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(roughness^2+1)
                half surfaceReduction;
                #ifdef UNITY_COLORSPACE_GAMMA
                    surfaceReduction = 1.0 - 0.28 * roughness * perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
                #else
                    surfaceReduction = 1.0 / (roughness * roughness + 1.0);           // fade \in [0.5;1]
                #endif
                
                // To provide true Lambert lighting, we need to be able to kill specular completely.
                specularTerm *= any(specColor) ? 1.0: 0.0;
                
                half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));
                half3 c1 = (gi.diffuse + light.color * diffuseTerm);
                half3 c2 = specularTerm * light.color * FresnelTerm(specColor, lh);
                half3 GI = surfaceReduction * gi.specular * FresnelLerp(specColor, grazingTerm, nv);
                
                half3 color = GI;
                
                half Ndot = 0.0;
                half3 mainLightContribution = c1 * diffColor + c2;
                half3 subsurfaceContribution = LightingSubsurface(light, normal, sssColor, _SubsurfaceRadius, Ndot);
                
                color += lerp(mainLightContribution, subsurfaceContribution, _SubsurfaceScattering * (1.0 - metallic));
                color += emission;
                
                half _FlashArea = smoothstep(0.2, 1.0, 1.0 - max(0, dot(normal, viewDir)));
                
                half fresnel = smoothstep(_RimLightSoftness, 1.0, 1.0 - saturate(dot(normal, viewDir)));
                half3 rimLighting = gi.diffuse * Ndot * fresnel * 1.0 * _RimLightColor;
                
                color += rimLighting;
                //alpha = max(fresnel * _RimLightColor.a, alpha);
                color.rgb = clamp(color, 0.0.xxxx, (max(gi.diffuse, GI)) * _MaxHDR) + _FlashArea * GetColorHDRValue(_FlashingColor.rgb) * _FlashingColor.rgb;
                return half4(color, 1.0);
            }
            #if _DiscolorationSystem
                half3 RGB2HSV(half3 c)
                {
                    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
                    
                    float d = q.x - min(q.w, q.y);
                    float e = 1.0e-10;
                    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
                }
                
                half3 HSV2RGB(half3 c)
                {
                    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
                }
                
                void Step6Color(half gray, out float4 color, out float blackArea, out float skinArea)
                {
                    float gray_oneminus = (1.0 - gray);
                    
                    float grayArea_5 = saturate((smoothstep(0.90, 1.00, gray) * 2.0));
                    float grayArea_4 = saturate((smoothstep(0.70, 0.80, gray) * 2.0));
                    float grayArea_3 = saturate((smoothstep(0.60, 0.70, gray) * 2.0));
                    float grayArea_2 = saturate((smoothstep(0.45, 0.60, gray) * 2.0));
                    float grayArea_1 = saturate((smoothstep(0.35, 0.45, gray) * 2.0));
                    float grayArea_0 = saturate((smoothstep(0.95, 1.00, gray_oneminus) * 2.0));
                    
                    float fillArea_5 = grayArea_5;
                    float fillArea_4 = grayArea_4 - grayArea_5;
                    float fillArea_3 = grayArea_3 - grayArea_4;
                    float fillArea_2 = grayArea_2 - grayArea_3;
                    float fillArea_1 = grayArea_1 - grayArea_2;
                    float fillArea_0 = grayArea_0;
                    
                    blackArea = fillArea_0;
                    skinArea = fillArea_1;
                    
                    color = _DiscolorationColor_5 * fillArea_5 + _DiscolorationColor_4 * fillArea_4 +
                    _DiscolorationColor_3 * fillArea_3 + _DiscolorationColor_2 * fillArea_2 +
                    _DiscolorationColor_1 * fillArea_1 + _DiscolorationColor_0 * fillArea_0
                    ;
                    
                    half hdr = max(max(color.r, color.g), color.b) ;
                    color.a = hdr - 1.0;
                }
            #endif
            half4 fragBase(VertexOutput i): SV_Target
            {
                UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);
                
                FRAGMENT_SETUP(s)
                
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                UnityLight mainLight = MainLight();
                UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld);
                
                half2 occAndDiscoloration = tex2D(_OcclusionMap, i.tex.xy).gb;
                
                half occlusion = LerpOneTo(occAndDiscoloration.x, _OcclusionStrength);
                UnityGI gi = FragmentGI(s, occlusion, i.ambientOrLightmapUV, atten, mainLight);
                
                
                #if _DiscolorationSystem
                    half4 step_var ;
                    half blackArea;
                    half skinArea;
                    half eyeArea;
                    half2 eyeAreaReplace = 0.0;
                    half2 browReplace = 0.0;
                    half2 mouthReplace = 0.0;
                    
                    Step6Color(occAndDiscoloration.y, step_var, blackArea, skinArea);
                    
                    s.diffColor.rgb *= lerp(1.0.xxx, step_var.rgb, _Discoloration);
                #endif
                
                half3 sssColor = tex2D(_SubsurfaceMap, i.tex.xy).rgb * _SubsurfaceColor.rgb;
                half3 emission = Emission(i.tex.xy);
                
                #if _DiscolorationSystem
                    sssColor.rgb *= lerp(1.0.xxx, step_var.rgb, _Discoloration);
                    emission.rgb *= lerp(1.0.xxx, step_var.rgb, _Discoloration);
                #endif
                
                half4 c = BuildinFragmentPBR(s.diffColor, s.specColor, s.oneMinusReflectivity, s.metallic, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect, sssColor, emission);
                
                UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
                UNITY_APPLY_FOG(_unity_fogCoord, c.rgb);
                
                half4 effectiveMask = tex2D(_EffectiveMap, i.tex.xy * 0.5);
                half4 effectiveDisslive = _EffectiveColor;
                
                half alphaMinus = 1.0 - _EffectiveColor.a;
                effectiveDisslive.a = smoothstep(alphaMinus - 0.1, alphaMinus + 0.1, (1.0 - effectiveMask.r + 0.1 * (_EffectiveColor.a - 0.5) * 2.0));
                c.rgb *= effectiveDisslive.rgb;
                return OutputForward(c, s.alpha * effectiveDisslive.a);
            }
            
            ENDCG
            
        }
        
        // ------------------------------------------------------------------
        //  Additive forward pass (one light per pass)
        
        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode" = "ForwardAdd" }
            Blend [_SrcBlend] One
            Fog
            {
                Color(0, 0, 0, 0)
            }// in additive pass fog should be black
            ZWrite Off
            ZTest LEqual
            
            CGPROGRAM
            
            #pragma target 3.0
            
            // -------------------------------------
            #define _NORMALMAP 1
            //#pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _METALLICGLOSSMAP
            //#pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            //#pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
            //#pragma shader_feature_local _DETAIL_MULX2
            #pragma shader_feature_local _PARALLAXMAP
            #define INSTANCING_ON 1
            //#pragma multi_compile_instancing
            /*
            #define DIRECTIONAL 1
            #define DIRECTIONAL_COOKIE 0
            #define POINT 1
            #define POINT_COOKIE 0
            #define SOPT 1
            #define SHADOWS_DEPTH 1
            #define SHADOWS_SCREEN 1
            #define SHADOWS_CUBE 0
            #define SHADOWS_SOFT 1
            #define LIGHTMAP_SHADOW_MIXING 1
            #define SHADOWS_SHADOWMASK 1
            */
            #pragma multi_compile_fwdadd_fullshadows
            
            #define FOG_LINEAR 1
            #define FOG_EXP 0
            #define FOG_EXP2 0
            //#pragma multi_compile_fog
            
            #define _DiscolorationSystem 1
            
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE
            
            #pragma vertex vertAdd
            #pragma fragment fragAdd
            
            #include "../../ShaderLibrary/UnityStandardConfig.cginc"
            #include "../../ShaderLibrary/UnityStandardCore.cginc"
            
            sampler2D _SubsurfaceMap;
            sampler2D _EffectiveMap;
            
            half4 _SubsurfaceColor;
            half _SubsurfaceScattering;
            half _SubsurfaceRadius;
            half4 _RimLightColor;
            half _RimLightSoftness;
            half _MaxHDR;
            
            //Discoloration System
            half _Discoloration;
            float4 _DiscolorationColor_0;
            float4 _DiscolorationColor_1;
            float4 _DiscolorationColor_2;
            float4 _DiscolorationColor_3;
            float4 _DiscolorationColor_4;
            float4 _DiscolorationColor_5;
            
            half4 _EffectiveColor;
            
            struct VertexOutput
            {
                UNITY_POSITION(pos);
                float4 tex: TEXCOORD0;
                float4 eyeVec: TEXCOORD1;    // eyeVec.xyz | fogCoord
                float4 tangentToWorldAndLightDir[3]: TEXCOORD2;    // [3x3:tangentToWorld | 1x3:lightDir]
                float3 posWorld: TEXCOORD5;
                UNITY_LIGHTING_COORDS(6, 7)
                
                // next ones would not fit into SM2.0 limits, but they are always for SM3.0+
                #if defined(_PARALLAXMAP)
                    half3 viewDirForParallax: TEXCOORD8;
                #endif
                
                UNITY_VERTEX_OUTPUT_STEREO
            };
            VertexOutput vertAdd(VertexInput v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                VertexOutput o;
                UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.tex = TexCoords(v);
                o.eyeVec.xyz = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
                o.posWorld = posWorld.xyz;
                float3 normalWorld = UnityObjectToWorldNormal(v.normal);
                #ifdef _TANGENT_TO_WORLD
                    float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
                    
                    float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
                    o.tangentToWorldAndLightDir[0].xyz = tangentToWorld[0];
                    o.tangentToWorldAndLightDir[1].xyz = tangentToWorld[1];
                    o.tangentToWorldAndLightDir[2].xyz = tangentToWorld[2];
                #else
                    o.tangentToWorldAndLightDir[0].xyz = 0;
                    o.tangentToWorldAndLightDir[1].xyz = 0;
                    o.tangentToWorldAndLightDir[2].xyz = normalWorld;
                #endif
                //We need this for shadow receiving and lighting
                UNITY_TRANSFER_LIGHTING(o, v.uv1);
                
                float3 lightDir = _WorldSpaceLightPos0.xyz - posWorld.xyz * _WorldSpaceLightPos0.w;
                #ifndef USING_DIRECTIONAL_LIGHT
                    lightDir = NormalizePerVertexNormal(lightDir);
                #endif
                o.tangentToWorldAndLightDir[0].w = lightDir.x;
                o.tangentToWorldAndLightDir[1].w = lightDir.y;
                o.tangentToWorldAndLightDir[2].w = lightDir.z;
                
                #ifdef _PARALLAXMAP
                    TANGENT_SPACE_ROTATION;
                    o.viewDirForParallax = mul(rotation, ObjSpaceViewDir(v.vertex));
                #endif
                
                UNITY_TRANSFER_FOG_COMBINED_WITH_EYE_VEC(o, o.pos);
                return o;
            }
            
            
            // Calculates the subsurface light radiating out from the current fragment. This is a simple approximation using wrapped lighting.
            // Note: This does not use distance attenuation, as it is intented to be used with a sun light.
            // Note: This does not subtract out cast shadows (light.shadowAttenuation), as it is intended to be used on non-shadowed objects. (for now)
            half3 LightingSubsurface(UnityLight light, half3 normalWS, half3 subsurfaceColor, half subsurfaceRadius, out half NdotL)
            {
                // Calculate normalized wrapped lighting. This spreads the light without adding energy.
                // This is a normal lambertian lighting calculation (using N dot L), but warping NdotL
                // to wrap the light further around an object.
                //
                // A normalization term is applied to make sure we do not add energy.
                // http://www.cim.mcgill.ca/~derek/files/jgt_wrap.pdf
                
                NdotL = dot(normalWS, light.dir);
                half alpha = subsurfaceRadius;
                //half theta_m = acos(-alpha); // boundary of the lighting function
                
                half theta = max(0, NdotL + alpha) - alpha;
                half normalization_jgt = (2 + alpha) / (2 * (1 + alpha));
                half wrapped_jgt = (pow(((theta + alpha) / (1 + alpha)), 1.0 + alpha)) * normalization_jgt;
                
                //half wrapped_valve = 0.25 * (NdotL + 1) * (NdotL + 1);
                //half wrapped_simple = (NdotL + alpha) / (1 + alpha);
                
                half3 subsurface_radiance = subsurfaceColor * wrapped_jgt;
                
                return subsurface_radiance;
            }
            half4 BuildinFragmentPBR(half3 diffColor, half3 specColor, half oneMinusReflectivity, half metallic, half smoothness, float3 normal, float3 viewDir, UnityLight light, UnityIndirect gi, half3 sssColor)
            {
                float perceptualRoughness = 1.0 - smoothness;
                float3 halfDir = Unity_SafeNormalize(float3(light.dir) + viewDir);
                
                // NdotV should not be negative for visible pixels, but it can happen due to perspective projection and normal mapping
                // In this case normal should be modified to become valid (i.e facing camera) and not cause weird artifacts.
                // but this operation adds few ALU and users may not want it. Alternative is to simply take the abs of NdotV (less correct but works too).
                // Following define allow to control this. Set it to 0 if ALU is critical on your platform.
                // This correction is interesting for GGX with SmithJoint visibility function because artifacts are more visible in this case due to highlight edge of rough surface
                // Edit: Disable this code by default for now as it is not compatible with two sided lighting used in SpeedTree.
                #define UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV 0
                
                #if UNITY_HANDLE_CORRECTLY_NEGATIVE_NDOTV
                    // The amount we shift the normal toward the view vector is defined by the dot product.
                    half shiftAmount = dot(normal, viewDir);
                    normal = shiftAmount < 0.0f ? normal + viewDir * (-shiftAmount + 1e-5f): normal;
                    // A re-normalization should be applied here but as the shift is small we don't do it to save ALU.
                    //normal = normalize(normal);
                    
                    float nv = saturate(dot(normal, viewDir)); // TODO: this saturate should no be necessary here
                #else
                    half nv = abs(dot(normal, viewDir));    // This abs allow to limit artifact
                #endif
                
                float nl = saturate(dot(normal, light.dir));
                float nh = saturate(dot(normal, halfDir));
                
                half lv = saturate(dot(light.dir, viewDir));
                half lh = saturate(dot(light.dir, halfDir));
                
                // Diffuse term
                half diffuseTerm = DisneyDiffuse(nv, nl, lh, perceptualRoughness) * nl;
                
                // Specular term
                // HACK: theoretically we should divide diffuseTerm by Pi and not multiply specularTerm!
                // BUT 1) that will make shader look significantly darker than Legacy ones
                // and 2) on engine side "Non-important" lights have to be divided by Pi too in cases when they are injected into ambient SH
                float roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
                #if UNITY_BRDF_GGX
                    // GGX with roughtness to 0 would mean no specular at all, using max(roughness, 0.002) here to match HDrenderloop roughtness remapping.
                    roughness = max(roughness, 0.002);
                    float V = SmithJointGGXVisibilityTerm(nl, nv, roughness);
                    float D = GGXTerm(nh, roughness);
                #else
                    // Legacy
                    half V = SmithBeckmannVisibilityTerm(nl, nv, roughness);
                    half D = NDFBlinnPhongNormalizedTerm(nh, PerceptualRoughnessToSpecPower(perceptualRoughness));
                #endif
                
                float specularTerm = V * D * UNITY_PI; // Torrance-Sparrow model, Fresnel is applied later
                
                #ifdef UNITY_COLORSPACE_GAMMA
                    specularTerm = sqrt(max(1e-4h, specularTerm));
                #endif
                
                // specularTerm * nl can be NaN on Metal in some cases, use max() to make sure it's a sane value
                specularTerm = max(0, specularTerm * nl);
                #if defined(_SPECULARHIGHLIGHTS_OFF)
                    specularTerm = 0.0;
                #endif
                
                // surfaceReduction = Int D(NdotH) * NdotH * Id(NdotL>0) dH = 1/(roughness^2+1)
                half surfaceReduction;
                #ifdef UNITY_COLORSPACE_GAMMA
                    surfaceReduction = 1.0 - 0.28 * roughness * perceptualRoughness;      // 1-0.28*x^3 as approximation for (1/(x^4+1))^(1/2.2) on the domain [0;1]
                #else
                    surfaceReduction = 1.0 / (roughness * roughness + 1.0);           // fade \in [0.5;1]
                #endif
                
                // To provide true Lambert lighting, we need to be able to kill specular completely.
                specularTerm *= any(specColor) ? 1.0: 0.0;
                
                half grazingTerm = saturate(smoothness + (1 - oneMinusReflectivity));
                half3 c1 = (gi.diffuse + light.color * diffuseTerm);
                half3 c2 = specularTerm * light.color * FresnelTerm(specColor, lh);
                half3 GI = surfaceReduction * gi.specular * FresnelLerp(specColor, grazingTerm, nv);
                
                half3 color = GI;
                
                half Ndot = 0.0;
                half3 mainLightContribution = c1 * diffColor + c2;
                half3 subsurfaceContribution = LightingSubsurface(light, normal, sssColor, _SubsurfaceRadius, Ndot);
                
                color += lerp(mainLightContribution, subsurfaceContribution, _SubsurfaceScattering * (1.0 - metallic));
                
                
                return half4(color, 1);
            }
            #if _DiscolorationSystem
                half3 RGB2HSV(half3 c)
                {
                    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
                    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
                    
                    float d = q.x - min(q.w, q.y);
                    float e = 1.0e-10;
                    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
                }
                
                half3 HSV2RGB(half3 c)
                {
                    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
                }
                
                void Step6Color(half gray, out float4 color, out float blackArea, out float skinArea)
                {
                    float gray_oneminus = (1.0 - gray);
                    
                    float grayArea_5 = saturate((smoothstep(0.90, 1.00, gray) * 2.0));
                    float grayArea_4 = saturate((smoothstep(0.70, 0.80, gray) * 2.0));
                    float grayArea_3 = saturate((smoothstep(0.60, 0.70, gray) * 2.0));
                    float grayArea_2 = saturate((smoothstep(0.45, 0.60, gray) * 2.0));
                    float grayArea_1 = saturate((smoothstep(0.35, 0.45, gray) * 2.0));
                    float grayArea_0 = saturate((smoothstep(0.95, 1.00, gray_oneminus) * 2.0));
                    
                    float fillArea_5 = grayArea_5;
                    float fillArea_4 = grayArea_4 - grayArea_5;
                    float fillArea_3 = grayArea_3 - grayArea_4;
                    float fillArea_2 = grayArea_2 - grayArea_3;
                    float fillArea_1 = grayArea_1 - grayArea_2;
                    float fillArea_0 = grayArea_0;
                    
                    blackArea = fillArea_0;
                    skinArea = fillArea_1;
                    
                    color = _DiscolorationColor_5 * fillArea_5 + _DiscolorationColor_4 * fillArea_4 +
                    _DiscolorationColor_3 * fillArea_3 + _DiscolorationColor_2 * fillArea_2 +
                    _DiscolorationColor_1 * fillArea_1 + _DiscolorationColor_0 * fillArea_0
                    ;
                    
                    half hdr = max(max(color.r, color.g), color.b) ;
                    color.a = hdr - 1.0;
                }
            #endif
            half4 fragAdd(VertexOutput i): SV_Target
            {
                UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);
                
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                FRAGMENT_SETUP_FWDADD(s)
                
                UNITY_LIGHT_ATTENUATION(atten, i, s.posWorld)
                UnityLight light = AdditiveLight(IN_LIGHTDIR_FWDADD(i), atten);
                UnityIndirect noIndirect = ZeroIndirect();
                
                half2 occAndDiscoloration = tex2D(_OcclusionMap, i.tex.xy).gb;
                
                #if _DiscolorationSystem
                    half4 step_var ;
                    half blackArea;
                    half skinArea;
                    half eyeArea;
                    half2 eyeAreaReplace = 0.0;
                    half2 browReplace = 0.0;
                    half2 mouthReplace = 0.0;
                    
                    Step6Color(occAndDiscoloration.y, step_var, blackArea, skinArea);
                    
                    s.diffColor.rgb *= lerp(1.0.xxx, step_var.rgb, _Discoloration);
                #endif
                
                half3 sssColor = tex2D(_SubsurfaceMap, i.tex.xy).rgb * _SubsurfaceColor.rgb;
                
                #if _DiscolorationSystem
                    sssColor.rgb *= lerp(1.0.xxx, step_var.rgb, _Discoloration);
                    
                #endif
                
                half4 c = BuildinFragmentPBR(s.diffColor, s.specColor, s.oneMinusReflectivity, s.metallic, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect, sssColor);
                
                UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
                UNITY_APPLY_FOG_COLOR(_unity_fogCoord, c.rgb, half4(0, 0, 0, 0)); // fog towards black in additive pass
                
                half4 effectiveMask = tex2D(_EffectiveMap, i.tex.xy * 0.5);
                half4 effectiveDisslive = _EffectiveColor;
                
                half alphaMinus = 1.0 - _EffectiveColor.a;
                effectiveDisslive.a = smoothstep(alphaMinus - 0.1, alphaMinus + 0.1, (1.0 - effectiveMask.r + 0.1 * (_EffectiveColor.a - 0.5) * 2.0));
                c.rgb *= effectiveDisslive.rgb;
                return OutputForward(c * effectiveDisslive.a, s.alpha);
            }
            
            ENDCG
            
        }
        
        // ------------------------------------------------------------------
        //  Shadow rendering pass
        
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            
            ZWrite On ZTest LEqual
            
            CGPROGRAM
            
            #pragma target 3.0
            
            // -------------------------------------
            
            #pragma shader_feature_local _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature_local _METALLICGLOSSMAP
            //#pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _PARALLAXMAP
            #pragma multi_compile_shadowcaster
            #define INSTANCING_ON 1
            //#pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE
            
            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster
            
            
            #include "UnityCG.cginc"
            #include "UnityShaderVariables.cginc"
            #include "UnityStandardConfig.cginc"
            #include "UnityStandardUtils.cginc"
            #include "PBRBase(SSS)ShadowCaster.hlsl"
            
            ENDCG
            
        }
        
        /*
        // ------------------------------------------------------------------
        // Extracts information for lightmapping, GI (emission, albedo, ...)
        // This pass it not used during regular rendering.
        Pass
        {
            Name "META"
            Tags { "LightMode" = "Meta" }
            
            Cull Off
            
            CGPROGRAM
            
            #pragma vertex vert_meta
            #pragma fragment frag_meta
            
            #pragma shader_feature _EMISSION
            #pragma shader_feature_local _METALLICGLOSSMAP
            #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local _DETAIL_MULX2
            #pragma shader_feature EDITOR_VISUALIZATION
            
            #include "UnityStandardMeta.cginc"
            ENDCG
            
            */
        }
        
        CustomEditor "UnityEditor.Rendering.Funcy.BuildinRP.ShaderGUI.LitShader"
    }
