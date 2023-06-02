//
//  YDSRErrorInfo.h
//  YDScreenRecordeKit
//
//  Created by wangyuandong on 2020/7/14.
//  Copyright © 2020 chong2vv. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YDSRErrorInfo : NSObject
{
    NSInteger   code;
    NSString    *msg;
    BOOL        isError;
}

/**
 错误码
 */
@property (nonatomic, assign) NSInteger  code;

/**
 错误信息
 */
@property (nonatomic, copy) NSString *msg;

/**
 是否有错误
 */
@property (nonatomic, assign) BOOL isError;

- (id)initWithDic:(NSDictionary *)dic;

- (instancetype)initWithDefault;

@end

NS_ASSUME_NONNULL_END
