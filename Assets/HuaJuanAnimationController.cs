using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class HuaJuanAnimationController : MonoBehaviour
{
    public GameObject[] gameObjects;

    public void PlayAnimations()
    {
        if (gameObjects.Length > 0)
        {
            foreach (var obj in gameObjects)
            {
                obj.GetComponent<Animation>().Play();
            }
        }
        else
        {
            Debug.Log("Empty !");
        }
    }
}
