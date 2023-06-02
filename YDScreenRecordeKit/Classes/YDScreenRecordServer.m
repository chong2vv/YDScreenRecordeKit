//
//  YDScreenRecordServer.m
//  YDScreenRecordeKit
//
//  Created by wangyuandong on 2020/7/14.
//  Copyright © 2020 chong2vv. All rights reserved.
//

#import "YDScreenRecordServer.h"
#import <ReplayKit/ReplayKit.h>
#import "YDVideoWriteServer.h"

@interface YDScreenRecordServer ()

@property (nonatomic, assign) BOOL                             isRecording;
@property (nonatomic, assign) BOOL                             needContinue;
@property (nonatomic, assign) BOOL                             inBack;
@property (nonatomic, assign) NSInteger                        startTime;
@property (nonatomic, copy)void (^complate)(BOOL, NSString * _Nonnull path);

@property (nonatomic, strong) YDVideoWriteServer              *writeServer;

@end

@implementation YDScreenRecordServer

- (void)startScreenRecord {
    if (@available(iOS 11.0, *)) {
        self.complate = nil;
        [self startRecord];
        [self addNotification];
    }
    else
    {
//        ArtLogInfo(@"视频录制～～～～～失败系统版本低");
    }
}

- (void)startRecord {
    if (@available(iOS 11.0, *)) {
//        ArtLogInfo(@"视频录制～～～～开始启动");
        self.isRecording = YES;
        self.needContinue = YES;
        self.startTime = [[NSDate date] timeIntervalSince1970];
        [RPScreenRecorder sharedRecorder].microphoneEnabled = NO;
        [self.writeServer resetAndConstructWrite];
        [[RPScreenRecorder sharedRecorder] startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
            if (error) {
//                ArtLogInfo(@"视频录制～～～～错误:%@",error);
                return;
            }
            if (!self.isRecording) return;
            switch (bufferType) {
                case RPSampleBufferTypeVideo:
                {
                    [self.writeServer appendVSampleBuffer:sampleBuffer];
                }
                    break;
                case RPSampleBufferTypeAudioApp:
                {
                    [self.writeServer appendAudioSampleBuffer:sampleBuffer];
                }
                    break;
                case RPSampleBufferTypeAudioMic:
                {
                    [self.writeServer appendMicSampleBuffer:sampleBuffer];
                }
                    break;
                default:
                    break;
            }
        } completionHandler:^(NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
//                    ArtLogInfo(@"视频录制～～～～开始启动失败:%@",error);
                }
                else {
//                    ArtLogInfo(@"视频录制～～～～开始启动成功");
//                    [self performSelector:@selector(stopRPScreen) withObject:nil afterDelay:10*60];
                    if (self.starSuc) {
                        self.starSuc();
                    }
                }
            });
        }];
    } else {
//        ArtLogInfo(@"视频录制～～～～～失败系统版本低");
        // Fallback on earlier versions
    }
}

- (void)addNotification {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(willEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(willEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)willEnterBackground {
    if (self.isRecording && self.writeServer.isWrite) {
//        ArtLogInfo(@"视频录制～～～～进入后台");
        self.needContinue = NO;
        self.isRecording = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopRPScreen) object:nil];
        self.inBack = YES;
        [self stopRPScreen];
//        [[ArtRecordManger manager] beginBackgroundTask];
    }
}

- (void)willEnterForeground {
    if (self.inBack) {
//        ArtLogInfo(@"视频录制～～～～进入前台");
        self.needContinue = YES;
        self.inBack = NO;
        [self startRecord];
    }
}

- (void)stopRecordComplete:(void (^)(BOOL, NSString * _Nonnull))complete {
//    ArtLogInfo(@"视频录制～～～～～结束开始");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopRPScreen) object:nil];
    self.isRecording = NO;
    self.needContinue = NO;
    [self stopRPScreen];
}

- (void)stopRPScreen {
    if (@available(iOS 11.0, *)) {
//        ArtLogInfo(@"视频录制～～～～～stopCapture1");
        self.isRecording = NO;
        if ([RPScreenRecorder sharedRecorder].recording) {
//            ArtLogInfo(@"视频录制～～～～～stopCapture-YES");
            [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
              
            }];
        }
        [self.writeServer stopWrite];
    } else {
//        ArtLogInfo(@"视频录制～～～～～失败系统版本低");
    }
}

- (YDVideoWriteServer *)writeServer {
    if (!_writeServer) {
        __weak typeof(self) weakSelf = self;
        _writeServer = [[YDVideoWriteServer alloc] initWithFinishCompletion:^(NSString * _Nonnull path) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.needContinue) {
                [strongSelf startRecord];
            }
            if (strongSelf.VideoSction) {
                AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
                if (asset && asset.duration.value>0) {
                    strongSelf.VideoSction([path componentsSeparatedByString:@"/"].lastObject, asset.duration.value/asset.duration.timescale, strongSelf.startTime, path);

                }
            }
        }];
    }
    return _writeServer;
}

@end
