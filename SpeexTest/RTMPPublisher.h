//
//  SpeexEncoder.m
//  SpeexTest
//
//  Created by ShouMingChen on 2016/10/15.
//  Copyright © 2016年 ShouMingChen. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "rtmp.h"

@interface RTMPPublisher : NSObject{
    RTMP                *rtmp_publish;
}

- (id)   initRTMPPublisher:(NSString*) publishURL;
- (void) sendRTMPAudioData:(char*) buf lenOfBuf:(int) len timeStamp:(unsigned int) timestamp;
- (void) releaseRTMPPublisher;

@end
