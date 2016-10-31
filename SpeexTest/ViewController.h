//
//  ViewController.h
//  SpeexTest
//
//  Created by ShouMingChen on 2016/10/15.
//  Copyright © 2016年 ShouMingChen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SpeexEncoder.h"
#import "AQRecoder.h"
#import "RTMPPublisher.h"

@interface ViewController : UIViewController {
    SpeexEncoder *speexEncoder;
    AQRecoder *recoder;
    RTMPPublisher *rtmpPublisher;
}

@property (nonatomic, strong) NSPipe *audioDataStreamPipe;
@property (nonatomic, strong) NSFileHandle *audioDataStreamPipeReader;
@property (nonatomic, strong) NSFileHandle *audioDataStreamPipeWriter;
@property (nonatomic, retain) RTMPPublisher *rtmpPublisher;

@end

