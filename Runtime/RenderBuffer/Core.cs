
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif
namespace UnityEngine.Rendering.Funcy.BuildinRP
{
    using System.Linq;
    using static UnityEngine.Rendering.Funcy.BuildinRP.Core;

    public class Core
    {
        

    }


    public static class Extension
    {
        public static CommandBuffer InitCommandBuffer(this Camera camera, string name, int propertyID, RenderTextureDescriptor rtd, RenderTargetIdentifier id, CameraEvent cameraEvent, BuiltinRenderTextureType type)
        {
            CommandBuffer cmd = camera.GetCommandBuffers(cameraEvent).ToList().Find(c => c.name == name);
            if (cmd == null) cmd = new CommandBuffer();
            cmd.name = name;
            cmd.GetTemporaryRT(propertyID, rtd);
            if (type != BuiltinRenderTextureType.None)
                cmd.Blit(type, id);
                        
            cmd.SetGlobalTexture(propertyID, id);
            
            if (!camera.CommandBufferExist(cmd, cameraEvent))
                camera.AddCommandBuffer(cameraEvent, cmd);

            return cmd;
        }



        public static bool CommandBufferExist(this Camera camera, CommandBuffer cb, CameraEvent cameraEvent)
        {
            return camera.GetCommandBuffers(cameraEvent).ToList().Contains(cb);
        }


    }
}