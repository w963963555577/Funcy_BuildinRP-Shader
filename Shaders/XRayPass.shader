Shader "ZDShader/Build-in RP/XRay"
{
    Properties
    {
        //Effective
        [HDR]_EffectiveColor_Light ("_EffectiveColor", Color) = (1.0, 1.0, 1.0, 1.0)
        [HDR]_EffectiveColor_Dark("_EffectiveColor Dark", Color) = (1.0, 1.0, 1.0, 1.0)
        _EffectiveDisslove("Disslove", Range(0.0, 1.0)) = 1.0
        _EffectiveMap ("Effective Map", 2D) = "white" { }
        [HDR]_XRayColor ("XRayColor", Color) = (.22, 1.95, 6.0, 1.0)
        
        [Toggle] _DissliveWithDiretion ("From Direction", float) = 0
        _DissliveAngle ("Angle", Range(-180, 180)) = 0
        [Toggle]_XRayEnabled ("Enabled", float) = 0
    }
    
    SubShader
    {
        Tags { "RenderType" = "Transparent" }
        LOD 100

        CGINCLUDE
        #pragma target 3.0
        ENDCG
        
        Blend SrcAlpha One
        AlphaToMask Off
        Cull Back
        ColorMask RGBA
        ZWrite Off
        ZTest Greater
        Offset 0, 0
        
        
        
        Pass
        {
            Name "XRayPass"
            
            CGPROGRAM
            
            #ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
                //only defining to not throw compilation error over Unity 5.5
                #define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
            #endif
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"
            #define ASE_NEEDS_FRAG_WORLD_POSITION


            struct VertexInput
            {
                float4 vertex: POSITION;
                float4 color: COLOR;
                half3 normal: NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct VertexOutput
            {
                float4 vertex: SV_POSITION;
                half3 normalWS: TEXCOORD1;
                half3 positionWS: TEXCOORD2;
                half3 OSuvMask: TEXCOORD3;
                half4 OSuv1: TEXCOORD4;
                half4 OSuv2: TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            #include "Lit/PBRBase(SSS)_Properties.hlsl"
            
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                
                GetDissloveInput(v.vertex, v.normal, _EffectiveMap_ST, o.OSuv1, o.OSuv2, o.OSuvMask);
                
                o.positionWS = mul(unity_ObjectToWorld, v.vertex);
                o.normalWS.xyz = UnityObjectToWorldNormal(v.normal);
                
                o.vertex = UnityObjectToClipPos(v.vertex);

                return o;
            }
            
            fixed4 frag(VertexOutput i): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                fixed4 finalColor;
                
                half3 appendResult8 = _XRayColor.rgb;
                half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.positionWS));
                half fresnelNdotV2 = dot(i.normalWS, worldViewDir);
                half fresnelNode2 = (0.0 + 1.0 * pow(max(1.0 - fresnelNdotV2, 0.0001), 2.0));
                
                half effectiveDisslive = _EffectiveDisslove;
                half edgeArea;
				half4 effectiveMask;
                effectiveDisslive = GetDissloveAlpha(i, effectiveDisslive, _EffectiveMap, edgeArea,effectiveMask);
                half4 appendResult12 = (half4((appendResult8 * fresnelNode2), effectiveDisslive));
                
                finalColor = (appendResult12 * _XRayEnabled);
                return finalColor;
            }
            ENDCG
            
        }
    }
    CustomEditor "ASEMaterialInspector"
}
