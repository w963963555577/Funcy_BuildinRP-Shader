half4 _AlbedoHSV;

half4 _SubsurfaceColor;
half _SubsurfaceScattering;
half _SubsurfaceRadius;

half _SsprEnabled;

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

//Effective
half4 _EffectiveMap_ST;
half4 _EffectiveColor_Light;
half4 _EffectiveColor_Dark;
half _EffectiveDisslove;
half _XRayEnabled;
half4 _XRayColor;
half _DissliveWithDiretion;
half _ObjectLeft;
half _ObjectUp;
half4 _NegativeDiretionLeft;
half4 _NegativeDiretionUp;
half _DissliveAngle;

sampler2D _MobileSSPR_ColorRT;

sampler2D _SubsurfaceMap;
sampler2D _EffectiveMap;

half smoothstepBetterPerformace(half edge0, half edge1, half x, half d)
{
    half t = saturate((x - edge0) * d);
    return t * t * (3.0 - 2.0 * t);
}

half linearstep(half edge0, half edge1, half x)
{
    half t = (x - edge0) / (edge1 - edge0);
    
    return min(max(t, 0.0), 1.0);
}

float2 rotate2D(float2 uv, half2 pivot, half angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return mul(uv - pivot, float2x2(c, -s, s, c)) + pivot;
}
//Unity
half GetUnityHDRIntensityValue(half3 color)
{
    half scaleFactor = 191.0 / max(color.r, max(color.b, color.g));
    half hdr = log(255.0 / scaleFactor) * 1.44269504089;//1.44269504089 = 1.0 / log(2.0)
    return max(0.0, hdr);
}

fixed3 RGB2HSV(fixed3 c)
{
    fixed4 K = fixed4(0.0, -0.3333333333333333, 0.6666666666666667, -1.0);
    fixed4 p = lerp(fixed4(c.bg, K.wz), fixed4(c.gb, K.xy), step(c.b, c.g));
    fixed4 q = lerp(fixed4(p.xyw, c.r), fixed4(c.r, p.yzx), step(p.x, c.r));
    
    fixed d = q.x - min(q.w, q.y);
    fixed e = 1.0e-4;
    return fixed3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

fixed3 HSV2RGB(fixed3 c)
{
    fixed4 K = fixed4(1.0, 0.6666666666666667, 0.3333333333333333, 3.0);
    fixed3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

fixed3 AdjustContrast(fixed3 color, fixed contrast)
{
    color = saturate(lerp(fixed3(0.214, 0.214, 0.214), color, contrast * contrast));
    return color;
}

fixed3 AlbedoHSV(fixed3 albedo)
{
    fixed3 hsv = RGB2HSV(AdjustContrast(albedo, _AlbedoHSV.w));
    hsv.x += _AlbedoHSV.x;
    hsv.y *= _AlbedoHSV.y;
    hsv.z *= _AlbedoHSV.z;
    return HSV2RGB(hsv);
}
fixed3 D_GGX(fixed roughness, fixed HdN, fixed LdH2)
{
    fixed a = roughness;
    fixed a2 = a * a;
    fixed normalizationTerm = a * 4.0 + 2.0;
    fixed d = (HdN * a2 - HdN) * HdN + 1;
    return a2 / (d * d * max(0.1, LdH2) * normalizationTerm);
}

#if _DiscolorationSystem
    void Step6Color(fixed gray, out fixed4 color, out fixed blackArea, out fixed skinArea)
    {
        fixed gray_oneminus = (1.0 - gray);
        
        fixed grayArea_5 = saturate((smoothstep(0.90, 1.00, gray) * 2.0));
        fixed grayArea_4 = saturate((smoothstep(0.70, 0.80, gray) * 2.0));
        fixed grayArea_3 = saturate((smoothstep(0.60, 0.70, gray) * 2.0));
        fixed grayArea_2 = saturate((smoothstep(0.45, 0.60, gray) * 2.0));
        fixed grayArea_1 = saturate((smoothstep(0.35, 0.45, gray) * 2.0));
        fixed grayArea_0 = saturate((smoothstep(0.95, 1.00, gray_oneminus) * 2.0));
        
        fixed fillArea_5 = grayArea_5;
        fixed fillArea_4 = grayArea_4 - grayArea_5;
        fixed fillArea_3 = grayArea_3 - grayArea_4;
        fixed fillArea_2 = grayArea_2 - grayArea_3;
        fixed fillArea_1 = grayArea_1 - grayArea_2;
        fixed fillArea_0 = grayArea_0;
        
        blackArea = fillArea_0;
        skinArea = fillArea_1;
        
        color = _DiscolorationColor_5 * fillArea_5 + _DiscolorationColor_4 * fillArea_4 +
        _DiscolorationColor_3 * fillArea_3 + _DiscolorationColor_2 * fillArea_2 +
        _DiscolorationColor_1 * fillArea_1 + _DiscolorationColor_0 * fillArea_0
        ;
        
        fixed hdr = max(max(color.r, color.g), color.b) ;
        color.a = hdr - 1.0;
    }
#endif

#if IS_LITPASS
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
#endif
void GetDissloveInput(float4 vertex, float3 normal, half4 _ST, out half4 OSuv1, out half4 OSuv2, out half3 OSuvMask)
{
    _ObjectLeft = fmod(_ObjectLeft, 3.0);
    _ObjectUp = fmod(_ObjectUp, 3.0);
    half3x3 identity = half3x3(half3(1.0, 0.0, 0.0), half3(0.0, 1.0, 0.0), half3(0.0, 0.0, 1.0));
    //Projection UV Texcoord
    half3 maskDir = mul(identity, vertex.xyz);
    half3 leftDir = maskDir * _NegativeDiretionLeft.xyz;
    half3 upDir = maskDir * _NegativeDiretionUp.xyz;
    half trueLeft = leftDir.x * saturate(1.0 - _ObjectLeft) + leftDir.y * saturate(1.0 - abs(_ObjectLeft - 1.0)) + leftDir.z * saturate(1.0 - abs(_ObjectLeft - 2.0)) + _ST.z;
    half trueUp = upDir.x * saturate(1.0 - _ObjectUp) + upDir.y * saturate(1.0 - abs(_ObjectUp - 1.0)) + upDir.z * saturate(1.0 - abs(_ObjectUp - 2.0)) + _ST.w;
    
    OSuv1.xy = maskDir.xy * _ST.xy + _ST.zw;
    OSuv1.zw = maskDir.xz * _ST.xy + _ST.zw;
    OSuv2.xy = maskDir.yz * _ST.xy + _ST.zw;
    
    //Disslove Direction
    OSuv2.zw = rotate2D(half2(trueLeft, trueUp) * float2(1.0, 1.0), 0.0, _DissliveAngle * 0.0174532925194444) * 0.5;
    OSuvMask.xyz = abs(mul(identity, normal));
}

half GetDissloveAlpha(VertexOutput i, half value, sampler2D _EffectiveMap, out half edgeArea, out half4 effectiveMask)
{
    effectiveMask = 0.0;
    half mask_x = tex2D(_EffectiveMap, i.OSuv1.xy).r;
    half mask_y = tex2D(_EffectiveMap, i.OSuv1.zw).r;
    half mask_z = tex2D(_EffectiveMap, i.OSuv2.xy).r;
    effectiveMask += mask_x * i.OSuvMask.x;
    effectiveMask += mask_y * i.OSuvMask.y;
    effectiveMask += mask_z * i.OSuvMask.z;
    
    half overArea = saturate(effectiveMask - 1.0);
    effectiveMask = lerp(effectiveMask, mask_x, overArea);
    
    half directionExpend = 0.6;
    value *= lerp(1.0, directionExpend + 0.05, _DissliveWithDiretion);
    half alphaMinus = 1.0 - value;
    
    half blend1 = linearstep(alphaMinus - 0.3, alphaMinus + 0.3, (1.0 - effectiveMask.r + 0.3 * (value - 0.5) * 2.0));
    half blend2 = linearstep(alphaMinus - directionExpend, alphaMinus, (1.0 - (i.OSuv2.w + 0.5) + directionExpend * (value - 0.5) * 2.0));
    //blend2 /= directionExpend;
    blend2 *= _DissliveWithDiretion;
    half x1 = smoothstepBetterPerformace(0.5, 0.6, max(blend1, blend2 + blend1) * max(1.0 - _DissliveWithDiretion, blend2), 10.0);
    half x2 = smoothstepBetterPerformace(0.45, 0.5, max(blend1, blend2 + blend1) * max(1.0 - _DissliveWithDiretion, blend2), 10.0);
    //x = saturate_good_performace(x);
    edgeArea = x2 - x1;
    return x2;
}