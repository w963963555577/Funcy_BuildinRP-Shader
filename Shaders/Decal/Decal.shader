Shader "Decal"
{
    Properties
    {
        [Header(Please use a cube to render)]
        [HDR]_Color ("Color", color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" { }
        
    }
    
    SubShader
    {
        Tags { "RenderType" = "Overlay" "Queue" = "Geometry+1" "DisableBatching" = "True" }
        
        Pass
        {
            Cull Front
            ZWrite Off
            ZTest GEqual
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            // GPU Instancing
            #pragma multi_compile_instancing
            
            #pragma target 3.0
            
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex: POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct v2f
            {
                float4 vertex: SV_POSITION;
                float4 screenUV: TEXCOORD0;
                float4 viewRayOS: TEXCOORD2;
                float3 cameraPosOS: TEXCOORD3;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            
            
            half4 _Color;
            half4 _MainTex_ST;
            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            
            
            void InitProjectorVertexData(float4 positionOS, float4x4 o2w, float4x4 w2o, out float4 viewRay, out float3 cameraPos)
            {
                float3 vr = mul(UNITY_MATRIX_V, mul(o2w, float4(positionOS.xyz, 1.0))).xyz;
                
                viewRay.w = vr.z;
                
                vr *= -1;
                float4x4 ViewToObjectMatrix = mul(w2o, UNITY_MATRIX_I_V);
                
                viewRay.xyz = mul((float3x3)ViewToObjectMatrix, vr);
                cameraPos = mul(ViewToObjectMatrix, float4(0.0h, 0.0h, 0.0h, 1.0h)).xyz;
            }
            
            float2 rotate2D(float2 uv, half2 pivot, half angle)
            {
                float c = cos(angle);
                float s = sin(angle);
                return mul(uv - pivot, float2x2(c, -s, s, c)) + pivot;
            }
            
            float2 projectorUV(float4 viewRayOS, float3 cameraPosOS, float4 screenUV, float2 scale, float rotateAngle)
            {
                viewRayOS /= viewRayOS.w;
                screenUV /= screenUV.w;
                #if defined(UNITY_SINGLE_PASS_STEREO)
                    screenUV.xy = UnityStereoTransformScreenSpaceTex(screenUV.xy);
                #endif
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, screenUV.xy));
                
                
                float sceneCameraSpaceDepth = depth;
                float3 decalSpaceScenePos = cameraPosOS + viewRayOS.xyz * sceneCameraSpaceDepth;
                decalSpaceScenePos.xy = rotate2D(decalSpaceScenePos.xy, 0.0.xx, rotateAngle);
                decalSpaceScenePos.xy *= scale;
                float2 decalSpaceUV = decalSpaceScenePos.xy + 0.5;
                
                float mask = (abs(decalSpaceScenePos.y) < 0.5) * (abs(decalSpaceScenePos.x) < 0.5) * (abs(decalSpaceScenePos.z) < 0.5) /* (abs(decalSpaceScenePos.y) < 0.5) * (abs(decalSpaceScenePos.z) < 0.5)*/;
                
                
                float3 decalSpaceHardNormal = normalize(cross(ddx(decalSpaceScenePos), ddy(decalSpaceScenePos)));
                mask *= decalSpaceHardNormal.z > - 1.0 ? 1.0: 0.0;//compare scene hard normal with decal projector's dir, decalSpaceHardNormal.z equals dot(decalForwardDir,sceneHardNormalDir)
                
                //call discard
                clip(mask - 0.5);//if ZWrite is off, clip() is fast enough on mobile, because it won't access the DepthBuffer, so no pipeline stall.
                //===================================================
                
                // sample the decal texture
                return decalSpaceUV.xy;
            }
            
            
            v2f vert(appdata v)
            {
                v2f o;
                
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex.xyz);
                o.screenUV = ComputeScreenPos(o.vertex);
                
                float4x4 o2w = unity_ObjectToWorld;
                float4x4 w2o = unity_WorldToObject;
                InitProjectorVertexData(v.vertex, o2w, w2o, o.viewRayOS, o.cameraPosOS);
                
                return o;
            }
            
            
            half4 frag(v2f i): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                half2 uv = projectorUV(i.viewRayOS, i.cameraPosOS, i.screenUV, 1.0.xx, 0.0);
                
                half4 col = tex2D(_MainTex, uv);
                
                //return col;
                
                half alpha = max(col.b, max(col.r, col.g));
                half3 trueColor = col.rgb / alpha;
                return half4(trueColor, alpha) * _Color;
                
            }
            ENDCG
            
        }
        
        Pass
        {
            Tags { "LightMode" = "SceneSelectionPass" }

            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            // GPU Instancing
            #pragma multi_compile_instancing
            
            #pragma target 3.0
            
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float4 vertex: POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct v2f
            {
                float4 vertex: SV_POSITION;
                
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            
            
            v2f vert(appdata v)
            {
                v2f o;
                
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex.xyz);
                
                return o;
            }
            
            
            half4 frag(v2f i): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                return 1.0;
            }
            ENDCG
            
        }
    }
}