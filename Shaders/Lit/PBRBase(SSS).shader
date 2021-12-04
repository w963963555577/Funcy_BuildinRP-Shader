// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "ZDShader/Build-in RP/PBR Base(SSS)"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" { }
        _AlbedoHSV ("HSV", Vector) = (0, 1, 1, 1)
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
        
        //SSPR
        [Toggle] _SsprEnabled ("Enable", float) = 0
        
        
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
        
        
        //Effective
        [HDR]_EffectiveColor_Light ("_EffectiveColor", Color) = (1.0, 1.0, 1.0, 1.0)
        [HDR]_EffectiveColor_Dark ("_EffectiveColor Dark", Color) = (1.0, 1.0, 1.0, 1.0)
        _EffectiveDisslove ("Disslove", Range(0.0, 1.0)) = 1.0
        _EffectiveMap ("Effective Map", 2D) = "clear" { }
        [HDR]_XRayColor ("XRayColor", Color) = (.22, 1.95, 6.0, 1.0)
        
        [Toggle] _DissliveWithDiretion ("From Direction", float) = 0
        _DissliveAngle ("Angle", Range(-180, 180)) = 0
        [Toggle]_XRayEnabled ("Enabled", float) = 0
        
        [Enum(UV0, 0, UV1, 1)] _UVSec ("UV Set for secondary textures", Float) = 0
        
        // Blending state
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src", Float) = 1.0
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst", Float) = 0.0
        [Enum(Off, 0, On, 1)]  _ZWrite ("ZWrite", Float) = 1.0
    }
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "PerformanceChecks" = "False" }
        LOD 300
        
        
        UsePass "ZDShader/Build-in RP/XRay/XRayPass"
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
            
            #ifdef SHADER_API_D3D11
                #pragma multi_compile_fog
            #else
                #define FOG_LINEAR 1
                //#define FOG_EXP 0
                //#define FOG_EXP2 0
                
            #endif
            
            #define INSTANCING_ON 1
            //#pragma multi_compile_instancing
            
            #define _DiscolorationSystem 1
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE
            
            #pragma vertex vertBase
            #pragma fragment fragBase
            
            #include "../../ShaderLibrary/UnityStandardConfig.cginc"
            #include "../../ShaderLibrary/UnityStandardCore.cginc"
            
            struct VertexOutput
            {
                UNITY_POSITION(pos);
                half4 tex: TEXCOORD0;
                half4 eyeVec: TEXCOORD1;    // eyeVec.xyz | fogCoord
                float4 tangentToWorldAndPackedData[3]: TEXCOORD2;    // [3x3:tangentToWorld | 1x3:viewDirForParallax or worldPos]
                half4 ambientOrLightmapUV: TEXCOORD5;    // SH or Lightmap UV
                UNITY_LIGHTING_COORDS(6, 7)
                
                // next ones would not fit into SM2.0 limits, but they are always for SM3.0+
                #if UNITY_REQUIRE_FRAG_WORLDPOS && !UNITY_PACK_WORLDPOS_WITH_TANGENT
                    float3 posWorld: TEXCOORD8;
                #endif
                
                half3 OSuvMask: TEXCOORD9;
                half4 OSuv1: TEXCOORD10;
                half4 OSuv2: TEXCOORD11;
                
                half4 positionSS: TEXCOORD12;
                
                half4 HDRColor: COLOR;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            #define IS_LITPASS 1
            #include "PBRBase(SSS)_Properties.hlsl"
            
            VertexOutput vertBase(VertexInput v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                VertexOutput o = (VertexOutput)0;
                UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                GetDissloveInput(v.vertex, v.normal, _EffectiveMap_ST, o.OSuv1, o.OSuv2, o.OSuvMask);
                
                o.HDRColor.rgb = GetColorHDRValue(_FlashingColor.rgb) * _FlashingColor.rgb;
                o.HDRColor.a = 1.0;
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
                o.positionSS = ComputeScreenPos(o.pos);
                
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
            
            half4 BuildinFragmentPBR(half3 diffColor, half3 specColor, half oneMinusReflectivity, half metallic, half smoothness, float3 normal, float3 viewDir, UnityLight light, UnityIndirect gi, half3 sssColor, half3 emission, half3 HDRColor, float4 positionSS)
            {
                half2 screenUV = positionSS.xy / positionSS.w;
                
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
                
                half4 ssrColor = tex2D(_MobileSSPR_ColorRT, screenUV);
                ssrColor.a *= saturate(dot(normal, half3(0.0, 1.0, 0.0))) * _SsprEnabled;
                GI = lerp(GI, ssrColor.rgb, ssrColor.a * max(1.0-roughness, metallic));

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
                color.rgb = clamp(color, 0.0.xxxx, (max(gi.diffuse, GI)) * _MaxHDR) + _FlashArea * HDRColor;
                return half4(color, 1.0);
            }
            
            inline FragmentCommonData InitMetallic(float4 i_tex)
            {
                half2 metallicGloss = MetallicGloss(i_tex.xy);
                half metallic = metallicGloss.x;
                half smoothness = metallicGloss.y; // this is 1 minus the square root of real roughness m.
                
                half oneMinusReflectivity;
                half3 specColor;
                half3 diffColor = DiffuseAndSpecularFromMetallic(AlbedoHSV(Albedo(i_tex)), metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);
                
                FragmentCommonData o = (FragmentCommonData)0;
                o.diffColor = diffColor;
                o.specColor = specColor;
                o.oneMinusReflectivity = oneMinusReflectivity;
                o.metallic = metallic;
                o.smoothness = smoothness;
                return o;
            }
            
            // parallax transformed texcoord is used to sample occlusion
            inline FragmentCommonData InitFragment(inout float4 i_tex, float3 i_eyeVec, half3 i_viewDirForParallax, float4 tangentToWorld[3], float3 i_posWorld)
            {
                i_tex = Parallax(i_tex, i_viewDirForParallax);
                
                half alpha = Alpha(i_tex.xy);
                #if defined(_ALPHATEST_ON)
                    clip(alpha - _Cutoff);
                #endif
                
                FragmentCommonData o = InitMetallic(i_tex);
                o.normalWorld = PerPixelWorldNormal(i_tex, tangentToWorld);
                o.eyeVec = NormalizePerPixelNormal(i_eyeVec);
                o.posWorld = i_posWorld;
                
                // NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
                o.diffColor = PreMultiplyAlpha(o.diffColor, alpha, o.oneMinusReflectivity, /*out*/ o.alpha);
                return o;
            }
            
            #define INIT_FRAGMENT(x) FragmentCommonData x = \
                InitFragment(i.tex, i.eyeVec.xyz, IN_VIEWDIR4PARALLAX(i), i.tangentToWorldAndPackedData, IN_WORLDPOS(i));

            half4 fragBase(VertexOutput i): SV_Target
            {
                UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);
                
                INIT_FRAGMENT(s)
                
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
                sssColor = lerp(s.diffColor, sssColor, min(_AlbedoHSV.z, _AlbedoHSV.y));
                #if _DiscolorationSystem
                    sssColor.rgb *= lerp(1.0, step_var.rgb, _Discoloration);
                    emission.rgb *= lerp(1.0.xxx, step_var.rgb, _Discoloration);
                #endif
                                
                half4 c = BuildinFragmentPBR(s.diffColor, s.specColor, s.oneMinusReflectivity, s.metallic, s.smoothness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect, sssColor, emission, i.HDRColor.rgb, i.positionSS);
                
                UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
                UNITY_APPLY_FOG(_unity_fogCoord, c.rgb);
                
                half effectiveDisslive = _EffectiveDisslove;
                half edgeArea;
                half alphaMinus = 1.0 - effectiveDisslive;
                half value = effectiveDisslive;
                half4 effectiveMask;
                effectiveDisslive = GetDissloveAlpha(i, effectiveDisslive, _EffectiveMap, edgeArea, effectiveMask);
                
                half gradient = smoothstep(value + 0.2, value - 0.2, (lerp(effectiveMask.r, i.OSuv2.w + 0.4 + (1.0 - value) * 0.3, _DissliveWithDiretion)));
                c.rgb = lerp(c.rgb, lerp(_EffectiveColor_Light.rgb, _EffectiveColor_Dark.rgb, gradient), edgeArea);
                return OutputForward(c, s.alpha * effectiveDisslive);
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
            
            #pragma multi_compile_fwdadd_fullshadows
            
            #ifdef SHADER_API_D3D11
                #pragma multi_compile_fog
            #else
                #define FOG_LINEAR 1
                //#define FOG_EXP 0
                //#define FOG_EXP2 0
                
            #endif
            
            #define _DiscolorationSystem 1
            
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE
            
            #pragma vertex vertAdd
            #pragma fragment fragAdd
            
            #include "../../ShaderLibrary/UnityStandardConfig.cginc"
            #include "../../ShaderLibrary/UnityStandardCore.cginc"
            
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
                
                half3 OSuvMask: TEXCOORD9;
                half4 OSuv1: TEXCOORD10;
                half4 OSuv2: TEXCOORD11;
                
                half4 positionSS: TEXCOORD12;
                
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            #define IS_LITPASS 1
            #include "PBRBase(SSS)_Properties.hlsl"
            
            VertexOutput vertAdd(VertexInput v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                VertexOutput o = (VertexOutput)0;
                UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                GetDissloveInput(v.vertex, v.normal, _EffectiveMap_ST, o.OSuv1, o.OSuv2, o.OSuvMask);
                
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
            
            
            inline FragmentCommonData InitMetallic(float4 i_tex)
            {
                half2 metallicGloss = MetallicGloss(i_tex.xy);
                half metallic = metallicGloss.x;
                half smoothness = metallicGloss.y; // this is 1 minus the square root of real roughness m.
                
                half oneMinusReflectivity;
                half3 specColor;
                half3 diffColor = DiffuseAndSpecularFromMetallic(AlbedoHSV(Albedo(i_tex)), metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);
                
                FragmentCommonData o = (FragmentCommonData)0;
                o.diffColor = diffColor;
                o.specColor = specColor;
                o.oneMinusReflectivity = oneMinusReflectivity;
                o.metallic = metallic;
                o.smoothness = smoothness;
                return o;
            }
            
            // parallax transformed texcoord is used to sample occlusion
            inline FragmentCommonData InitFragment(inout float4 i_tex, float3 i_eyeVec, half3 i_viewDirForParallax, float4 tangentToWorld[3], float3 i_posWorld)
            {
                i_tex = Parallax(i_tex, i_viewDirForParallax);
                
                half alpha = Alpha(i_tex.xy);
                #if defined(_ALPHATEST_ON)
                    clip(alpha - _Cutoff);
                #endif
                
                FragmentCommonData o = InitMetallic(i_tex);
                o.normalWorld = PerPixelWorldNormal(i_tex, tangentToWorld);
                o.eyeVec = NormalizePerPixelNormal(i_eyeVec);
                o.posWorld = i_posWorld;
                
                // NOTE: shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
                o.diffColor = PreMultiplyAlpha(o.diffColor, alpha, o.oneMinusReflectivity, /*out*/ o.alpha);
                return o;
            }
            
            #define INIT_FRAGMENT_FWDADD(x) FragmentCommonData x = \
                InitFragment(i.tex, i.eyeVec.xyz, IN_VIEWDIR4PARALLAX_FWDADD(i), i.tangentToWorldAndLightDir, IN_WORLDPOS_FWDADD(i));            
 
            half4 fragAdd(VertexOutput i): SV_Target
            {
                UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);
                
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                INIT_FRAGMENT_FWDADD(s)
                
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
                sssColor = lerp(s.diffColor, sssColor, min(_AlbedoHSV.z, _AlbedoHSV.y));
                #if _DiscolorationSystem
                    sssColor.rgb *= lerp(1.0.xxx, step_var.rgb, _Discoloration);
                    
                #endif
                
                half4 c = BuildinFragmentPBR(s.diffColor, s.specColor, s.oneMinusReflectivity, s.metallic, s.smoothness, s.normalWorld, -s.eyeVec, light, noIndirect, sssColor);
                
                UNITY_EXTRACT_FOG_FROM_EYE_VEC(i);
                UNITY_APPLY_FOG_COLOR(_unity_fogCoord, c.rgb, half4(0, 0, 0, 0)); // fog towards black in additive pass
                
                half effectiveDisslive = _EffectiveDisslove;
                half edgeArea;
                half4 effectiveMask;
                effectiveDisslive = GetDissloveAlpha(i, effectiveDisslive, _EffectiveMap, edgeArea, effectiveMask);
                
                return OutputForward(c * effectiveDisslive, s.alpha);
            }
            
            ENDCG
            
        }
        
        // ------------------------------------------------------------------
        //  Shadow rendering pass
        
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ZWrite On
            ZTest LEqual
            AlphaToMask Off
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
            #pragma multi_compile_shadowcaster
            
            #pragma multi_compile_local _AlphaClip
            
            #ifndef UNITY_PASS_SHADOWCASTER
                #define UNITY_PASS_SHADOWCASTER
            #endif
            #include "HLSLSupport.cginc"
            #ifndef UNITY_INSTANCED_LOD_FADE
                #define UNITY_INSTANCED_LOD_FADE
            #endif
            #ifndef UNITY_INSTANCED_SH
                #define UNITY_INSTANCED_SH
            #endif
            #ifndef UNITY_INSTANCED_LIGHTMAPSTS
                #define UNITY_INSTANCED_LIGHTMAPSTS
            #endif
            #if (SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN)
                #define CAN_SKIP_VPOS
            #endif
            #include "UnityShaderVariables.cginc"
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            
            
            struct VertexInput
            {
                float4 vertex: POSITION;
                float4 tangent: TANGENT;
                float3 normal: NORMAL;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct VertexOutput
            {
                V2F_SHADOW_CASTER;
                
                half3 OSuvMask: TEXCOORD0;
                half4 OSuv1: TEXCOORD1;
                half4 OSuv2: TEXCOORD2;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            #include "PBRBase(SSS)_Properties.hlsl"
            
            #ifdef UNITY_STANDARD_USE_DITHER_MASK
                sampler3D _DitherMaskLOD;
            #endif
            
            VertexOutput vert(VertexInput v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                VertexOutput o;
                UNITY_INITIALIZE_OUTPUT(VertexOutput, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                GetDissloveInput(v.vertex, v.normal, _EffectiveMap_ST, o.OSuv1, o.OSuv2, o.OSuvMask);
                
                v.vertex.w = 1;
                v.normal = v.normal;
                v.tangent = v.tangent;
                
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }
            
            
            fixed4 frag(VertexOutput i
            #ifdef _DEPTHOFFSET_ON
            , out float outputDepth: SV_Depth
            #endif
            #if !defined(CAN_SKIP_VPOS)
            , UNITY_VPOS_TYPE vpos: VPOS
            #endif
            ): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                
                #ifdef LOD_FADE_CROSSFADE
                    UNITY_APPLY_DITHER_CROSSFADE(i.pos.xy);
                #endif
                
                #if defined(_SPECULAR_SETUP)
                    SurfaceOutputStandardSpecular o = (SurfaceOutputStandardSpecular)0;
                #else
                    SurfaceOutputStandard o = (SurfaceOutputStandard)0;
                #endif
                
                
                o.Normal = fixed3(0, 0, 1);
                o.Occlusion = 1;
                o.Alpha = 1;
                float AlphaClipThreshold = 0.5;
                float AlphaClipThresholdShadow = 0.5;
                
                half effectiveDisslive = _EffectiveDisslove;
                half edgeArea;
                half4 effectiveMask;
                effectiveDisslive = GetDissloveAlpha(i, effectiveDisslive, _EffectiveMap, edgeArea, effectiveMask);
                o.Alpha *= effectiveDisslive;
                
                #ifdef _AlphaClip
                    clip(o.Alpha - AlphaClipThreshold);
                #endif
                
                #if defined(CAN_SKIP_VPOS)
                    float2 vpos = i.pos;
                #endif
                
                #ifdef UNITY_STANDARD_USE_DITHER_MASK
                    half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy * 0.25, o.Alpha * 0.9375)).a;
                    clip(alphaRef - 0.01);
                #endif
                
                #ifdef _DEPTHOFFSET_ON
                    outputDepth = IN.pos.z;
                #endif
                
                SHADOW_CASTER_FRAGMENT(i)
            }
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
            
            
        }
        */
    }
    CustomEditor "UnityEditor.Rendering.Funcy.BuildinRP.ShaderGUI.LitShader"
}