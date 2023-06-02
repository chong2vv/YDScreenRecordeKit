//
//  YDScreenRecordManager.h
//  YDScreenRecordeKit
//
//  Created by wangyuandong on 2020/7/14.
//  Copyright © 2020 chong2vv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YDSRErrorHandle.h"
#import "YDSRErrorInfo.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
// 录屏状态
typedef NS_ENUM(NSInteger, RecState) {
    
    RecState_Rec = 0,
    RecState_Stop = 1
    
};
@protocol YDScreenRecordDelegate <NSObject>

@optional

/**
 保存到相册的代理方法

 @param image 路径，好像没什么用
 @param error 错误信息
 @param contextInfo 额外信息
 */
- (void)savedPhotoImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;

/**
 生成视频的二进制文件
 
 @param data 二进制数据
 @param isError 是否有错误
 */
- (void)savedVideoData:(NSData*)data didFinishSavingWithError:(BOOL)isError;

/**
 录制状态变化的代理方法

 @param state 状态
 @param error 错误信息
 */
-(void)recStateDidChange:(RecState)state withError:(NSError *__nullable)error;

-(void)changeUrl:(NSURL *)url;

@end

typedef void(^srerrorinfo)(YDSRErrorHandle *error);
//typedef void(^stopUrl)(NSURL *url);

@interface YDScreenRecordManager : NSObject

+ (instancetype)shareManager;

@property(nonatomic,weak)id<YDScreenRecordDelegate>  screenRecordDelegate;

/**
 是否正在录制中
 */
@property(nonatomic, assign) BOOL isRecording;

/**
 录制屏幕

 @param suc 成功回调
 @param errorInfo 错误信息
 */
- (void)screenRecSuc:(void (^)(void))suc failure:(srerrorinfo)errorInfo;

/**
 停止录制屏幕

 @param suc 成功回调
 @param errorInfo 错误信息
 */
- (void)stopRecSuc:(void (^)(void))suc failure:(srerrorinfo)errorInfo;

@end

NS_ASSUME_NONNULL_END
