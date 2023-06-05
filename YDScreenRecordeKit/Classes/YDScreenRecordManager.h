//
//  YDScreenRecordServer.m
//  YDScreenRecordeKit
//
//  Created by wangyuandong on 2020/7/14.
//  Copyright © 2020 chong2vv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YDSRErrorHandle.h"
#import "YDSRErrorInfo.h"

NS_ASSUME_NONNULL_BEGIN

// 录屏状态
typedef NS_ENUM(NSInteger, RecState) {
    
    RecState_Rec = 0,
    RecState_Stop = 1
    
};

typedef void(^YDRecordFailure)(YDSRErrorHandle *error);
typedef void(^YDRecordStartSuccess)(void);
typedef void(^YDRecordStopSuccess)(NSString *name, NSInteger duration, NSInteger beginTime, NSString *path);

@interface YDScreenRecordManager : NSObject

- (void)startScreenRecord:(YDRecordStartSuccess) onSuccess failure:(YDRecordFailure) failure;

- (void)stopRecordComplete:(YDRecordStopSuccess) onSuccess failure:(YDRecordFailure) failure;

@end

NS_ASSUME_NONNULL_END
