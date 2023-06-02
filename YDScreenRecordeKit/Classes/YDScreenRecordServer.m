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

@property (nonatomic, copy)YDRecordStartSuccess startBlock;
@property (nonatomic, copy)YDRecordStopSuccess stopBlock;
@property (nonatomic, copy)YDRecordFailure startFailure;
@property (nonatomic, copy)YDRecordFailure stopFailure;

@property (nonatomic, strong) YDVideoWriteServer              *writeServer;

@end

#define kWeakSelf(type)  __weak typeof(type) weak##type = type;
#define kStrongSelf(type) __strong typeof(type) strong##type = weak##type;

@implementation YDScreenRecordServer

- (void)startScreenRecord:(YDRecordStartSuccess)onSuccess failure:(YDRecordFailure)failure {
    self.startBlock = onSuccess;
    self.startFailure = failure;
    self.complate = nil;
    [self _startRecording];
    [self addNotification];
}

- (void)stopRecordComplete:(YDRecordStopSuccess) onSuccess failure:(YDRecordFailure) failure {
    self.stopBlock = onSuccess;
    self.stopFailure = failure;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_stopRecording) object:nil];
    self.isRecording = NO;
    self.needContinue = NO;
    [self _stopRecording];
}

- (void)_startRecording {
    if (@available(iOS 11.0, *)) {
        self.isRecording = YES;
        self.needContinue = YES;
        self.startTime = [[NSDate date] timeIntervalSince1970];
        [RPScreenRecorder sharedRecorder].microphoneEnabled = NO;
        [self.writeServer resetAndConstructWrite];
        kWeakSelf(self)
        [[RPScreenRecorder sharedRecorder] startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
            kStrongSelf(self)
            if (error) {
                YDSRErrorHandle *err = [[YDSRErrorHandle alloc] initWithError:error];
                if (strongself.startFailure) {
                    strongself.startFailure(err);
                }
                return;
            }
            if (!strongself.isRecording) return;
            switch (bufferType) {
                case RPSampleBufferTypeVideo:
                {
                    [strongself.writeServer appendVSampleBuffer:sampleBuffer];
                }
                    break;
                case RPSampleBufferTypeAudioApp:
                {
                    [strongself.writeServer appendAudioSampleBuffer:sampleBuffer];
                }
                    break;
                case RPSampleBufferTypeAudioMic:
                {
                    [strongself.writeServer appendMicSampleBuffer:sampleBuffer];
                }
                    break;
                default:
                    break;
            }
        } completionHandler:^(NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                kStrongSelf(self)
                if (error) {
                    YDSRErrorHandle *err = [[YDSRErrorHandle alloc] initWithError:error];
                    if (strongself.startFailure) {
                        strongself.startFailure(err);
                    }
                }
                else {
                    if (strongself.startBlock) {
                        strongself.startBlock();
                    }
                }
            });
        }];
    } else {
        YDSRErrorHandle *err = [[YDSRErrorHandle alloc] init];
        err.isError = YES;
        err.msg = @"需要iOS11以上系统";
        err.code = 10001;
        if (self.startFailure) {
            self.startFailure(err);
        }
    }
}

- (void)_stopRecording {
    if (@available(iOS 11.0, *)) {
        self.isRecording = NO;
        if ([RPScreenRecorder sharedRecorder].recording) {
            [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
              
            }];
        }
        [self.writeServer stopWrite];
    } else {
        YDSRErrorHandle *err = [[YDSRErrorHandle alloc] init];
        err.isError = YES;
        err.msg = @"需要iOS11以上系统";
        err.code = 10001;
        if (self.stopFailure) {
            self.stopFailure(err);
        }
    }
}

- (void)addNotification {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(willEnterForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(willEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)willEnterBackground {
    if (self.isRecording && self.writeServer.isWrite) {
        self.needContinue = NO;
        self.isRecording = NO;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_stopRecording) object:nil];
        self.inBack = YES;
        [self _stopRecording];
    }
}

- (void)willEnterForeground {
    if (self.inBack) {
        self.needContinue = YES;
        self.inBack = NO;
        [self _startRecording];
    }
}

- (YDVideoWriteServer *)writeServer {
    if (!_writeServer) {
        kWeakSelf(self)
        _writeServer = [[YDVideoWriteServer alloc] initWithFinishCompletion:^(NSString * _Nonnull path) {
            kStrongSelf(self)
            if (strongself.needContinue) {
                [strongself _startRecording];
            }
            if (strongself.VideoSction) {
                AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
                if (asset && asset.duration.value>0) {
                    strongself.VideoSction([path componentsSeparatedByString:@"/"].lastObject, asset.duration.value/asset.duration.timescale, strongself.startTime, path);

                }
            }
        }];
    }
    return _writeServer;
}


@end
