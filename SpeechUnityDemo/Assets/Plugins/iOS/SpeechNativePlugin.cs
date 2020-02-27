using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using AOT;
using UnityEngine;

public static partial class SpeechNativePlugin{

	#if UNITY_IPHONE
    [DllImport("__Internal")]
    public static extern void _init();

    [DllImport("__Internal")]
    private static extern void _listen(OnRecognized callback);

    [DllImport("__Internal")]
    public static extern void _release();

    [DllImport("__Internal")]
    public static extern void _getAudioSamples(float[] samples, out int size);


    public delegate void OnRecognized(string mesage);

    [MonoPInvokeCallback(typeof(OnRecognized))]
    public static void OnSpeachRecognized(string message){
        Debug.Log("# SpeachRecognitionNative : " + message);

        if(OnSpeachRecognizeCompleted != null){
            OnSpeachRecognizeCompleted(message);
        }
    }

    public static Action<string> OnSpeachRecognizeCompleted;

    public static void _listenWithCallback(Action<string> onRecognized){
        OnSpeachRecognizeCompleted = onRecognized;

        _listen(OnSpeachRecognized);
    }

#endif

}