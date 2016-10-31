//
//  SpeexEncoder.h
//  SpeexTest
//
//  Created by ShouMingChen on 2016/10/15.
//  Copyright © 2016年 ShouMingChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMSampleBuffer.h>

#include "speex.h"
#include "speex_preprocess.h"
#include "speex_resampler.h"

#import "RTMPPublisher.h"

#define MAX_ENCODED_SIZE 200

@interface SpeexEncoder : NSObject {
    SpeexBits bits;
    void *frame_size;
    void *enc_state;
    SpeexPreprocessState    *preprocess_state;
    
    SpeexBits bits2;
    void *frame_size2;
    void *dec_state;
    
    RTMPPublisher *publish;
    UInt32 pubTs;
}

@property (nonatomic, retain) RTMPPublisher *publish;
@property (nonatomic, retain) NSFileHandle *audioDataReader;

+ (id)   sharedEncoder;
- (void) releaseSpeexEncoder;

- (void) setPublisher:(RTMPPublisher*)publisher;
- (void) setDataPipeReader:(NSFileHandle*)dataReader;
- (void) encode_audio;
@end
