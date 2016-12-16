//
//  ViewController.m
//  YSYPlayerController
//
//  Created by 吕成翘 on 16/12/16.
//  Copyright © 2016年 Weitac. All rights reserved.
//

#import "ViewController.h"
#import "YSYPlayerController.h"


#warning 在 info.plist文件中，添加 View controller-based status bar appearance 项并设为 NO。


@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect playerFrame = CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width / 16 * 9);
    
    YSYPlayerController *playerController = [[YSYPlayerController alloc] initWithFrame:playerFrame parentViewController:self];
    playerController.URLString = @"http://flv2.bn.netease.com/videolib3/1609/12/yRxoB7561/SD/yRxoB7561-mobile.mp4";
}

- (BOOL)shouldAutorotate {
    return NO;
}

@end
