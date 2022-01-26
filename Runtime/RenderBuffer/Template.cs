using System.Collections;
using System.Collections.Generic;

using UnityEngine;
using UnityEngine.Rendering;

using UnityEngine.SceneManagement;

using System.Linq;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
#endif


public class Template : MonoBehaviour
{
    Camera cam;
    CommandBuffer cmd;

    public void Active(bool isEnable)
    {
        cam = GetComponent<Camera>();
    }

    //Render Code In this Area
    public void Configure()
    {

    }

    public void Execude(CommandBuffer cmd)
    {

    }

    /// Cleanup any allocated resources that were created during the execution of this render pass.
    public void FrameCleanup(CommandBuffer cmd)
    {

    }
    //Render Code In this Area

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
}
