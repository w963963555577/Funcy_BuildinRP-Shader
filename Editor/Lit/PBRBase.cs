// Unity C# reference source
// Copyright (c) Unity Technologies. For terms of use, see
// https://unity3d.com/legal/licenses/Unity_Reference_Only_License

using System;
using UnityEngine;

namespace UnityEditor.Rendering.Funcy.BuildinRP.ShaderGUI
{    
    internal class LitShader : BaseShaderGUI
    {
        MaterialProperty sssColor { get; set; }
        MaterialProperty sssMap { get; set; }
        MaterialProperty sssRadius { get; set; }
        MaterialProperty sss { get; set; }

        MaterialProperty rimLightColor { get; set; }
        MaterialProperty maxHDR { get; set; }
        
        MaterialProperty rimLightSoftness { get; set; }

        public override void FindProperties(MaterialProperty[] properties)
        {
            base.FindProperties(properties);

            sss = FindProperty("_SubsurfaceScattering", properties);
            sssRadius = FindProperty("_SubsurfaceRadius", properties);
            sssColor = FindProperty("_SubsurfaceColor", properties);
            sssMap = FindProperty("_SubsurfaceMap", properties);

            rimLightColor = FindProperty("_RimLightColor", properties);
            rimLightSoftness = FindProperty("_RimLightSoftness", properties);
            maxHDR = FindProperty("_MaxHDR", properties);
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            base.OnGUI(materialEditor, props);
        }

        public override void ShaderPropertiesGUI(Material material)
        {
            base.ShaderPropertiesGUI(material);

            DrawArea("Subsurface Scattering", () => {
                m_MaterialEditor.ShaderProperty(sss, sss.displayName);
                m_MaterialEditor.TexturePropertySingleLine(sssMap.displayName.ToGUIContent(), sssMap, sssColor, sssRadius);
            });

            DrawArea("Rim Lighting", () => {
                m_MaterialEditor.ShaderProperty(rimLightColor, rimLightColor.displayName);
                m_MaterialEditor.ShaderProperty(rimLightSoftness, rimLightSoftness.displayName);
                m_MaterialEditor.ShaderProperty(maxHDR, maxHDR.displayName);

                //materialEditor.TexturePropertySingleLine(sssMap.displayName.ToGUIContent(), sssMap, sssColor, sssRadius);
            });

            DrawArea("Advanced", () =>
            {
                // NB renderqueue editor is not shown on purpose: we want to override it based on blend mode
                GUILayout.Label(Styles.advancedText, EditorStyles.boldLabel);
                m_MaterialEditor.EnableInstancingField();
                m_MaterialEditor.DoubleSidedGIField();

                GUILayout.Space(10);
            });

           
        }
    }
} // namespace UnityEditor