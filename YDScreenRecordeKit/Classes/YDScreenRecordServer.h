//
//  YDScreenRecordServer.m
//  YDScreenRecordeKit
//
//  Created by wangyuandong on 2020/7/14.
//  Copyright © 2020 chong2vv. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YDScreenRecordServer : NSObject

@property (nonatomic, assign) NSInteger                        teacherId;
@property (nonatomic, assign) NSInteger                        studentId;
@property (nonatomic, copy) void (^starSuc)(void);
@property (nonatomic, copy) void (^saveSuc)(NSString *path);

@property (nonatomic, copy) void(^VideoSction)(NSString *name,NSInteger duration,NSInteger beginTime, NSString *path);

- (void)startScreenRecord;

- (void)stopRecordComplete:(void(^)(BOOL success ,NSString *path))complete;

@end

NS_ASSUME_NONNULL_END
