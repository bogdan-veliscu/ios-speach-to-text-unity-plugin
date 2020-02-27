//
//  SpeechNativePlugin.m
//  SpeechNativePlugin
//
//  Created by Bogdan on 2/27/20.
//  Copyright © 2020 Codeswiftr. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <Speech/Speech.h>
#import "SpeechNativePlugin.h"
@implementation SpeechNativePlugin
//@synthesize lastRecognizedText;
static callbackFunc recognitionCallback;

float *const *sampleData;
int channelCount = 1;
- (id)init
{
    self = [super init];
    
    // Initialize the Speech Recognizer with the locale
    speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    
    // Set speech recognizer delegate
    speechRecognizer.delegate = self;
    
    // Request the authorization to make sure the user is asked for permission so you can
    // get an authorized response, also remember to change the .plist file, check the repo's
    // readme file or this projects info.plist
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        switch (status) {
            case SFSpeechRecognizerAuthorizationStatusAuthorized:
                NSLog(@"#SpechRecognition: Authorized :SFSpeechRecognizerAuthorizationStatusAuthorized");
                break;
            case SFSpeechRecognizerAuthorizationStatusDenied:
                NSLog(@"#SpechRecognition: Denied");
                break;
            case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                NSLog(@"#SpechRecognition: Not Determined");
                break;
            case SFSpeechRecognizerAuthorizationStatusRestricted:
                NSLog(@"#SpechRecognition: Restricted");
                break;
            default:
                break;
        }
    }];
    
    return self;
}

- (void)startListening {
    
    NSLog(@"# startListening");
    // Initialize the AVAudioEngine
    audioEngine = [[AVAudioEngine alloc] init];
    
    // Starts an AVAudio Session
    NSError *error;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    
    // Starts a recognition process, in the block it logs the input or stops the audio
    // process if there's an error.
    recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = audioEngine.inputNode;
    recognitionRequest.shouldReportPartialResults = YES;
    recognitionTask = [speechRecognizer recognitionTaskWithRequest:recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        BOOL isFinal = NO;
        if (result) {
            
            for (SFTranscription *transcription in result.transcriptions) {
                
                NSLog(@"# SpechRecognition: Recognized CODE: %@", transcription);
                if (recognitionCallback != NULL){
                    recognitionCallback([transcription.formattedString UTF8String]);
                }
            }
            
            isFinal = !result.isFinal;
        }
        if (error && !self->recognitionTask.isCancelled) {
            NSLog(@"# SpechRecognition: Error: %@ %@", error, [error userInfo]);
            [self->audioEngine stop];
            [inputNode removeTapOnBus:0];
            self->recognitionRequest = nil;
            self->recognitionTask = nil;
        }
    }];
    
    // Sets the recording format
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    channelCount = [recordingFormat channelCount];
    
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [self->recognitionRequest appendAudioPCMBuffer:buffer];
        sampleData = buffer.floatChannelData;
    }];
    
    // Starts the audio engine, i.e. it starts listening.
    [audioEngine prepare];
    [audioEngine startAndReturnError:&error];
    NSLog(@"# SpechRecognition: listening on chanel:%d", [recordingFormat channelCount]);
    
}

- (void)restartRecognition {
    sampleData = nil;
    NSLog(@"## restartRecognition");
    if (audioEngine.isRunning) {
        [self stopListening];
    }
    [self performSelector:@selector(startListening) withObject:nil afterDelay:1];
}

- (void) stopListening{
    NSLog(@"StopListening");

    // Make sure there's not a recognition task already running
    if (recognitionTask) {
        
        NSLog(@"# SpechRecognition: an older recognitionTask isRunning");
        [recognitionTask cancel];
        recognitionTask = nil;
    }
    if (audioEngine.isRunning) {
        [audioEngine stop];
        [recognitionRequest endAudio];
    }
}

#pragma mark - SFSpeechRecognizerDelegate Delegate Methods

- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    NSLog(@"# SpechRecognition: Availability: %d",available);
}

@end

static SpeechNativePlugin* delegateObject = nil;

// Helper method to create C string copy
char* MakeStringCopy (const char* string)
{
    if (string == NULL)
        return NULL;
    
    char* res = (char*)malloc(strlen(string) + 1);
    strcpy(res, string);
    return res;
}

extern "C" {
    
    void _init(){
        if (delegateObject == nil){
            delegateObject = [[SpeechNativePlugin alloc] init];
        }
    }
    
    void _listen(callbackFunc callback){
        recognitionCallback = callback;
        NSLog(@"# SpechRecognition: restartRecognition _lisen");
        [delegateObject restartRecognition];
    }
    
    void _getAudioSamples (float *samples, float *size){
        //NSLog(@"#SpechRecognition restartRecognition: %d",  channelCount);
        *size = 1024;
        if (sampleData != nil){
            for (int i = 0; i < 1024 ; i ++) {
                samples[i] = sampleData[0][i];
            }
        }
    }
    
    void _release(){
        
        NSLog(@"# SpechRecognition: _release");
        sampleData = nil;
        [delegateObject stopListening];
    }
}
