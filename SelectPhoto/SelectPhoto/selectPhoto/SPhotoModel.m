//
//  SPhotoModel.m
//  SelectPhoto
//
//  Created by wangtian on 15/7/23.
//  Copyright (c) 2015年 wangtian. All rights reserved.
//

#import "SPhotoModel.h"


#define imageScale 0.1

static ALAssetsLibrary *library = nil;

@implementation SPhotoModel

+ (void)getLocalVideoWithFinishBlock:(TYRequestFinishBlock)finishBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableArray *data = [[NSMutableArray alloc] init];
        ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop) {
            
            if (group != nil) {
                
                [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                [data addObject:group];
            }
            else{
                
                //从读取到的资源里面获得 视频信息
                NSLog(@"获得完图片group用时%f",[NSObject endConutTime]);
                [self getVideoWithDataArray:data andFinishBlock:finishBlock];
            }
        };
        
        ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error){
            
            //获得视频信息失败的处理
            [self getLocalVideoFailureWithError:error andFinishBlock:finishBlock];
        };
        
        library = [[ALAssetsLibrary alloc]  init];
        [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
         
                                     usingBlock:listGroupBlock failureBlock:failureBlock];
    });
}

+ (void)getVideoWithDataArray:(NSMutableArray *)data andFinishBlock:(TYRequestFinishBlock)finishBlock
{
    NSMutableArray *localPhotoArray = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < data.count; i++) {
        
        id obj = data[i];
        [obj enumerateAssetsWithOptions:(NSEnumerationConcurrent | NSEnumerationReverse) usingBlock:^(ALAsset *result, NSUInteger idx, BOOL *stop) {
            
            if (result)
            {
                SPhotoModel *model = [[SPhotoModel alloc] init];
//                UIImage *image = [UIImage imageWithCGImage:[result aspectRatioThumbnail]];
               // model.bili = image.size.width / image.size.height;
                CGSize size = [[result defaultRepresentation] dimensions];
                model.bili = size.width / size.height;
                model.imageAlsset = result;
                [localPhotoArray addObject:model];
            }
        }];
    }
    NSLog(@"读取group用时%f",[NSObject endConutTime]);
    dispatch_async(dispatch_get_main_queue(), ^{
        
        RequestResult *result = [[RequestResult alloc] init];
        result.dataDic = localPhotoArray;
        result.state = YES;
        if (localPhotoArray.count == 0) {
            
            result.state = NO;
            result.descripe = @"没有发现本地图片";
        }
        finishBlock(result);
    });
}

#pragma mark - 获得本地视频信息失败处理
+ (void)getLocalVideoFailureWithError:(NSError *)error andFinishBlock:(TYRequestFinishBlock)finishBlock
{
    NSString *errorMessage = nil;
    switch ([error code]) {
            
        case ALAssetsLibraryAccessUserDeniedError:
            
        case ALAssetsLibraryAccessGloballyDeniedError:
            
            errorMessage = @"用户拒绝访问相册,请在<隐私>中开启";
            break;
            
        default:
            errorMessage = @"加载本地照片出错，请稍后再试";
            break;
            
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        finishBlock(TYRequestResult(NO, errorMessage));
    });
}

- (UIImage *)getImage
{
    return [UIImage imageWithCGImage:[self.imageAlsset aspectRatioThumbnail]];
}

+ (NSMutableArray *)getImagesWithModelArray:(NSMutableArray *)modelArray
{
    NSMutableArray *imageArray = [[NSMutableArray alloc] init];
    
    [modelArray enumerateObjectsUsingBlock:^(SPhotoModel *obj, NSUInteger idx, BOOL *stop) {
        
        [imageArray addObject:[obj getImage]];
    }];
    return imageArray;
}

+ (void)releaseResource
{
    library = nil;
}

@end
