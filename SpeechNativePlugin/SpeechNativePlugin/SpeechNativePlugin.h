//
//  SpeechNativePlugin.h
//  SpeechNativePlugin
//
//  Created by Bogdan on 2/27/20.
//  Copyright © 2020 Codeswiftr. All rights reserved.
//

#import <Foundation/Foundation.h>

#define EXPORT_API

@interface SpeechNativePlugin : NSObject<SFSpeechRecognizerDelegate> {
    SFSpeechRecognizer *speechRecognizer;
    SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
    SFSpeechRecognitionTask *recognitionTask;
    AVAudioEngine *audioEngine;
}
@end

extern "C" {

typedef void (*callbackFunc)(const char *);

EXPORT_API void _init();
EXPORT_API void _listen(callbackFunc scanCallback);
EXPORT_API void _release();
EXPORT_API void _getAudioSamples (float *samples, float *size);

}
