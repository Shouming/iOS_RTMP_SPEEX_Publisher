//
//  AQRecoder.h
//  SpeexTest
//
//  Created by ShouMingChen on 2016/10/16.
//  Copyright © 2016年 ShouMingChen. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <AudioToolbox/AudioToolbox.h>

static const int kNumberBuffers = 3;

struct AQRecorderState {
    AudioStreamBasicDescription  mDataFormat;
    AudioQueueRef                mQueue;
    AudioQueueBufferRef          mBuffers[kNumberBuffers];
    AudioFileID                  mAudioFile;
    UInt32                       bufferByteSize;
    SInt64                       mCurrentPacket;
    bool                         mIsRunning;
};

@interface AQRecoder : NSObject {
    OSStatus errorStatus;
    struct AQRecorderState aqData;
}

- (id) initWithPipeWriter:(NSFileHandle*) audioDataWriter;
- (Boolean) startRecording;
- (void) stopRecording;

@end
