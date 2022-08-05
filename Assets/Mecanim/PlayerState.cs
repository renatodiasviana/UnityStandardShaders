using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerState : MonoBehaviour
{
    private void OnTriggerEnter(Collider other)
    {
        if (other.tag == "Enemy")
            GetComponent<Animator>().SetInteger("State", 1);

        GetComponent<Animator>().SetFloat("Angle", 0.15f);
    }
}
