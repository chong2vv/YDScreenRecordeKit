//
//  YDScreenRecordManager.m
//  YDScreenRecordeKit
//
//  Created by wangyuandong on 2020/7/14.
//  Copyright © 2020 chong2vv. All rights reserved.
//

#import "YDScreenRecordManager.h"
#import <ReplayKit/ReplayKit.h>
#import "RPPreviewViewController+MovieURL.h"
#import <Photos/Photos.h>

#define kWeakSelf(type)  __weak typeof(type) weak##type = type;
#define kStrongSelf(type) __strong typeof(type) type = weak##type;
@interface YDScreenRecordManager()<RPPreviewViewControllerDelegate,RPScreenRecorderDelegate>

@end

@implementation YDScreenRecordManager

static YDScreenRecordManager *_screenManager = nil;

+ (instancetype)shareManager{
    if (_screenManager == nil) {
        
        _screenManager = [[YDScreenRecordManager alloc] init];
        
    }
    return _screenManager;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        _screenManager = [super allocWithZone:zone];
        
    });
    
    return _screenManager;
}

- (id)copyWithZone:(NSZone *)zone{
    
    return self;
    
}

- (id)mutableCopyWithZone:(NSZone *)zone{
    
    return self;
    
}

- (instancetype)init{
    if (self = [super init]) {
        
    }
    return self;
}

// 开始录制屏幕
- (void)screenRecSuc:(void (^)(void))suc failure:(srerrorinfo)errorInfo{
    
    kWeakSelf(self);
    RPScreenRecorder* recorder = RPScreenRecorder.sharedRecorder;
    recorder.delegate = self;
    recorder.microphoneEnabled = NO;
    
    NSString *version = [UIDevice currentDevice].systemVersion;
    
    if ([version doubleValue] < 9.0) {
        
        YDSRErrorHandle *err = [[YDSRErrorHandle alloc] init];
        err.code = -4;
        err.msg = @"iOS9.0之后的系统才可以使用录屏功能";
        errorInfo(err);
        
    }
    
    // 先检查系统版本
    if (@available(iOS 10.0, *)) {
        
        if (recorder.isRecording) { // 正在录制中不能在录制了
            
            YDSRErrorHandle *err = [[YDSRErrorHandle alloc] init];
            err.code = -1;
            err.msg = @"录屏正在进行，无法再次开启录屏功能";
            errorInfo(err);
            
        }
        
        [recorder startRecordingWithHandler:^(NSError * _Nullable error) {
            if (!error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    weakself.isRecording = YES;
                    suc();
                    
                });
                
            }else{
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    weakself.isRecording = NO;
                    YDSRErrorHandle *err = [[YDSRErrorHandle alloc] initWithError:error];
                    errorInfo(err);
                    
                });
            }
        }];
    } else {
        if (@available(iOS 9.0, *)) {
            if (recorder.isRecording) { // 正在录制中不能在录制了
                
                weakself.isRecording = NO;
                YDSRErrorHandle *err = [[YDSRErrorHandle alloc] init];
                err.code = -1;
                err.msg = @"正在录制中";
                errorInfo(err);
                
            }
            [recorder startRecordingWithMicrophoneEnabled:YES handler:^(NSError * _Nullable error) {
                if (!error) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        weakself.isRecording = YES;
                        suc();
                        
                    });
                    
                }else{
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        weakself.isRecording = NO;
                        YDSRErrorHandle *err = [[YDSRErrorHandle alloc] initWithError:error];
                        errorInfo(err);
                        
                    });
                }
                
            }];
            
        }
        
    }
    
}

// 停止录制屏幕
- (void)stopRecSuc:(void (^)(void))suc failure:(srerrorinfo)errorInfo{
    
    NSLog(@"结束开始");
    kWeakSelf(self);
    if (!RPScreenRecorder.sharedRecorder.isRecording) {
        
        YDSRErrorHandle *err = [[YDSRErrorHandle alloc] init];
        err.code = -2;
        err.msg = @"没有正在录制的进程";
        errorInfo(err);
        
    }else{
        
        [[RPScreenRecorder sharedRecorder] stopRecordingWithHandler:^(RPPreviewViewController * _Nullable previewViewController, NSError * _Nullable error) {
            NSLog(@"结束回调");
            
            
            previewViewController.previewControllerDelegate = self;
            
            if (error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    YDSRErrorHandle *err = [[YDSRErrorHandle alloc] initWithError:error];
                    errorInfo(err);
                });
                
            }else{
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakself.isRecording = NO;
                    suc();
                    if ([previewViewController respondsToSelector:@selector(movieURL)]) {
//                        NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
//
//                        NSTimeInterval a=[dat timeIntervalSince1970];
//
//                        NSString*timeString = [NSString stringWithFormat:@"%0.f", a];//转为字符型
                        
                        NSURL *videoURL = [previewViewController.movieURL copy];
                        if ([weakself.screenRecordDelegate respondsToSelector:@selector(changeUrl:)]) {
                            [weakself.screenRecordDelegate changeUrl:videoURL];
                        }
//                        BOOL compatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([videoURL path]);
//                        if(compatible){
//                                                   UISaveVideoAtPathToSavedPhotosAlbum([videoURL path],self,@selector(savedPhotoImage:didFinishSavingWithError:contextInfo:),nil);
//                                               }
                        
                    }
                });
            }
        }];
    }
}

- (NSURL *)getVideosURLPath:(NSString *)videoName{
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    documents = [self action_addFiles:documents];//判断文件是否存在
    NSString *failPath = [documents stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",videoName]];
    NSURL *filUrl = [NSURL fileURLWithPath:failPath];
    return filUrl;
}

//新建文件并返回地址
- (NSString *)action_addFiles:(NSString *)path{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        //文件夹已存在
    } else {
        //创建文件夹
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}


#pragma mark -
//保存视频完成之后的回调 - Private
- (void)savedPhotoImage:(UIImage*)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    
    if (self.screenRecordDelegate && [self.screenRecordDelegate respondsToSelector:@selector(savedPhotoImage: didFinishSavingWithError: contextInfo:)]){
        
        [self.screenRecordDelegate savedPhotoImage:image didFinishSavingWithError:error contextInfo:contextInfo];
        
    }
    
    __block NSData *data;
    __block BOOL isError; // 判断进入didFinishSavingWithError之后有没有错误
    if (error) {
        
        isError = YES;
        
    } else {
        
        isError = NO;
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]]; //按创建日期获取
        PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsWithOptions:options];
        PHAsset *phasset = [assetsFetchResults lastObject];
        if (phasset){
            if (phasset.mediaType == PHAssetMediaTypeVideo) {
                
                PHImageManager *manager = [PHImageManager defaultManager];
                [manager requestAVAssetForVideo:phasset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                    
                    isError = NO;
                    AVURLAsset *urlAsset = (AVURLAsset *)asset;
                    NSURL *videoURL = urlAsset.URL;
                    data = [NSData dataWithContentsOfURL:videoURL];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        // delegate
                        if (self.screenRecordDelegate && [self.screenRecordDelegate respondsToSelector:@selector(savedVideoData:didFinishSavingWithError:)]){
                            
                            [self.screenRecordDelegate savedVideoData:data didFinishSavingWithError:isError];
                            
                        }
                        
                    });
                    
                }];
                
            } else {
                
                isError = YES;
                // delegate
                if (self.screenRecordDelegate && [self.screenRecordDelegate respondsToSelector:@selector(savedVideoData:didFinishSavingWithError:)]){
                    
                    [self.screenRecordDelegate savedVideoData:data didFinishSavingWithError:isError];
                    
                }
            }
            
        }else{
            
            isError = NO;
            // delegate
            if (self.screenRecordDelegate && [self.screenRecordDelegate respondsToSelector:@selector(savedVideoData:didFinishSavingWithError:)]){
                
                [self.screenRecordDelegate savedVideoData:data didFinishSavingWithError:isError];
                
            }
            
        }
        
    }
    
}

#pragma mark - RPScreenRecorder Delegate
-(void)screenRecorder:(RPScreenRecorder *)screenRecorder didStopRecordingWithPreviewViewController:(RPPreviewViewController *)previewViewController error:(NSError *)error{
    
    if (self.screenRecordDelegate && [self.screenRecordDelegate respondsToSelector:@selector(recStateDidChange:withError:)]){
        
        RecState state = RecState_Stop;
        [self.screenRecordDelegate recStateDidChange:state withError: NULL];
        
    }
    
}

// 监听replaykit是否可用，比如状态发生变化（比如录制过程中，切入设置，关闭权限。）会回调该方法。
-(void)screenRecorderDidChangeAvailability:(RPScreenRecorder *)screenRecorder{
    
    
}

#pragma mark - Setter
- (void)setIsRecording:(BOOL)isRecording{
    _isRecording = isRecording;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.screenRecordDelegate && [self.screenRecordDelegate respondsToSelector:@selector(recStateDidChange:withError:)]){
            RecState state;
            if (isRecording) {
                
                state = RecState_Rec;
                
            }else{
                
                state = RecState_Stop;
                
            }
            
            [self.screenRecordDelegate recStateDidChange:state withError: NULL];
            
        }
        
    });
    
}

@end
