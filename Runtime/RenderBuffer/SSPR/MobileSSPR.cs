using System.Collections;
using System.Collections.Generic;

using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Funcy.BuildinRP;
using UnityEngine.SceneManagement;

using System.Linq;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
#endif
[ExecuteInEditMode, ImageEffectAllowedInSceneView]
[RequireComponent(typeof(Camera))]
public class MobileSSPR : MonoBehaviour
{    
    Camera cam;

    CommandBuffer colorCmd;

    const int SHADER_NUMTHREAD_X = 8; //must match compute shader's [numthread(x)]
    const int SHADER_NUMTHREAD_Y = 8; //must match compute shader's [numthread(y)]


    static readonly int ID_CameraColorTexture = Shader.PropertyToID("_SSPRCamera_ColorTexture");
    RenderTargetIdentifier _CameraColorTexture = new RenderTargetIdentifier(ID_CameraColorTexture);

    static readonly int _SSPR_PosWSyRT_pid = Shader.PropertyToID("_MobileSSPR_PosWSyRT");    
    RenderTargetIdentifier _SSPR_PosWSyRT_rti = new RenderTargetIdentifier(_SSPR_PosWSyRT_pid);

    static readonly int _SSPR_ColorRT_pid = Shader.PropertyToID("_MobileSSPR_ColorRT");
    RenderTargetIdentifier _SSPR_ColorRT_rti = new RenderTargetIdentifier(_SSPR_ColorRT_pid);


    int GetRTHeight()
    {
        return Mathf.CeilToInt(settings.RT_height / (float)SHADER_NUMTHREAD_Y) * SHADER_NUMTHREAD_Y;
    }
    int GetRTWidth()
    {
        float aspect = (float)Screen.width / Screen.height;
        return Mathf.CeilToInt(GetRTHeight() * aspect / (float)SHADER_NUMTHREAD_X) * SHADER_NUMTHREAD_X;
    }

    public void Configure(CommandBuffer cmd)
    {
        RenderTextureDescriptor rtd = new RenderTextureDescriptor(GetRTWidth(), GetRTHeight(), RenderTextureFormat.Default, 0, 0);

        rtd.sRGB = false; //don't need gamma correction when sampling these RTs, it is linear data already because it will be filled by screen's linear data
        rtd.enableRandomWrite = true; //using RWTexture2D in compute shader need to turn on this

        //color RT
        bool shouldUseHDRColorRT = settings.UseHDR;

        rtd.colorFormat = shouldUseHDRColorRT ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB32; //we need alpha! (usually LDR is enough, ignore HDR is acceptable for reflection)
        cmd.GetTemporaryRT(_SSPR_ColorRT_pid, rtd);

        rtd.colorFormat = RenderTextureFormat.RFloat;
        cmd.GetTemporaryRT(_SSPR_PosWSyRT_pid, rtd);

        aspectRadio = new Vector2Int(Screen.width, Screen.height);
    }
    /// Cleanup any allocated resources that were created during the execution of this render pass.
    public void FrameCleanup(CommandBuffer cmd)
    {
        cmd.ReleaseTemporaryRT(_SSPR_ColorRT_pid);
        cmd.ReleaseTemporaryRT(_SSPR_PosWSyRT_pid);        
    }


    /// <summary>
    /// If user enabled PerPlatformAutoSafeGuard, this function will return true if we should use mobile path
    /// </summary>
    bool ShouldUseSinglePassUnsafeAllowFlickeringDirectResolve()
    {
        if (settings.EnablePerPlatformAutoSafeGuard)
        {
            //if RInt RT is not supported, use mobile path
            if (!SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RInt))
                return true;

            //tested Metal(even on a Mac) can't use InterlockedMin().
            //so if metal, use mobile path
            if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Metal)
                return true;
#if UNITY_EDITOR
            //PC(DirectX) can use RenderTextureFormat.RInt + InterlockedMin() without any problem, use Non-Mobile path.
            //Non-Mobile path will NOT produce any flickering
            if (SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D11 || SystemInfo.graphicsDeviceType == GraphicsDeviceType.Direct3D12)
                return false;
#elif UNITY_ANDROID
                //- samsung galaxy A70(Adreno612) will fail if use RenderTextureFormat.RInt + InterlockedMin() in compute shader
                //- but Lenovo S5(Adreno506) is correct, WTF???
                //because behavior is different between android devices, we assume all android are not safe to use RenderTextureFormat.RInt + InterlockedMin() in compute shader
                //so android always go mobile path
                return true;
#endif
        }
        //let user decide if we still don't know the correct answer
        return !settings.ShouldRemoveFlickerFinalControl;
    }


    private void OnEnable()
    {
        cam = GetComponent<Camera>();
        
        RenderTextureDescriptor rtd = new RenderTextureDescriptor(GetRTWidth(), GetRTHeight(), RenderTextureFormat.Default, 0, 0);
        rtd.sRGB = false; //don't need gamma correction when sampling these RTs, it is linear data already because it will be filled by screen's linear data
        rtd.enableRandomWrite = true; //using RWTexture2D in compute shader need to turn on this
        
        colorCmd = cam.InitCommandBuffer("_SSPRCamera_ColorTexture", ID_CameraColorTexture, rtd, _CameraColorTexture, CameraEvent.AfterForwardAlpha, BuiltinRenderTextureType.CameraTarget);
        
        if (cam.cameraType == CameraType.Game)
        {
            Configure(colorCmd);
        }

#if UNITY_EDITOR
        if (settings.heightFixerData == null)
            settings.heightFixerData = AssetDatabase.LoadAssetAtPath<MobileSSPRHeightFixerData>("Packages/com.buildinrp.shader.funcy/Runtime/RenderBuffer/SSPR/SSRHeightFixerDatas/Default.asset");
#endif
    }

    private void OnDisable()
    {
        if (colorCmd == null) return;
        cam.RemoveCommandBuffer(CameraEvent.AfterForwardAlpha, colorCmd);
        colorCmd.Clear();
        colorCmd.Release();
    }

    Vector2Int aspectRadio;

    private void OnPreCull()
    {
        if (cam.cameraType == CameraType.SceneView)
        {
            Configure(colorCmd);
        }
        if (cam.cameraType == CameraType.Game)
        {
            var targetScreenSize = new Vector2Int(Screen.width, Screen.height);
            if (aspectRadio != targetScreenSize)
            {
                aspectRadio = targetScreenSize;
                Configure(colorCmd);
            }
        }
    }

    Matrix4x4 VP;
    Matrix4x4 invViewProjMatrix;
    private void OnPreRender()
    {
        var colorTarget = Shader.GetGlobalTexture(ID_CameraColorTexture);
        
        var depthTarget = Shader.GetGlobalTexture("_CameraDepthTexture");
        
        var colorDataTex = Shader.GetGlobalTexture(_SSPR_ColorRT_pid);

        int dispatchThreadGroupXCount = GetRTWidth() / SHADER_NUMTHREAD_X; //divide by shader's numthreads.x
        int dispatchThreadGroupYCount = GetRTHeight() / SHADER_NUMTHREAD_Y; //divide by shader's numthreads.y
        int dispatchThreadGroupZCount = 1; //divide by shader's numthreads.z

        var cs = settings.SSPR_computeShader;

        cs.SetVector(Shader.PropertyToID("_RTSize"), new Vector2(GetRTWidth(), GetRTHeight()));
        cs.SetFloat(Shader.PropertyToID("_HorizontalPlaneHeightWS"), settings.horizontalReflectionPlaneHeightWS);

        var heightFixerData = settings.heightFixerData;
        cs.SetVector(Shader.PropertyToID("_WorldSize_Offest_HeightIntensity"), heightFixerData.worldSize_Offest_HeightIntensity);

        cs.SetFloat(Shader.PropertyToID("_FadeOutScreenBorderWidthVerticle"), settings.fadeOutScreenBorderWidthVerticle);
        cs.SetFloat(Shader.PropertyToID("_FadeOutScreenBorderWidthHorizontal"), settings.fadeOutScreenBorderWidthHorizontal);
        cs.SetVector(Shader.PropertyToID("_CameraDirection"), cam.transform.forward);
        cs.SetFloat(Shader.PropertyToID("_ScreenLRStretchIntensity"), settings.screenLRStretchIntensity);
        cs.SetFloat(Shader.PropertyToID("_ScreenLRStretchThreshold"), settings.screenLRStretchThreshold);
        cs.SetVector(Shader.PropertyToID("_FinalTintColor"), settings.tintColor);

        Camera camera = cam;
        Matrix4x4 viewMatrix = camera.worldToCameraMatrix;
        VP = GL.GetGPUProjectionMatrix(camera.projectionMatrix, true) * viewMatrix;
        cs.SetMatrix("_VPMatrix", VP);

        Matrix4x4 projMatrix = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false);
        Matrix4x4 viewProjMatrix = projMatrix * viewMatrix;
        invViewProjMatrix = Matrix4x4.Inverse(viewProjMatrix);
        cs.SetMatrix("_InverseVPMatrix", invViewProjMatrix);

        if (colorDataTex == null) return;
        
        var posDataTex = Shader.GetGlobalTexture(_SSPR_PosWSyRT_pid);

        ////////////////////////////////////////////////
        //Mobile Path (Android GLES / Metal)
        ////////////////////////////////////////////////

        if (posDataTex != null)
        {
            
            int kernel_MobilePathSinglePassColorRTDirectResolve = cs.FindKernel("MobilePathSinglePassColorRTDirectResolve");
            cs.SetTexture(kernel_MobilePathSinglePassColorRTDirectResolve, "ColorRT", colorDataTex);
            cs.SetTexture(kernel_MobilePathSinglePassColorRTDirectResolve, "PosWSyRT", posDataTex);
            cs.SetTexture(kernel_MobilePathSinglePassColorRTDirectResolve, "_CameraOpaqueTexture", colorTarget);
            cs.SetTexture(kernel_MobilePathSinglePassColorRTDirectResolve, "_CameraDepthTexture", depthTarget);
            cs.SetTexture(kernel_MobilePathSinglePassColorRTDirectResolve, "_HorizontalHeightFixerMap", heightFixerData.horizontalHeightFixerMap);
            cs.Dispatch(kernel_MobilePathSinglePassColorRTDirectResolve, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);


        }

        //optional shared pass to improve result only: fill RT hole
        if (settings.ApplyFillHoleFix)
        {
            int kernel_FillHoles = cs.FindKernel("FillHoles");
            cs.SetTexture(kernel_FillHoles, "ColorRT", colorTarget);
            cs.Dispatch(kernel_FillHoles, Mathf.CeilToInt(dispatchThreadGroupXCount / 2f), Mathf.CeilToInt(dispatchThreadGroupYCount / 2f), dispatchThreadGroupZCount);
        }
    }
    private void OnPostRender()
    {
        if (cam.cameraType == CameraType.SceneView)
        {
            FrameCleanup(colorCmd);
        }        
    }


    #region PassSettings

    public bool debugBufferInSceneView = false;
    [System.Serializable]
    public class PassSettings
    {
        [Header("Settings")]
        public bool ShouldRenderSSPR = true;
        public float horizontalReflectionPlaneHeightWS = 0.1f; //default higher than ground a bit, to avoid ZFighting if user placed a ground plane at y=0

        [System.NonSerialized] public MobileSSPRHeightFixerData selectedHeightFixerData;
        public MobileSSPRHeightFixerData heightFixerData = null;
        [Range(0.01f, 1f)]
        public float fadeOutScreenBorderWidthVerticle = 0.25f;
        [Range(0.01f, 1f)]
        public float fadeOutScreenBorderWidthHorizontal = 0.35f;
        [Range(0, 8f)]
        public float screenLRStretchIntensity = 4;
        [Range(-1f, 1f)]
        public float screenLRStretchThreshold = 0.7f;
        [ColorUsage(true, true)]
        public Color tintColor = Color.white;

        //////////////////////////////////////////////////////////////////////////////////
        [Header("Performance Settings")]
        [Range(128, 1024)]
        [Tooltip("set to 512 or below for better performance, if visual quality lost is acceptable")]
        public int RT_height = 512;
        [Tooltip("can set to false for better performance, if visual quality lost is acceptable")]
        public bool UseHDR = true;
        [Tooltip("can set to false for better performance, if visual quality lost is acceptable")]
        public bool ApplyFillHoleFix = true;
        [Tooltip("can set to false for better performance, if flickering is acceptable")]
        public bool ShouldRemoveFlickerFinalControl = true;

        //////////////////////////////////////////////////////////////////////////////////
        [Header("Danger Zone")]
        [Tooltip("You should always turn this on, unless you want to debug")]
        public bool EnablePerPlatformAutoSafeGuard = true;

        public ComputeShader SSPR_computeShader;
    }
    public PassSettings settings = new PassSettings();

    #endregion
}
#if UNITY_EDITOR
[InitializeOnLoad]
public class MobileSSPR_Editor : Editor
{
    static MobileSSPR_Editor()
    {
        SceneView.duringSceneGui += DebugBuffer;
    }

    MobileSSPR data;
    private void OnEnable()
    {
        data = target as MobileSSPR;
    }
    
    public override void OnInspectorGUI()
    {        
        base.OnInspectorGUI();                
    }

    private void OnDisable()
    {
        
    }
    public static void DebugBuffer(SceneView sceneView)
    {
        if (Selection.activeGameObject == null) return;
        var sspr = Selection.activeGameObject.GetComponent<MobileSSPR>();
        if (!sspr) return;
        if (!sspr.debugBufferInSceneView) return;

        var sceneRect = sceneView.position;

        Handles.BeginGUI();

        var colorTex = Shader.GetGlobalTexture("_SSPRCamera_ColorTexture");
        var currentRect = sceneRect;
        currentRect.size = sceneRect.size * 0.2f;
        currentRect.position = Vector2.zero;
        GUI.DrawTexture(currentRect, colorTex);


        var depthTex = Shader.GetGlobalTexture("_CameraDepthTexture");
        currentRect.x += sceneRect.size.x * 0.2f;
        GUI.DrawTexture(currentRect, depthTex);

        var posWSy = Shader.GetGlobalTexture("_MobileSSPR_PosWSyRT");
        currentRect.x += sceneRect.size.x * 0.2f;
        GUI.DrawTexture(currentRect, posWSy);

        var ssr = Shader.GetGlobalTexture("_MobileSSPR_ColorRT");
        currentRect.x += sceneRect.size.x * 0.2f;
        GUI.DrawTexture(currentRect, ssr);


        Handles.EndGUI();
    }

}
#endif