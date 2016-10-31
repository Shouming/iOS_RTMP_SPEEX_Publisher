//
//  ViewController.m
//  SpeexTest
//
//  Created by ShouMingChen on 2016/10/15.
//  Copyright © 2016年 ShouMingChen. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize audioDataStreamPipe;
@synthesize audioDataStreamPipeReader;
@synthesize audioDataStreamPipeWriter;
@synthesize rtmpPublisher;

- (void)viewDidLoad {
    [super viewDidLoad];
    // init data pipe
    [self initDataStreamPipe];
    
    // rtmp server
    NSString *path = [NSString stringWithFormat:@"rtmp://192.168.43.216/oflaDemo/5588"];
    rtmpPublisher = [[RTMPPublisher alloc] initRTMPPublisher:path];
    
    // init speex encoder
    [[SpeexEncoder sharedEncoder] setPublisher:rtmpPublisher];
    [[SpeexEncoder sharedEncoder] setDataPipeReader:audioDataStreamPipeReader];
    
    // init audio recorder & start recording
    recoder = [[AQRecoder alloc] initWithPipeWriter:audioDataStreamPipeWriter];
    [recoder startRecording];
    
    // Skip the implementation of UI control
    //[recoder stopRecording];
    //[rtmpPublisher releaseRTMPPublisher];
    //[self closeDataStreamPipe];
    
}

- (void) initDataStreamPipe {
    self.audioDataStreamPipe = [[NSPipe alloc] init];
    self.audioDataStreamPipeReader = [self.audioDataStreamPipe fileHandleForReading];
    self.audioDataStreamPipeWriter = [self.audioDataStreamPipe fileHandleForWriting];
}

- (void) closeDataStreamPipe {
    [self.audioDataStreamPipeWriter closeFile];
    [self.audioDataStreamPipeReader closeFile];
    self.audioDataStreamPipe = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
