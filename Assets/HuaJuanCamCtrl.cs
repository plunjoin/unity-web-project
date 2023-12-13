using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HuaJuanCamCtrl : MonoBehaviour
{
    public Transform targetTf;
    public float rotateSpeed = 1.0f;
    public float scrollSpeed = 1.0f;
    public Vector2 minMaxAngle = new Vector2(10.0f, 80.0f);
    public Vector2 minMaxDistance = new Vector2(1.0f, 10.0f);
    public Vector3 defautAngleDistanceOffset = new Vector3(0.0f, 0.0f, 0.0f);
    public float waitTime = 1.0f;
    
    private Transform camParentTf;
    private float time;
    
    void Start()
    {
        camParentTf = new GameObject().transform;
        if (targetTf != null)
            camParentTf.position = targetTf.position;
        this.transform.SetParent(camParentTf);
        camParentTf.eulerAngles = new Vector3(defautAngleDistanceOffset.x, 0.0f, 0.0f);
        camParentTf.position = new Vector3(0.0f, defautAngleDistanceOffset.z, 0.0f);
        this.transform.localPosition = new Vector3(0.0f, 0.0f, defautAngleDistanceOffset.y * -1.0f);
        time = 0.0f;
    }
    void Update()
    {
        if (Input.GetMouseButton(0))
        {
            camParentTf.eulerAngles += new Vector3(Input.GetAxis("Mouse Y") * -1.0f, Input.GetAxis("Mouse X"), 0.0f) * rotateSpeed;
            camParentTf.eulerAngles = new Vector3(Mathf.Clamp(camParentTf.eulerAngles.x, minMaxAngle.x, minMaxAngle.y),
                                                              camParentTf.eulerAngles.y,
                                                              camParentTf.eulerAngles.z);
            time = 0.0f;
        }
        else
        {
            if (time > waitTime)
            {
                camParentTf.eulerAngles += new Vector3(0.0f, 0.04f, 0.0f);
            }
            time += Time.deltaTime;
        }

        this.transform.localPosition += new Vector3(0.0f, 0.0f, Input.mouseScrollDelta.y * scrollSpeed);
        this.transform.localPosition = new Vector3(0.0f,
                                                   0.0f,
                                                   Mathf.Clamp(this.transform.localPosition.z, minMaxDistance.y * -1.0f, minMaxDistance.x * -1.0f));
    }
}
