//
//  YSYPlayerController.h
//  demo
//
//  Created by 吕成翘 on 16/12/15.
//  Copyright © 2016年 Weitac. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface YSYPlayerController : UIViewController

/** 视频地址 */
@property (strong, nonatomic) NSString *URLString;

/**
 实例化视频播放控制器

 @param frame 视频播放器的大小
 @param parentViewController 添加到的父控制器
 @return 视频播放控制器s
 */
- (instancetype)initWithFrame:(CGRect)frame parentViewController:(UIViewController *)parentViewController;
/**
 暂停
 */
- (void)pause;
/**
 播放
 */
- (void)play;

@end
