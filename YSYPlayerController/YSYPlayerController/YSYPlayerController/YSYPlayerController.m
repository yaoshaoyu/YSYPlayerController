//
//  YSYPlayerController.m
//  demo
//
//  Created by 吕成翘 on 16/12/15.
//  Copyright © 2016年 Weitac. All rights reserved.
//

#import "YSYPlayerController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMotion/CoreMotion.h>
#import <Masonry.h>


/** 顶部和底部视图的颜色 */
#define kTopBottomViewBackgroundColor [UIColor colorWithWhite:0.4 alpha:0.4]
/** 全屏大小 */
#define kFullScreenFrame [UIScreen mainScreen].bounds


@interface YSYPlayerController ()

/** 加载菊花视图 */
@property (strong, nonatomic) UIActivityIndicatorView *loadingView;
/** 加载失败标签 */
@property (strong, nonatomic) UILabel *loadFailedLabel;
/** 顶部视图 */
@property (strong, nonatomic) UIView *topView;
/** 标题标签 */
@property (strong, nonatomic) UILabel *titleLabel;
/** 底部视图 */
@property (strong, nonatomic) UIView *bottomView;
/** 播放暂停按钮 */
@property (strong, nonatomic) UIButton *playPauseButton;
/** 全屏窗口按钮 */
@property (strong, nonatomic) UIButton *fullWindowScreenButton;
/** 已播时长标签 */
@property (strong, nonatomic) UILabel *playedTimeLabel;
/** 总时长标签 */
@property (strong, nonatomic) UILabel *totalTimeLabel;
/** 播放进度滑竿 */
@property (strong, nonatomic) UISlider *progressSlider;
/** 缓冲进度条 */
@property (strong, nonatomic) UIProgressView *loadingProgress;
/** 底部蒙板视图 */
@property (nonatomic, strong) UIView *darkView;
/** 视频播放项目 */
@property (strong, nonatomic) AVPlayerItem *playerItem;
/** 视频播放器 */
@property (strong, nonatomic) AVPlayer *player;
/** 视频播放层 */
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
/** 加速计传感器 */
@property (strong, nonatomic) CMMotionManager *motionManager;
/** 隐藏顶部和底部视图定时器 */
@property (strong, nonatomic) NSTimer *autoHiddenTimer;
/** 单击屏幕手势 */
@property (strong, nonatomic) UITapGestureRecognizer *screenSingleTap;
/** 双击屏幕手势 */
@property (strong, nonatomic) UITapGestureRecognizer *screenDoubleTap;

@end


@implementation YSYPlayerController {
    /** 是否正在滑动进度条 */
    BOOL _isSliding;
    /** 竖屏视图大小 */
    CGRect _verticalFrame;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupConstraints];
    [self setupGestureRecognizer];
    [self setupMotionManager];
}

- (void)dealloc {
    [_playerItem removeObserver:self forKeyPath:@"status"];
    [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (void)setURLString:(NSString *)URLString {
    _URLString = URLString;
    
    NSURL *url = [NSURL URLWithString:URLString];
    
    _playerItem = [AVPlayerItem playerItemWithURL:url];
    
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = self.view.layer.bounds;
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer insertSublayer:_playerLayer atIndex:0];
    
    [self setupObserver];
    [self setupNotification];
}

- (instancetype)initWithFrame:(CGRect)frame parentViewController:(UIViewController *)parentViewController {
    if (self = [super init]) {
        self.view.frame = frame;
        
        _verticalFrame = frame;
        
        [parentViewController.view addSubview:self.view];
        [parentViewController addChildViewController:self];
        [self didMoveToParentViewController:parentViewController];
    }
    
    return self;
}

#pragma mark - PublicMethod
- (void)pause {
    _playPauseButton.selected = YES;
    
    [_player pause];
}

- (void)play {
    _playPauseButton.selected = NO;
    
    [_player play];
}

#pragma mark - PrivateMethod
/**
 设置界面
 */
- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    
    _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.view addSubview:_loadingView];
    [_loadingView startAnimating];
    
    _loadFailedLabel = [UILabel new];
    _loadFailedLabel.textColor = [UIColor whiteColor];
    _loadFailedLabel.textAlignment = NSTextAlignmentCenter;
    _loadFailedLabel.backgroundColor = [UIColor clearColor];
    _loadFailedLabel.text = @"视频加载失败";
    _loadFailedLabel.hidden = YES;
    [_loadFailedLabel sizeToFit];
    [self.view addSubview:_loadFailedLabel];
    
    _darkView = [[UIView alloc] initWithFrame:kFullScreenFrame];
    _darkView.backgroundColor = [UIColor blackColor];
    
    [self setupTopView];
    [self setupBottomView];
}

/**
 设置顶部视图
 */
- (void)setupTopView {
    _topView = [UIView new];
    _topView.backgroundColor = kTopBottomViewBackgroundColor;
    [self.view addSubview:_topView];
    
    _titleLabel = [UILabel new];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.font = [UIFont systemFontOfSize:17.0];
    _titleLabel.text = @"标题";
    [_titleLabel sizeToFit];
    [_topView addSubview:_titleLabel];
}

/**
 设置底部视图
 */
- (void)setupBottomView {
    _bottomView = [[UIView alloc]init];
    _bottomView.backgroundColor = kTopBottomViewBackgroundColor;
    [self.view addSubview:_bottomView];
    
    _playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playPauseButton.showsTouchWhenHighlighted = YES;
    [_playPauseButton setImage:[UIImage imageNamed:@"player_pause"] forState:UIControlStateNormal];
    [_playPauseButton setImage:[UIImage imageNamed:@"player_play"] forState:UIControlStateSelected];
    [_playPauseButton addTarget:self action:@selector(playPauseButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_playPauseButton];
    
    _playedTimeLabel = [UILabel new];
    _playedTimeLabel.textColor = [UIColor whiteColor];
    _playedTimeLabel.textAlignment = NSTextAlignmentCenter;
    _playedTimeLabel.backgroundColor = [UIColor clearColor];
    _playedTimeLabel.font = [UIFont systemFontOfSize:11];
    _playedTimeLabel.text = @"00:00";
    [_playedTimeLabel sizeToFit];
    [_bottomView addSubview:_playedTimeLabel];
    
    _loadingProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _loadingProgress.progressTintColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.7];
    _loadingProgress.trackTintColor = [UIColor lightGrayColor];
    _loadingProgress.progress = 0.0;
    [_bottomView addSubview:_loadingProgress];
    
    _progressSlider = [UISlider new];
    _progressSlider.value = 0.0;
    _progressSlider.minimumValue = 0.0;
    _progressSlider.maximumTrackTintColor = [UIColor clearColor];
    _progressSlider.backgroundColor = [UIColor clearColor];
    [_progressSlider setThumbImage:[UIImage imageNamed:@"player_thumb"] forState:UIControlStateNormal];
    [_progressSlider addTarget:self action:@selector(progressSliderTouchDownAction:) forControlEvents:UIControlEventTouchDown];
    [_progressSlider addTarget:self action:@selector(progressSliderTouchUpInsideAction:) forControlEvents:UIControlEventTouchUpInside];
    [_progressSlider addTarget:self action:@selector(progressSliderValueChangedAction:)  forControlEvents:UIControlEventValueChanged];
    [_bottomView addSubview:_progressSlider];
    
    _totalTimeLabel = [UILabel new];
    _totalTimeLabel.textColor = [UIColor whiteColor];
    _totalTimeLabel.textAlignment = NSTextAlignmentCenter;
    _totalTimeLabel.backgroundColor = [UIColor clearColor];
    _totalTimeLabel.font = [UIFont systemFontOfSize:11];
    _totalTimeLabel.text = @"00:00";
    [_totalTimeLabel sizeToFit];
    [_bottomView addSubview:_totalTimeLabel];
    
    _fullWindowScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _fullWindowScreenButton.showsTouchWhenHighlighted = YES;
    [_fullWindowScreenButton addTarget:self action:@selector(fullWindowScreenButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_fullWindowScreenButton setImage:[UIImage imageNamed:@"player_fullscreen"] forState:UIControlStateNormal];
    [_fullWindowScreenButton setImage:[UIImage imageNamed:@"player_windowscreen"] forState:UIControlStateSelected];
    [_bottomView addSubview:_fullWindowScreenButton];
}

/**
 设置视图约束
 */
- (void)setupConstraints {
    [_loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    [_loadFailedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];
    
    [_topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(40);
    }];
    
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(_topView);
    }];
    
    [_bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self.view);
        make.height.mas_equalTo(40);
    }];
    
    [_playPauseButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(40, 40));
        make.left.bottom.equalTo(_bottomView);
    }];
    
    [_playedTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(40, 40));
        make.left.equalTo(_playPauseButton.mas_right);
        make.centerY.equalTo(_bottomView);
    }];
    
    [_loadingProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(_progressSlider);
        make.left.right.equalTo(_progressSlider);
    }];
    
    [_progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(_bottomView);
        make.left.equalTo(_playedTimeLabel.mas_right).offset(5);
        make.right.equalTo(_totalTimeLabel.mas_left).offset(-5);
    }];
    
    [_totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(40, 40));
        make.right.equalTo(_fullWindowScreenButton.mas_left);
        make.centerY.equalTo(_bottomView);
    }];
    
    [_fullWindowScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(40, 40));
        make.bottom.right.equalTo(_bottomView);
    }];
}

/**
 设置手势
 */
- (void)setupGestureRecognizer {
    UITapGestureRecognizer *screenSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenSingleTapAction:)];
    screenSingleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:screenSingleTap];
    
    UITapGestureRecognizer *screenDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(screenDoubleTapAction:)];
    screenDoubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:screenDoubleTap];
    
    [screenSingleTap requireGestureRecognizerToFail:screenDoubleTap];
    
    UITapGestureRecognizer *progressSliderTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(progressSliderTapAction:)];
    [_progressSlider addGestureRecognizer:progressSliderTap];
}

/**
 设置观察者
 */
- (void)setupObserver {
    __weak typeof(self)weakSelf = self;
    
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    [_player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.01, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float currentPlayTime = weakSelf.playerItem.currentTime.value / weakSelf.playerItem.currentTime.timescale;
        
        if (_isSliding == NO) {
            weakSelf.progressSlider.value = currentPlayTime;
            weakSelf.playedTimeLabel.text = [weakSelf convertTime:currentPlayTime];
        }
    }];
}

/**
 设置通知
 */
- (void)setupNotification {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterforeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:)name:UIDeviceOrientationDidChangeNotification object:nil];
}

/**
 设置加速计传感器
 */
- (void)setupMotionManager {
    _motionManager = [CMMotionManager new];
    
    if (!_motionManager.isAccelerometerAvailable) {
        return;
    }
    
    [_motionManager startAccelerometerUpdates];
}

/**
 * 把秒转换成格式化时间
 **/
- (NSString *)convertTime:(CGFloat)second{
    NSDateFormatter *formatter = [NSDateFormatter new];
    
    if (second / 3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
    
    NSString *newTime = [formatter stringFromDate:date];
    
    return newTime;
}

/**
 旋转视图
 
 @param pi 旋转角度
 @param frame 旋转完成后的大小
 @param orientation 旋转完成后status的方向
 @param isHidden 旋转完成后是否显示黑色蒙板视图
 */
- (void)viewTransformRotate:(CGFloat)pi frame:(CGRect)frame statusBarOrientation:(UIInterfaceOrientation)orientation isHiddenDarkView:(BOOL)isHidden {
    if(isHidden == YES) {
        [_darkView removeFromSuperview];
    }
    
    [UIApplication sharedApplication].statusBarHidden = YES;
    
    [UIView animateWithDuration:[[UIApplication sharedApplication] statusBarOrientationAnimationDuration] animations:^{
        self.view.transform = CGAffineTransformRotate(self.view.transform, pi);
        
        if (!CGRectIsNull(frame)) {
            self.view.frame = frame;
            
            _playerLayer.frame = self.view.bounds;
        }
    } completion:^(BOOL finished) {
        [UIApplication sharedApplication].statusBarHidden = NO;
        
        [[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];
        
        if (isHidden == NO) {
            [self.parentViewController.view insertSubview:_darkView belowSubview:self.view];
        }
    }];
}

/**
 自动隐藏顶部和底部视图
 */
- (void)autoHiddenTopBottomView {
    if (_player.rate == 0.0 && _playPauseButton.selected == YES) {
        return;
    }
    
    if([_autoHiddenTimer isValid]) {
        [_autoHiddenTimer invalidate];
        _autoHiddenTimer = nil;
    }
    
    _autoHiddenTimer = [NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(autoHiddenTopBottomViewTimerAction:) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:_autoHiddenTimer forMode:NSRunLoopCommonModes];
}

#pragma mark - ResponseEventAction
- (void)playPauseButtonAction:(UIButton *)sender {
    NSLog(@"点击了播放暂停按钮");
    
    if (_player.rate == 0.0 && sender.selected == YES) {
        sender.selected = NO;
        
        [_player play];
    } else if (_player.rate > 0.0 && sender.selected == NO) {
        sender.selected = YES;
        
        [_player pause];
    }
}

- (void)fullWindowScreenButtonAction:(UIButton *)sender {
    NSLog(@"点击了全屏窗口按钮");
    
    _fullWindowScreenButton.selected = !_fullWindowScreenButton.selected;
    
    CMAcceleration acceleration = _motionManager.accelerometerData.acceleration;
    CGFloat xACC = acceleration.x;
    
    if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) {
        if (xACC <= 0) {
            [self viewTransformRotate:M_PI_2 frame:kFullScreenFrame statusBarOrientation:UIInterfaceOrientationLandscapeRight isHiddenDarkView:NO];
        } else if (xACC > 0) {
            [self viewTransformRotate:-M_PI_2 frame:kFullScreenFrame statusBarOrientation:UIInterfaceOrientationLandscapeLeft isHiddenDarkView:NO];
        }
    } else if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
        [self viewTransformRotate:-M_PI_2 frame:_verticalFrame statusBarOrientation:UIInterfaceOrientationPortrait isHiddenDarkView:YES];
    } else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
        [self viewTransformRotate:M_PI_2 frame:_verticalFrame statusBarOrientation:UIInterfaceOrientationPortrait isHiddenDarkView:YES];
    }
}

- (void)progressSliderTouchDownAction:(UISlider *)sender {
    NSLog(@"按下了进度条按钮");
    
    [self pause];
}

- (void)progressSliderTouchUpInsideAction:(UISlider *)sender {
    NSLog(@"进度条按钮滑动结束");
    
    _isSliding = NO;
    
    [self play];
}

- (void)progressSliderValueChangedAction:(UISlider *)sender {
    NSLog(@"进度条按钮正在滑动");
    
    _isSliding = YES;
    
    [self pause];
    
    CMTime changedTime = CMTimeMakeWithSeconds(_progressSlider.value, 1.0);
    
    _playedTimeLabel.text = [self convertTime:_progressSlider.value];
    
    [_playerItem seekToTime:changedTime];
}

- (void)screenSingleTapAction:(UITapGestureRecognizer *)recognizer {
    NSLog(@"单击了屏幕");
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoHiddenTopBottomViewTimerAction:) object:nil];
    
    [UIView animateWithDuration:0.5 animations:^{
        _topView.alpha = 1.0;
        _bottomView.alpha = 1.0;
    } completion:^(BOOL finished) {
        [self autoHiddenTopBottomView];
    }];
}

- (void)screenDoubleTapAction:(UITapGestureRecognizer *)recognizer {
    NSLog(@"双击了屏幕");
    
    [self playPauseButtonAction:_playPauseButton];
}

- (void)progressSliderTapAction:(UITapGestureRecognizer *)recognizer {
    NSLog(@"点击了进度条");
    
    [self screenSingleTapAction:_screenSingleTap];
    
    CGPoint touchLocation = [recognizer locationInView:_progressSlider];
    
    CGFloat value = (_progressSlider.maximumValue - _progressSlider.minimumValue) * (touchLocation.x / _progressSlider.frame.size.width);

    [_progressSlider setValue:value animated:YES];
    _playedTimeLabel.text = [self convertTime:_progressSlider.value];

    [_player seekToTime:CMTimeMakeWithSeconds(_progressSlider.value, 1.0)];
    
    if (_player.rate == 0.0 && _playPauseButton.selected == YES) {
        _playPauseButton.selected = NO;
        
        [_player play];
    }
}

#pragma mark - ObserveEventAction
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = AVPlayerItemStatusUnknown;
        
        NSNumber *statusNumber = change[NSKeyValueChangeNewKey];
        
        if ([statusNumber isKindOfClass:[NSNumber class]]) {
            status = statusNumber.integerValue;
        }
        
        switch (status) {
            case AVPlayerItemStatusReadyToPlay: {
                NSLog(@"视频加载成功");
                
                float totalDuration = CMTimeGetSeconds(_playerItem.duration);
                
                [_loadingView stopAnimating];
                _progressSlider.maximumValue = totalDuration;
                _totalTimeLabel.text = [self convertTime:totalDuration];
                
                [_player play];
                
                [self autoHiddenTopBottomView];
            }
                break;
            case AVPlayerItemStatusFailed: {
                NSLog(@"视频加载失败");
                
                [_loadingView stopAnimating];
                _loadFailedLabel.hidden = YES;
            }
                break;
            case AVPlayerItemStatusUnknown: {
                NSLog(@"未知状态");
            }
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray<NSValue *> *loadedTimeRanges = _playerItem.loadedTimeRanges;
        
        CMTimeRange timeRange = loadedTimeRanges.firstObject.CMTimeRangeValue;
        
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        
        NSTimeInterval bufferSecounds = startSeconds + durationSeconds;
        
        float totalDuration = CMTimeGetSeconds(_playerItem.duration);
        
        [_loadingProgress setProgress:bufferSecounds / totalDuration animated:YES];
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        [_loadingView startAnimating];
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        [_loadingView stopAnimating];
    }
}
#pragma mark - TimerEventAction
- (void)autoHiddenTopBottomViewTimerAction:(NSTimer *)timer {
    [UIView animateWithDuration:0.5 animations:^{
        _topView.alpha = 0.0;
        _bottomView.alpha = 0.0;
        
        if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait) {
            return;
        }
        
        [UIApplication sharedApplication].statusBarHidden = YES;
    }];
}

#pragma mark - NotificationEventAction
- (void)playerItemDidPlayToEndTime:(NSNotification *)note {
    [_playerItem seekToTime:kCMTimeZero];
    
    [self pause];
}

- (void)applicationWillEnterBackground:(NSNotification *)note {
    [self pause];
}

- (void)applicationDidEnterforeground:(NSNotification *)note {
    [self play];
}

- (void)deviceOrientationDidChange:(NSNotification *)note {
    UIDeviceOrientation orientenation = [UIDevice currentDevice].orientation;
    switch (orientenation) {
        case UIDeviceOrientationLandscapeLeft: {
            if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft) {
                [self viewTransformRotate:M_PI frame:CGRectNull statusBarOrientation:UIInterfaceOrientationLandscapeRight isHiddenDarkView:NO];
                
                _fullWindowScreenButton.selected = YES;
            } else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) {
                [self viewTransformRotate:M_PI_2 frame:kFullScreenFrame statusBarOrientation:UIInterfaceOrientationLandscapeRight isHiddenDarkView:NO];
                
                _fullWindowScreenButton.selected = YES;
            }
        }
            break;
            
        case UIDeviceOrientationLandscapeRight: {
            if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight) {
                [self viewTransformRotate:M_PI frame:CGRectNull statusBarOrientation:UIInterfaceOrientationLandscapeLeft isHiddenDarkView:NO];
                
                _fullWindowScreenButton.selected = YES;
            } else if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait) {
                [self viewTransformRotate:-M_PI_2 frame:kFullScreenFrame statusBarOrientation:UIInterfaceOrientationLandscapeLeft  isHiddenDarkView:NO];
                
                _fullWindowScreenButton.selected = YES;
            }
        }
            break;
        default:
            break;
    }
}

@end
