using System.Collections;
using System.Collections.Generic;
using UnityEngine;

class MyObject
{
    public int Bola = 0;
}


public class Teste : MonoBehaviour
{
    List<MyObject> myList = new List<MyObject>();

    // Start is called before the first frame update
    void Start()
    {
        float moveSpeed = 1.0f * (true ? 0.1f : 1f);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
