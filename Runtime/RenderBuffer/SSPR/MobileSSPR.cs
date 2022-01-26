using System.Collections;
using System.Collections.Generic;

using UnityEngine;
using UnityEngine.Rendering;

using System.Linq;

#if UNITY_EDITOR
using UnityEditor;
#endif

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
[RequireComponent(typeof(Camera))]
public class MobileSSPR : MonoBehaviour
{
    Camera cam;
    CommandBuffer cmd;

    const int SHADER_NUMTHREAD_X = 8; //must match compute shader's [numthread(x)]
    const int SHADER_NUMTHREAD_Y = 8; //must match compute shader's [numthread(y)]

    static readonly int _SSPR_ColorTexture_pid = Shader.PropertyToID("_SSPRCamera_ColorTexture");
    RenderTargetIdentifier _SSPR_ColorTexture_rti = new RenderTargetIdentifier(_SSPR_ColorTexture_pid);

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

    public void Active(bool isEnable)
    {
#if UNITY_EDITOR
        if (settings.heightFixerData == null)
            settings.heightFixerData = AssetDatabase.LoadAssetAtPath<MobileSSPRHeightFixerData>("Packages/com.buildinrp.shader.funcy/Runtime/RenderBuffer/SSPR/SSRHeightFixerDatas/Default.asset");
#endif
    }

    public void Configure()
    {
        cmd = CommandBufferPool.Get("_SSPR");

        RenderTextureDescriptor rtd = new RenderTextureDescriptor(GetRTWidth(), GetRTHeight(), RenderTextureFormat.Default, 0, 0);

        rtd.sRGB = false; //don't need gamma correction when sampling these RTs, it is linear data already because it will be filled by screen's linear data
        rtd.enableRandomWrite = true; //using RWTexture2D in compute shader need to turn on this

        
        //color RT
        bool shouldUseHDRColorRT = settings.UseHDR;

        cmd.GetTemporaryRT(_SSPR_ColorTexture_pid, rtd);
        cmd.Blit(BuiltinRenderTextureType.CurrentActive, _SSPR_ColorTexture_rti);

        rtd.colorFormat = shouldUseHDRColorRT ? RenderTextureFormat.ARGBHalf : RenderTextureFormat.ARGB32; //we need alpha! (usually LDR is enough, ignore HDR is acceptable for reflection)
        cmd.GetTemporaryRT(_SSPR_ColorRT_pid, rtd);

        rtd.colorFormat = RenderTextureFormat.RFloat;
        cmd.GetTemporaryRT(_SSPR_PosWSyRT_pid, rtd);

    }

    public void Execude(CommandBuffer cmd)
    {
        var colorTarget = _SSPR_ColorTexture_rti;
        var depthTarget = Shader.GetGlobalTexture("_CameraDepthTexture");
        var colorDataTex = _SSPR_ColorRT_rti;

        int dispatchThreadGroupXCount = GetRTWidth() / SHADER_NUMTHREAD_X; //divide by shader's numthreads.x
        int dispatchThreadGroupYCount = GetRTHeight() / SHADER_NUMTHREAD_Y; //divide by shader's numthreads.y
        int dispatchThreadGroupZCount = 1; //divide by shader's numthreads.z

        var cs = settings.SSPR_computeShader;

        cmd.SetComputeVectorParam(cs, Shader.PropertyToID("_RTSize"), new Vector2(GetRTWidth(), GetRTHeight()));
        cmd.SetComputeFloatParam(cs, Shader.PropertyToID("_HorizontalPlaneHeightWS"), settings.horizontalReflectionPlaneHeightWS);

        var heightFixerData = settings.heightFixerData;
        cmd.SetComputeVectorParam(cs, Shader.PropertyToID("_WorldSize_Offest_HeightIntensity"), heightFixerData.worldSize_Offest_HeightIntensity);

        cmd.SetComputeFloatParam(cs, Shader.PropertyToID("_FadeOutScreenBorderWidthVerticle"), settings.fadeOutScreenBorderWidthVerticle);
        cmd.SetComputeFloatParam(cs, Shader.PropertyToID("_FadeOutScreenBorderWidthHorizontal"), settings.fadeOutScreenBorderWidthHorizontal);
        cmd.SetComputeVectorParam(cs, Shader.PropertyToID("_CameraDirection"), cam.transform.forward);
        cmd.SetComputeFloatParam(cs, Shader.PropertyToID("_ScreenLRStretchIntensity"), settings.screenLRStretchIntensity);
        cmd.SetComputeFloatParam(cs, Shader.PropertyToID("_ScreenLRStretchThreshold"), settings.screenLRStretchThreshold);
        cmd.SetComputeVectorParam(cs, Shader.PropertyToID("_FinalTintColor"), settings.tintColor);

        Camera camera = cam;
        Matrix4x4 viewMatrix = camera.worldToCameraMatrix;
        VP = GL.GetGPUProjectionMatrix(camera.projectionMatrix, true) * viewMatrix;
        cmd.SetComputeMatrixParam(cs, "_VPMatrix", VP);

        Matrix4x4 projMatrix = GL.GetGPUProjectionMatrix(camera.projectionMatrix, false);
        Matrix4x4 viewProjMatrix = projMatrix * viewMatrix;
        invViewProjMatrix = Matrix4x4.Inverse(viewProjMatrix);
        cmd.SetComputeMatrixParam(cs, "_InverseVPMatrix", invViewProjMatrix);


        var posDataTex = Shader.GetGlobalTexture(_SSPR_PosWSyRT_pid);

        ////////////////////////////////////////////////
        //Mobile Path (Android GLES / Metal)
        ////////////////////////////////////////////////

        int kernel_MobilePathSinglePassColorRTDirectResolve = cs.FindKernel("MobilePathSinglePassColorRTDirectResolve");
        cmd.SetComputeTextureParam(cs, kernel_MobilePathSinglePassColorRTDirectResolve, "ColorRT", colorDataTex);
        cmd.SetComputeTextureParam(cs, kernel_MobilePathSinglePassColorRTDirectResolve, "PosWSyRT", _SSPR_PosWSyRT_rti);
        cmd.SetComputeTextureParam(cs, kernel_MobilePathSinglePassColorRTDirectResolve, "_CameraOpaqueTexture", colorTarget);
        cmd.SetComputeTextureParam(cs, kernel_MobilePathSinglePassColorRTDirectResolve, "_CameraDepthTexture", depthTarget);
        cmd.SetComputeTextureParam(cs, kernel_MobilePathSinglePassColorRTDirectResolve, "_HorizontalHeightFixerMap", heightFixerData.horizontalHeightFixerMap);
        cmd.DispatchCompute(cs, kernel_MobilePathSinglePassColorRTDirectResolve, dispatchThreadGroupXCount, dispatchThreadGroupYCount, dispatchThreadGroupZCount);



        //optional shared pass to improve result only: fill RT hole
        if (settings.ApplyFillHoleFix)
        {
            int kernel_FillHoles = cs.FindKernel("FillHoles");
            cmd.SetComputeTextureParam(cs, kernel_FillHoles, "ColorRT", colorDataTex);
            cmd.DispatchCompute(cs, kernel_FillHoles, Mathf.CeilToInt(dispatchThreadGroupXCount / 2f), Mathf.CeilToInt(dispatchThreadGroupYCount / 2f), dispatchThreadGroupZCount);
        }

    }

    /// Cleanup any allocated resources that were created during the execution of this render pass.
    public void FrameCleanup(CommandBuffer cmd)
    {        
        cmd.ReleaseTemporaryRT(_SSPR_ColorRT_pid);
        cmd.ReleaseTemporaryRT(_SSPR_PosWSyRT_pid);
        cmd.Clear();
        cmd.Release();
    }

    void Awake()
    {
        cam = GetComponent<Camera>();
    }

    void OnEnable()
    {
        Active(true);
    }

    void OnDisable()
    {
        Active(false);
    }

    void OnPreCull() { Configure(); }
    void OnPreRender() { Execude(cmd); }
    void OnPostRender()
    {
        Graphics.ExecuteCommandBuffer(cmd);
        FrameCleanup(cmd);
    }

#if UNITY_EDITOR
    public System.Action onGUI;
    private void OnGUI()
    {
        onGUI?.Invoke();        
    }
#endif

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

    Matrix4x4 VP;
    Matrix4x4 invViewProjMatrix;
}
#if UNITY_EDITOR
[InitializeOnLoad]
public class MobileSSPR_Editor : Editor
{
    static EditorWindow gameView;
    static MobileSSPR_Editor()
    {
        SceneView.duringSceneGui += DebugBufferInSceneView;
    }
    
    MobileSSPR data;
    private void OnEnable()
    {
        data = target as MobileSSPR;
        data.onGUI += DebugBufferInGameView;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
    }

    private void OnDisable()
    {
        data.onGUI -= DebugBufferInGameView;
    }
    public static void DebugBufferInSceneView(SceneView sceneView)
    {
        if (Selection.activeGameObject == null) return;
        var sspr = Selection.activeGameObject.GetComponent<MobileSSPR>();
        if (!sspr) return;
        if (!sspr.debugBufferInSceneView) return;

        gameView = Resources.FindObjectsOfTypeAll<EditorWindow>().ToList().Find(x => x.GetType().Name == "GameView");
        
        var sceneRect = sceneView.position;

        Handles.BeginGUI();

        OnGUI(sceneRect);
        
        Handles.EndGUI();
    }

    public static void DebugBufferInGameView()
    {
        if (Selection.activeGameObject == null) return;
        var sspr = Selection.activeGameObject.GetComponent<MobileSSPR>();
        if (!sspr) return;
        if (!sspr.debugBufferInSceneView) return;
        gameView = Resources.FindObjectsOfTypeAll<EditorWindow>().ToList().Find(x => x.GetType().Name == "GameView");
        if (!gameView) return;

        OnGUI(gameView.position);
    }

    static void OnGUI(Rect rect)
    {
        var colorTex = Shader.GetGlobalTexture("_SSPRCamera_ColorTexture");
        var currentRect = rect;
        currentRect.size = rect.size * 0.2f;
        currentRect.position = Vector2.zero;
        GUI.DrawTexture(currentRect, colorTex);

        var depthTex = Shader.GetGlobalTexture("_CameraDepthTexture");
        currentRect.x += rect.size.x * 0.2f;
        GUI.DrawTexture(currentRect, depthTex);

        var posWSy = Shader.GetGlobalTexture("_MobileSSPR_PosWSyRT");
        currentRect.x += rect.size.x * 0.2f;
        GUI.DrawTexture(currentRect, posWSy);

        var ssr = Shader.GetGlobalTexture("_MobileSSPR_ColorRT");
        currentRect.x += rect.size.x * 0.2f;
        GUI.DrawTexture(currentRect, ssr);

    }
    
    
}
#endif
