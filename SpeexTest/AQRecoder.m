//
//  AQRecoder.m
//  SpeexTest
//
//  Created by ShouMingChen on 2016/10/16.
//  Copyright © 2016年 ShouMingChen. All rights reserved.
//

#import "AQRecoder.h"

static NSFileHandle *audioDataWriter;

@implementation AQRecoder

- (id) initWithPipeWriter:(NSFileHandle*) dataWriter {
    if (self = [super init]) {
        audioDataWriter = dataWriter;
    }
    return self;
}

- (Boolean) startRecording {

    NSLog(@"[AQRecorder]      startRecording");
    // setup format
    aqData.mDataFormat.mFormatID         = kAudioFormatLinearPCM;
    aqData.mDataFormat.mSampleRate       = 16000.0;
    aqData.mDataFormat.mChannelsPerFrame = 1;
    aqData.mDataFormat.mBitsPerChannel   = 16;
    aqData.mDataFormat.mBytesPerPacket   =
    aqData.mDataFormat.mBytesPerFrame =
    aqData.mDataFormat.mChannelsPerFrame * sizeof (SInt16);
    aqData.mDataFormat.mFramesPerPacket  = 1;
    
    AudioFileTypeID fileType             = kAudioFileAIFFType;
    // for publish to RTMP Server
    aqData.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsSignedInteger;
    // for record into file
    //aqData.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    
    // create the queue
    errorStatus = AudioQueueNewInput (
                                      &aqData.mDataFormat,                          // 2
                                      HandleInputBuffer,                            // 3
                                      &aqData,                                      // 4
                                      NULL,                                         // 5
                                      kCFRunLoopCommonModes,                        // 6
                                      0,                                            // 7
                                      &aqData.mQueue                                // 8
                                      );
    
    if (errorStatus) {
        NSLog(@"[AQRecorder]      startRecording error: %d when AudioQueueNewInput ", (int)errorStatus);
        return false;
    }
    
    UInt32 dataFormatSize = sizeof (aqData.mDataFormat);
    errorStatus = AudioQueueGetProperty(
                                        aqData.mQueue,
                                        kAudioQueueProperty_StreamDescription,
                                        &aqData.mDataFormat,
                                        &dataFormatSize
                                        );
    if (errorStatus) {
        NSLog(@"[AQRecorder]      startRecording error:%d when AudioQueueGetProperty StreamDescription", (int)errorStatus);
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"test"];

    CFURLRef audioFileURL =
    CFURLCreateFromFileSystemRepresentation (
                                             NULL,
                                             (char*)path.cString,
                                             path.length,
                                             false                                            
                                             );
    
    AudioFileCreateWithURL (                                 // 6
                            audioFileURL,                                        // 7
                            fileType,                                            // 8
                            &aqData.mDataFormat,                                 // 9
                            kAudioFileFlags_EraseFile,                           // 10
                            &aqData.mAudioFile                                   // 11
                            );

    DeriveBufferSize (
                      aqData.mQueue,                               // 2
                      aqData.mDataFormat,                          // 3
                      0.5,                                         // 4
                      &aqData.bufferByteSize                       // 5
                      );
    
    // allocate and enqueue buffers
    for (int i = 0; i < kNumberBuffers; ++i) {
        errorStatus = AudioQueueAllocateBuffer (
                                                aqData.mQueue,
                                                aqData.bufferByteSize,
                                                &aqData.mBuffers[i]
                                                );
        
        if (errorStatus) {
            NSLog(@"[AQRecorder]      startRecording error:%d alloc buffer", (int)errorStatus);
            NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                                 code:errorStatus
                                             userInfo:nil];
            NSLog(@"[AQRecorder]      Error: %@", [error description]);
        }

        
        errorStatus = AudioQueueEnqueueBuffer (
                                               aqData.mQueue,
                                               aqData.mBuffers[i],
                                               0,
                                               NULL
                                               );
        if (errorStatus) {
            NSLog(@"[AQRecorder]      startRecording error:%d enqueue buffer", (int)errorStatus);
        }
    }

    // start the queue
    aqData.mCurrentPacket = 0;
    aqData.mIsRunning = true;
    errorStatus = AudioQueueStart(aqData.mQueue, NULL);
    if (errorStatus) {
        NSLog(@"[AQRecorder]      startRecording error:%d", (int)errorStatus);
        return false;
    }
    return true;
}

- (void) stopRecording {
    
    AudioQueueStop(aqData.mQueue, true);
}

// A Full Recording Audio Queue Callback
static void HandleInputBuffer (
                               void                                 *aqData,
                               AudioQueueRef                        inAQ,
                               AudioQueueBufferRef                  inBuffer,
                               const AudioTimeStamp                 *inStartTime,
                               UInt32                               inNumPackets,
                               const AudioStreamPacketDescription   *inPacketDesc
                               ) {

    NSLog(@"[AQRecorder]      HandleInputBuffer #packages=%lu, #bytes:%d", inNumPackets, (int)inBuffer->mAudioDataByteSize);
    struct AQRecorderState *pAqData = (struct AQRecorderState *) aqData;
    
    if (inNumPackets == 0 && pAqData->mDataFormat.mBytesPerPacket != 0) {
        inNumPackets = inBuffer->mAudioDataByteSize / pAqData->mDataFormat.mBytesPerPacket;
    }
    
    // Encode with Speex lib
    [audioDataWriter writeData:[NSData dataWithBytes:inBuffer->mAudioData length:(int)inBuffer->mAudioDataByteSize]];
    
    // Store into file
    if (AudioFileWritePackets (
                               pAqData->mAudioFile,
                               false,
                               inBuffer->mAudioDataByteSize,
                               inPacketDesc,
                               pAqData->mCurrentPacket,
                               &inNumPackets,
                               inBuffer->mAudioData
                               ) == noErr) {
        pAqData->mCurrentPacket += inNumPackets;
    }
    if (pAqData->mIsRunning == 0)
        return;
    
    AudioQueueEnqueueBuffer (
                             pAqData->mQueue,
                             inBuffer,
                             0,
                             NULL
                             );
}

void DeriveBufferSize(AudioQueueRef audioQueue, AudioStreamBasicDescription ASBDescription, Float64 seconds, UInt32 *outBufferSize)
{
    static const int maxBufferSize = 0x50000;
    
    int maxPacketSize = ASBDescription.mBytesPerPacket;
    if (maxPacketSize == 0) {
        UInt32 maxVBRPacketSize = sizeof(maxPacketSize);
        AudioQueueGetProperty (
                               audioQueue,
                               kAudioQueueProperty_MaximumOutputPacketSize,
                               // in Mac OS X v10.5, instead use
                               //   kAudioConverterPropertyMaximumOutputPacketSize
                               &maxPacketSize,
                               &maxVBRPacketSize
                               );
    }
    
    Float64 numBytesForTime = ASBDescription.mSampleRate * maxPacketSize * seconds;
    UInt32 result = (numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize);
    *outBufferSize = result;
}

@end