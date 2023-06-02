//
//  YDSRErrorInfo.m
//  YDScreenRecordeKit
//
//  Created by wangyuandong on 2020/7/14.
//  Copyright © 2020 chong2vv. All rights reserved.
//

#import "YDSRErrorInfo.h"

@implementation YDSRErrorInfo
@synthesize code;
@synthesize msg;
@synthesize isError;

- (id)initWithDic:(NSDictionary *)dic
{
    if (self = [super init]) {
        self.code = [[dic objectForKey: @"error_code"] integerValue];
        self.msg  = [dic objectForKey: @"error_msg"];
        if (self.code == 0) {
            isError = NO;
        }
        else{
            isError = YES;
        }
    }
    return self;
}

- (instancetype)initWithDefault
{
    if (self = [super init]) {
        self.msg = @"一般错误";
        self.code = 1;
    }
    return self;
}


@end
