//
//  YDVideoWriteServer.h
//  YDScreenRecordeKit
//
//  Created by wangyuandong on 2020/7/14.
//  Copyright © 2020 chong2vv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YDVideoWriteServer : NSObject

@property (nonatomic, assign,readonly) BOOL          isWrite;

- (instancetype)initWithFinishCompletion:(void(^)(NSString *path))complete;

/// 构建存储器
- (void)resetAndConstructWrite;

/// 拼接视频帧
/// @param sampleBuffer 视频帧
- (void)appendVSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/// 拼接应用内音频帧
/// @param sampleBuffer audiodata
- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/// 拼接麦克风声音
/// @param sampleBuffer audiodata
- (void)appendMicSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/// 结束视频写入生成视频
- (void)stopWrite;


@end

NS_ASSUME_NONNULL_END
