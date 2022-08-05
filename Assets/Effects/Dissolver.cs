using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Dissolver : MonoBehaviour
{
    [Range(1.1f, 0.0f)]
    public float dissolverValue;

    // Update is called once per frame
    void Update()
    {
        Renderer[] renders = GetComponentsInChildren<Renderer>();
        for (int i = 0; i < renders.Length; i++)
            renders[i].material.SetFloat("_DissolverController", dissolverValue);
    }
}
