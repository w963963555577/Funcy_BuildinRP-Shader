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
        MaterialProperty subsurfaceMap { get; set; }
        MaterialProperty subsurfaceRadius { get; set; }
        MaterialProperty subsurfaceScattering { get; set; }

        MaterialProperty rimLightColor { get; set; }
        MaterialProperty maxHDR { get; set; }
        
        MaterialProperty rimLightSoftness { get; set; }


        //Discoloration System
        MaterialProperty discolorationSystem { get; set; }
        MaterialProperty discolorationColorCount { get; set; }
        MaterialProperty discolorationColor_0 { get; set; }
        MaterialProperty discolorationColor_1 { get; set; }
        MaterialProperty discolorationColor_2 { get; set; }
        MaterialProperty discolorationColor_3 { get; set; }
        MaterialProperty discolorationColor_4 { get; set; }
        MaterialProperty discolorationColor_5 { get; set; }
        MaterialProperty[] discolorationColorList = new MaterialProperty[6];


        MaterialProperty effectiveMap { get; set; }
        MaterialProperty effectiveColor { get; set; }

        MaterialProperty srcBlend { get; set; }
        MaterialProperty dstBlend { get; set; }

        public override void FindProperties(MaterialEditor materialEditor, MaterialProperty[] props, UnityEditor.ShaderGUI data = null)                
        {
            data = this;
            base.FindProperties(materialEditor, props, data);
            discolorationColorList = new MaterialProperty[] {
                discolorationColor_0, discolorationColor_1,discolorationColor_2, discolorationColor_3,
                discolorationColor_4, discolorationColor_5
            };
        }

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
        {
            base.OnGUI(materialEditor, props);
        }

        public override void ShaderPropertiesGUI(Material material)
        {
            base.ShaderPropertiesGUI(material);
            var mat = material;

            DrawArea("Subsurface Scattering", () => {
                m_MaterialEditor.ShaderProperty(subsurfaceScattering, subsurfaceScattering.displayName);
                m_MaterialEditor.TexturePropertySingleLine(subsurfaceMap.displayName.ToGUIContent(), subsurfaceMap, sssColor, subsurfaceRadius);
            });


            DrawArea("Effective", () =>
            {
                GUILayout.BeginVertical("Box");
                GUILayout.Label("Effective Disslove", EditorStyles.boldLabel);
                GUILayout.BeginVertical("Box");
                {
                    materialEditor.TexturePropertySingleLine(effectiveMap.displayName.ToGUIContent(), effectiveMap, effectiveColor);                    
                    GUILayout.Space(10);
                }
                GUILayout.EndVertical();
                GUILayout.Space(10);
                GUILayout.EndVertical();

                GUILayout.BeginVertical("Box");
                GUILayout.Label("Blend Mode", EditorStyles.boldLabel);
                GUILayout.BeginVertical("Box");
                {
                    materialEditor.ShaderProperty(srcBlend, "");
                    materialEditor.ShaderProperty(dstBlend, "");
                }
                GUILayout.EndVertical();
                GUILayout.Space(10);
                GUILayout.EndVertical();


            });


            DrawArea("Rim Lighting", () => {
                m_MaterialEditor.ShaderProperty(rimLightColor, rimLightColor.displayName);
                m_MaterialEditor.ShaderProperty(rimLightSoftness, rimLightSoftness.displayName);
                m_MaterialEditor.ShaderProperty(maxHDR, maxHDR.displayName);

                //materialEditor.TexturePropertySingleLine(sssMap.displayName.ToGUIContent(), sssMap, sssColor, sssRadius);
            });

            DrawArea("Discoloration System", () =>
            {
                materialEditor.ShaderProperty(discolorationSystem, "Enable");
                EditorGUI.BeginDisabledGroup(mat.GetFloat("_DiscolorationSystem") == 0.0);
                materialEditor.ShaderProperty(discolorationColorCount, discolorationColorCount.displayName.ToGUIContent());
                mat.SetFloat("_DiscolorationColorCount", Mathf.Floor(mat.GetFloat("_DiscolorationColorCount")));
                byte[] discolorationLabelByte = new byte[] { 0, 142, 170, 198, 227, 255 };
                string[] discolorationLabel = new string[] { "No", "Skin", "Hair", "Cloth" , "Cloth" , "Cloth" };
                int[] discolorationLabelNumber = new int[] { -1, -1, -1, 1, 2, 3};
                for (int i = 0; i < mat.GetFloat("_DiscolorationColorCount"); i++)
                {
                    if (i == 0)
                    {
                        GUILayout.Label(" ");
                        var currentRect = GUILayoutUtility.GetLastRect();
                        EditorGUI.LabelField(currentRect, discolorationLabel[i], EditorStyles.boldLabel);
                        currentRect.x += 60;
                        EditorGUI.LabelField(currentRect, "");
                        currentRect.x += 20;
                        EditorGUI.LabelField(currentRect, string.Format("RGB= {0}", discolorationLabelByte[i]));
                        currentRect.x -= 80;
                        currentRect.x = currentRect.x + EditorGUIUtility.currentViewWidth - 165;
                        EditorGUI.LabelField(currentRect, "此　區　不　變　色", EditorStyles.boldLabel);
                    }
                    else
                    {
                        materialEditor.ShaderProperty(discolorationColorList[i], " ");
                        var currentRect = GUILayoutUtility.GetLastRect();
                        EditorGUI.LabelField(currentRect, discolorationLabel[i], EditorStyles.boldLabel);
                        currentRect.x += 60;
                        EditorGUI.LabelField(currentRect, (discolorationLabelNumber[i] > 0 ? discolorationLabelNumber[i].ToString() : ""));
                        currentRect.x += 20;
                        EditorGUI.LabelField(currentRect, string.Format("RGB= {0}", discolorationLabelByte[i]));
                    }
                }
                EditorGUI.EndDisabledGroup();
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