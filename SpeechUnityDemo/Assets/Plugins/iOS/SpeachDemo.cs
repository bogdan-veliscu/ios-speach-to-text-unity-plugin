using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SpeachDemo : MonoBehaviour
{
	public Text textField;

    // Start is called before the first frame update
    void Start()
    {
        #if UNITY_IPHONE
            SpeechNativePlugin._init();

            SpeechNativePlugin._listenWithCallback(OnTextRecognized);
		#endif
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    void OnDestroy()
    {
        Debug.Log("OnDestroy");

        #if UNITY_IPHONE
			SpeechNativePlugin._release();
		#endif
    }

    void OnTextRecognized(string message){
    	Debug.LogFormat("### OnTextRecognized: [{0}]  ");
    	textField.text = message;
    }
}
