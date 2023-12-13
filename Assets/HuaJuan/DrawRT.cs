using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class DrawRT : MonoBehaviour
{
    public RenderTexture rt;
    public Material mat;

    void Update()
    {
        if (rt != null && mat != null)
        {
            //rt.Release();
            Graphics.Blit(Texture2D.blackTexture, rt, mat);
        } 
    }
}
