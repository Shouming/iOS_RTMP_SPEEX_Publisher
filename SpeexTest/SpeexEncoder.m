//
//  SpeexEncoder.m
//  SpeexTest
//
//  Created by ShouMingChen on 2016/10/15.
//  Copyright © 2016年 ShouMingChen. All rights reserved.
//

#import "SpeexEncoder.h"

@implementation SpeexEncoder

@synthesize audioDataReader;
@synthesize publish;

+ (id) sharedEncoder {
    static SpeexEncoder *sharedEncoder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedEncoder = [[self alloc] initSpeexEncoder];
    });
    return sharedEncoder;
}

- (id) initSpeexEncoder
{
    NSLog(@"[SpeexEncoder]    initSpeexEncoder");
    if (self = [super init]) {
        int quality = 10;
        speex_bits_init(&bits);
        enc_state = speex_encoder_init(&speex_wb_mode);
        if(speex_encoder_ctl(enc_state, SPEEX_GET_FRAME_SIZE, &frame_size)!=0)
            NSLog(@"[SpeexEncoder]    Error in speex_encoder_ctl(SPEEX_GET_FRAME_SIZE)");
        else
            NSLog(@"[SpeexEncoder]    Get Frame Size: %d (#samples)", (int)frame_size);
        
        if(speex_encoder_ctl(enc_state, SPEEX_SET_QUALITY, &quality)!=0)
            NSLog(@"[SpeexEncoder]    Error in speex_encoder_ctl(SPEEX_SET_QUALITY)");
        
        /* de-noise */
        preprocess_state = speex_preprocess_state_init((int)frame_size, 16000);
        
        int on = 1;
        int state = 0;
        speex_preprocess_ctl(preprocess_state, SPEEX_PREPROCESS_SET_DENOISE, &on);
        speex_preprocess_ctl(preprocess_state, SPEEX_PREPROCESS_GET_DENOISE, &state);
        NSLog(@"[SpeexEncoder]    DENOISE : %d", state);
    }
    return self;
}

- (void) releaseSpeexEncoder
{
    NSLog(@"[SpeexEncoder]    releaseAVspeexEncoder");
    
    speex_bits_destroy(&bits);
    speex_encoder_destroy(enc_state);
    speex_preprocess_state_destroy(preprocess_state);
}

- (void) setPublisher:(RTMPPublisher*)publisher
{
    self.publish = publisher;
}

- (void) setDataPipeReader:(NSFileHandle*) dataReader
{
    self.audioDataReader = dataReader;
    
    __weak SpeexEncoder *weakSelf = self;
    self.audioDataReader.readabilityHandler = ^( NSFileHandle *pipehandler1 ) {
        [weakSelf encode_audio];
    };
}

- (void) encode_audio
{
    int inputLength = (int)frame_size * sizeof(short);
    NSData *inBuffer = [self.audioDataReader readDataOfLength:inputLength];
    
    char* encoded = (char*) malloc(MAX_ENCODED_SIZE);
    int lenOfSample = [inBuffer length];
    spx_int16_t *resampled = (spx_int16_t*) malloc(lenOfSample);
    memcpy(resampled, [inBuffer bytes], lenOfSample);
    
    // de-noise
    spx_int16_t *denoised = (spx_int16_t*) malloc(lenOfSample);
    memcpy(denoised, resampled, lenOfSample);
    speex_preprocess_run(preprocess_state, denoised);
    
    // encode speex
    speex_bits_reset(&bits);
    speex_encode_int(enc_state, denoised, &bits);
    int bytes = speex_bits_nbytes(&bits);
    int numOfBytes = speex_bits_write(&bits, encoded, MAX_ENCODED_SIZE);
    NSLog(@"[SpeexEncoder]    Encoded #bytes: %d", numOfBytes);

    // Send
    [self.publish sendRTMPAudioData:encoded lenOfBuf:numOfBytes timeStamp:pubTs += 20];
    
    free(encoded);
    free(denoised);
    free(resampled);
}

@end
