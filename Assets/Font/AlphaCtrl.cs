using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AlphaCtrl : MonoBehaviour
{
    public float alpha = 0.0f;
    private Material mat;
    void Start()
    {
        mat = GetComponent<MeshRenderer>().material;
    }

    void Update()
    {
        if (alpha < 1.0f)
            mat.SetColor("_BaseColor", new Color(alpha, alpha, alpha, alpha));
    }
}
