//
//  YDVideoWriteServer.m
//  YDScreenRecordeKit
//
//  Created by wangyuandong on 2020/7/14.
//  Copyright © 2020 chong2vv. All rights reserved.
//


#import "YDVideoWriteServer.h"
#import <AVFoundation/AVAssetWriter.h>
#import <AVFoundation/AVAssetWriterInput.h>

typedef enum : NSUInteger {
    SampleBufferTypeAudioApp,
    SampleBufferTypeAudioMic,
} SampleBufferType;

@interface YDVideoWriteServer ()
{
    AVAssetWriter *_videoWriter;
    AVAssetWriterInput *_videoWriterInput;
    AVAssetWriterInput *_audioWriterInput;
    AVAssetWriterInput *_audioMicWriterInput;
    AVAssetWriterInputPixelBufferAdaptor *_avAdaptor;
    NSDate *_startDate;
    BOOL _haveVideo;
    float _lastElapsed;
    NSString *_filePath;
}

@property (nonatomic, strong) void (^FinishCompletion)(NSString * path);

@end


@implementation YDVideoWriteServer

- (instancetype)initWithFinishCompletion:(void (^)(NSString * _Nonnull))complete {
    self = [super init];
    if (self) {
        self.FinishCompletion = complete;
    }
    return self;
}

/// 拼接视频帧
/// @param sampleBuffer 视频帧
- (void)appendVSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [self startWriteSessionAtSourceTime];
    float millisElapsed = [[NSDate date] timeIntervalSinceDate:_startDate] * 1000.0;
    if (millisElapsed-_lastElapsed<100 && millisElapsed!=0) {
        return;
    }
    _haveVideo = YES;
    CMTime time = millisElapsed==0?kCMTimeZero:CMTimeMake(millisElapsed, 1000);
    CVPixelBufferRef pixelbuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (_avAdaptor.assetWriterInput.readyForMoreMediaData) {
        _lastElapsed = millisElapsed;
        [_avAdaptor appendPixelBuffer:pixelbuffer withPresentationTime:time];
    }
}

/// 拼接应用内音频帧
/// @param sampleBuffer audiodata
- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!_haveVideo)return;
    if (_audioWriterInput.readyForMoreMediaData) {
        [self appendAudioSampleBuffer:sampleBuffer WithType:SampleBufferTypeAudioApp];
    }
}

/// 拼接麦克风声音
/// @param sampleBuffer audiodata
- (void)appendMicSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!_haveVideo)return;
    if (_audioMicWriterInput.readyForMoreMediaData) {
        [self appendAudioSampleBuffer:sampleBuffer WithType:SampleBufferTypeAudioMic];
    }
}

- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer WithType:(SampleBufferType)type {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, count, pInfo, &count);
    
    float millisElapsed = [[NSDate date] timeIntervalSinceDate:_startDate] * 1000.0;
    CMTime time = CMTimeMake(millisElapsed, 1000);
    for (CMItemCount i = 0; i < count; i++){
        pInfo[i].presentationTimeStamp =time;
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sampleBuffer, count, pInfo, &sout);
    free(pInfo);
    switch (type) {
        case SampleBufferTypeAudioApp:
            [_audioWriterInput appendSampleBuffer:sout];
            break;
        case SampleBufferTypeAudioMic:
            [_audioMicWriterInput appendSampleBuffer:sout];
            break;
        default:
            break;
    }
    
    CFRelease(sout);
}

/// 设置源开始时间
- (void)startWriteSessionAtSourceTime {
    if (!_startDate) {
        [_videoWriter startSessionAtSourceTime:kCMTimeZero];
        _startDate = [NSDate date];
        _isWrite = YES;
    }
}

/// 结束视频写入生成视频
- (void)stopWrite {
    @try {
        _haveVideo = NO;
        [_videoWriterInput markAsFinished];
        [_audioWriterInput markAsFinished];
        [_audioMicWriterInput markAsFinished];
        AVAssetWriterStatus status = _videoWriter.status;
        while (status == AVAssetWriterStatusUnknown)
        {
            [NSThread sleepForTimeInterval:0.5f];
            status = _videoWriter.status;
        }
        __weak typeof(self) weakSelf = self;
        [_videoWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
//                ArtLogInfo(@"视频录制～～～～～结束");
                __strong typeof(weakSelf) strongSelf = weakSelf;
                _videoWriter = nil;
                _videoWriterInput = nil;
                _avAdaptor = nil;
                _audioWriterInput = nil;
                _audioMicWriterInput = nil;
                _startDate = nil;
                _lastElapsed = 0;
                _isWrite = NO;
                if (strongSelf.FinishCompletion && !_videoWriter.error) {
                    strongSelf.FinishCompletion(_filePath);
                }
            });
        }];
    } @catch (NSException *exception) {
//        ArtLogInfo(@"视频录制～～～～合成异常:%@",exception);
    } @finally {
        
    }
}

/// 构建视频存储器
- (void)resetAndConstructWrite {
    CGSize size = [UIScreen mainScreen].bounds.size;
    NSString *filePath=[self fetchFilePath];
    _filePath = filePath;
    NSURL   *fileUrl=[NSURL fileURLWithPath:filePath];
    _videoWriter = [[AVAssetWriter alloc] initWithURL:fileUrl fileType:AVFileTypeMPEG4 error:nil];
    NSParameterAssert(_videoWriter);
    
    NSDictionary* videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithDouble:512*1000], AVVideoAverageBitRateKey,
                                           [NSNumber numberWithInt:10],AVVideoExpectedSourceFrameRateKey,
                                           [NSNumber numberWithInt:15],AVVideoMaxKeyFrameIntervalKey,
                                           nil ];
    
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   videoCompressionProps, AVVideoCompressionPropertiesKey,
                                   nil];
    
    _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSParameterAssert(_videoWriterInput);
    _videoWriterInput.expectsMediaDataInRealTime = YES;
    NSDictionary* bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8Planar], kCVPixelBufferPixelFormatTypeKey, nil];
    
    _avAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoWriterInput sourcePixelBufferAttributes:bufferAttributes];
    [_videoWriter addInput:_videoWriterInput];
    

    AudioChannelLayout acl;
    bzero( &acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    NSDictionary* audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                                         [ NSNumber numberWithInt: 2 ], AVNumberOfChannelsKey,
                                         [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                                         [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
                                         [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                                         nil];
    _audioWriterInput = [AVAssetWriterInput
                        assetWriterInputWithMediaType: AVMediaTypeAudio
                        outputSettings: audioOutputSettings];
    _audioWriterInput.expectsMediaDataInRealTime = NO;
    [_videoWriter addInput:_audioWriterInput];
    
    
    _audioMicWriterInput = [AVAssetWriterInput
                           assetWriterInputWithMediaType: AVMediaTypeAudio
                           outputSettings: [audioOutputSettings copy]];
    _audioMicWriterInput.expectsMediaDataInRealTime = NO;
    [_videoWriter addInput:_audioMicWriterInput];
    
    [_videoWriter startWriting];
}

/// 获取缓存路径
- (NSString*)fetchFilePath {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *fileName  = [NSString stringWithFormat:@"%ld.mp4",(long)[[NSDate date]timeIntervalSince1970]];
    NSString *dirName = @"ArtReplayVideos";
    NSString *filePath = [path stringByAppendingPathComponent:dirName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
        path = [path stringByAppendingPathComponent:dirName];
    }
    filePath = [filePath stringByAppendingPathComponent:fileName];
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if (exist) {
        fileName  = [NSString stringWithFormat:@"%ld.mp4",(long)([[NSDate date]timeIntervalSince1970]+arc4random()%100)];
        filePath = [path stringByAppendingPathComponent:fileName];
        exist = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    }
    return filePath;
}

@end
