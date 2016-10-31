//
//  SpeexEncoder.m
//  SpeexTest
//
//  Created by ShouMingChen on 2016/10/15.
//  Copyright © 2016年 ShouMingChen. All rights reserved.
//

#import "RTMPPublisher.h"
#import "rtmp.h"

#include "log.h"

@implementation RTMPPublisher

- (id) initRTMPPublisher:(NSString*) publishURL
{
    NSLog(@"[RTMPPublisher]   InitPublisher");
    if (self = [super init]) {
        [self setUpRTMPConnection:publishURL];
    }
    return self;
}

- (void) releaseRTMPPublisher
{
    NSLog(@"[RTMPPublisher]   releaseRTMPPublisher");
    [self closeRTMPConnection];
}

- (void) setUpRTMPConnection:(NSString*) publishURL
{
    RTMP_LogSetLevel(RTMP_LOGDEBUG);

    rtmp_publish= RTMP_Alloc();
    RTMP_Init(rtmp_publish);
    if(!RTMP_SetupURL(rtmp_publish, (char*)[publishURL cStringUsingEncoding:NSUTF8StringEncoding])) {
        NSLog(@"[RTMPPublisher]   RTMP_SetupURL error");
    }
    
    RTMP_EnableWrite(rtmp_publish);
    
    NSLog(@"[RTMPPublish]   Start RTMP_Connect to %@", publishURL);
    if(!RTMP_Connect(rtmp_publish, NULL)) {
        NSLog(@"[RTMPPublisher]   RTMP_Connect error");
    }
    
    NSLog(@"[RTMPPublish]   Start RTMP_ConnectStream");
    if(!RTMP_ConnectStream(rtmp_publish,0)) {
        NSLog(@"[RTMPPublisher]   RTMP_ConnectStream error");
    }
    
    NSLog(@"[RTMPPublisher]   Media Channel : %d, stream id : %d", rtmp_publish->m_mediaChannel, rtmp_publish->m_stream_id);
}

- (void) sendRTMPAudioData:(char*) buf lenOfBuf:(int) len timeStamp:(unsigned int) timestamp
{
    int ret;
    RTMPPacket rtmp_pakt;
    RTMPPacket_Reset(&rtmp_pakt);
    RTMPPacket_Alloc(&rtmp_pakt, len);
    rtmp_pakt.m_packetType = RTMP_PACKET_TYPE_AUDIO;
    rtmp_pakt.m_nBodySize = len+1;
    rtmp_pakt.m_nTimeStamp = timestamp;
    rtmp_pakt.m_nChannel = 0x04;
    rtmp_pakt.m_headerType = RTMP_PACKET_SIZE_MEDIUM;
    rtmp_pakt.m_nInfoField2 = rtmp_publish->m_stream_id;
    
    rtmp_pakt.m_body[0] = 0xB2;
    memcpy(rtmp_pakt.m_body+1, buf, len);
    ret = RTMP_SendPacket(rtmp_publish, &rtmp_pakt, 0);
    RTMPPacket_Free(&rtmp_pakt);
    
    NSLog(@"[RTMPPublisher]   sendRTMPAudioData size=%d, time_stamp=%d", len, timestamp);
}

- (void) closeRTMPConnection
{
    RTMP_Close(rtmp_publish);
}

@end
