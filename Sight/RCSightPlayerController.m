//
//  RCSightPlayerController.m
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/29.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import "RCSightPlayerController.h"
#import "RCSightPlayerView.h"
#import "RCSightProgressView.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCDownloadHelper.h"
#import "RongSightAdaptiveHeader.h"
#import "RCSightExtensionModule.h"

// AVPlayerItem's status property
#define STATUS_KEYPATH @"status"
#define RATE_KEYPATH @"rate"
/// 播放进度刷新频率
#define REFRESH_INTERVAL 0.01f

@interface RCSightPlayerController () <RCSightTransportDelegate, NSURLSessionDelegate>

@property (strong, nonatomic) AVAsset *asset;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) RCSightPlayerView *playerView;
@property (strong, nonatomic) UILabel *errorTipsLabel;
@property (strong, nonatomic) RCSightProgressView *progressView;

@property (weak, nonatomic) id<RCSightPlayerTransport, RCSightPlayerOverlay> transport;

@property (strong, nonatomic) id timeObserver;
@property (strong, nonatomic) id itemEndObserver;
@property (assign, nonatomic) float lastPlaybackRate;

@property (assign, nonatomic) BOOL isPlaying;

@property (assign, nonatomic) BOOL canceling;

@property (copy, nonatomic) void (^completion)(void);
@property (copy, nonatomic) void (^error)(NSError *error);

@property (assign, nonatomic) BOOL isAddStatusObserver;

@property (nonatomic, strong) NSURLSession *session;

@property (nonatomic, copy) NSString *localPath;
@end

@implementation RCSightPlayerController

#pragma mark - Init
- (instancetype)initWithURL:(NSURL *)assetURL autoPlay:(BOOL)isauto;
{
    if (self = [super init]) {
        [RCSightExtensionModule sharedInstance].isSightPlayerHolding = YES;
        self.transport.delegate = self;
        self.autoPlay = isauto;
        self.rcSightURL = assetURL;
        [self registerNotificationCenter];

    }
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [RCSightExtensionModule sharedInstance].isSightPlayerHolding = YES;
        self.transport.delegate = self;
        [self registerNotificationCenter];
    }
    return self;
}

#pragma mark - Deinit

- (void)dealloc {
    [RCSightExtensionModule sharedInstance].isSightPlayerHolding = NO;
    if (self.isAddStatusObserver) {
        [self.playerItem removeObserver:self forKeyPath:STATUS_KEYPATH];
    }
    [self.player removeObserver:self forKeyPath:RATE_KEYPATH];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_itemEndObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_itemEndObserver
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:_playerItem];
    }
    if (_timeObserver && _player) {
        [_player removeTimeObserver:_timeObserver];
    }
}

#pragma mark - Api

- (void)setRcSightURL:(NSURL *)assetURL {
    _rcSightURL = assetURL;
    if (self.overlayHidden) {
        [self.transport hideCenterPlayBtn];
        [self.transport setControlBarHidden:YES];
    }
    _asset = nil;
    _playerItem = nil;
    [self resetPlayer];
    _timeObserver = nil;
}

- (void)setOverlayHidden:(BOOL)overlayHidden {
    _overlayHidden = overlayHidden;
    if (self.overlayHidden) {
        [self.transport hideCenterPlayBtn];
        [self.transport setControlBarHidden:YES];
    }
}

- (UIView *)view {
    return self.playerView;
}

- (id<RCSightPlayerOverlay>)overlay {
    return self.playerView.transport;
}

- (nullable UIImage *)firstFrameImage {
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.rcSightURL.path]) {
        return nil;
    }

    NSString *imagePath = [[self.rcSightURL.path stringByDeletingPathExtension] stringByAppendingString:@".png"];
    NSRange range = [imagePath rangeOfString:NSTemporaryDirectory()];
    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath] && range.location == NSNotFound) {
        return [UIImage imageWithContentsOfFile:imagePath];
    }

    // AVAsset* assert = [AVAsset assetWithURL:self.assetURL];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:self.asset];
    generator.appliesPreferredTrackTransform = YES;

    CMTime time = CMTimeMakeWithSeconds(0.0, 600);

    NSError *error = nil;

    CMTime actualTime;

    CGImageRef image = [generator copyCGImageAtTime:time actualTime:&actualTime error:&error];

    UIImage *shotImage = [[UIImage alloc] initWithCGImage:image];
    if (range.location == NSNotFound) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *imageData = UIImagePNGRepresentation(shotImage);
            [imageData writeToFile:imagePath atomically:YES];
        });
    }

    CGImageRelease(image);
    return shotImage;
}

- (void)setFirstFrameThumbnail:(nullable UIImage *)image {
    [self.transport setThumbnailImage:image];
}

- (void)resetSightPlayer {
    [self resetSightPlayer:YES];
}

- (void)resetSightPlayer:(BOOL)inactivateAudioSession {
    self.canceling = YES;
    [self.transport.centerPlayBtn setImage:RCResourceImage(@"play_btn_normal") forState:UIControlStateNormal];
    [self.errorTipsLabel removeFromSuperview];
    if (!self.isPlaying) {
        return;
    }
    [self.player seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    self.player.rate = 0;
    self.isPlaying = NO;
    [self.transport setControlBarHidden:YES];
    [self.transport playbackComplete];
    if (inactivateAudioSession) {
        [self setAudioSessionUnActive];
    }
}

- (void)resetPlayer{
    [_player removeObserver:self forKeyPath:RATE_KEYPATH];
    _player = nil;
}

#pragma mark - helper
- (void)showDowndLoadFailedControl {
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self.transport stopIndicatorViewAnimating];
        [self.transport.centerPlayBtn setImage:RCResourceImage(@"sight_download_failed")
                                      forState:UIControlStateNormal];
        self.transport.centerPlayBtn.hidden = NO;
        self.transport.centerPlayBtn.selected = NO;
        CGPoint playBtnCenter = self.transport.centerPlayBtn.center;
        self.errorTipsLabel.center =
            CGPointMake(playBtnCenter.x, CGRectGetMaxY(self.transport.centerPlayBtn.frame) + 16);
        [self.view addSubview:self.errorTipsLabel];
    });
}

- (void)setAudioSessionUnActive {
    [[AVAudioSession sharedInstance] setActive:NO
                                   withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                                         error:nil];
}
#pragma mark - Properties

- (UILabel *)errorTipsLabel {
    if (!_errorTipsLabel) {
        _errorTipsLabel = [[UILabel alloc] init];
        _errorTipsLabel.font = [UIFont systemFontOfSize:14];
        _errorTipsLabel.textColor = [UIColor whiteColor];
        _errorTipsLabel.backgroundColor =
            [UIColor colorWithPatternImage:RCResourceImage(@"sight_label_shadow")];
        NSString *text = RCLocalizedString(@"downloadFailedClickToDownload");
        CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName : _errorTipsLabel.font}];
        _errorTipsLabel.textAlignment = NSTextAlignmentCenter;
        _errorTipsLabel.text = text;
        _errorTipsLabel.frame = CGRectMake(0, 0, textSize.width, textSize.height);
    }
    return _errorTipsLabel;
}

- (RCSightProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[RCSightProgressView alloc] initWithFrame:CGRectMake(0, 0, 63, 63)];
        CGRect bounds = [UIScreen mainScreen].bounds;
        _progressView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    }
    return _progressView;
}
- (void)setLoadingCenter:(CGPoint)center {
    self.progressView.center = center;
}
- (AVAsset *)asset {
    if (!_asset) {
        _asset = [AVAsset assetWithURL:self.rcSightURL];
    }
    return _asset;
}

- (AVPlayerItem *)playerItem {
    if (!_playerItem) {

        NSArray *keys =
            @[ @"tracks", @"duration", @"commonMetadata", @"availableMediaCharacteristicsWithMediaSelectionOptions" ];
        _playerItem = [[AVPlayerItem alloc] initWithAsset:self.asset automaticallyLoadedAssetKeys:keys];
    }
    return _playerItem;
}

- (AVPlayer *)player {
    if (!_player) {
        _player = [AVPlayer playerWithPlayerItem:self.playerItem];
        [_player addObserver:self
                  forKeyPath:RATE_KEYPATH
                     options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                     context:nil];
    }
    return _player;
}

- (RCSightPlayerView *)playerView {
    if (!_playerView) {
        _playerView = [[RCSightPlayerView alloc] init];
    }
    return _playerView;
}

- (id<RCSightPlayerTransport, RCSightPlayerOverlay>)transport {
    return self.playerView.transport;
}

- (void)prepareWithBlock:(void (^)(void))completion error:(void (^)(NSError *error))error {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.completion = completion;
    self.error = error;
    if (!self.isAddStatusObserver) {
        [self.playerItem addObserver:self
                          forKeyPath:STATUS_KEYPATH
                             options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                             context:nil];
        self.isAddStatusObserver = YES;
    }
    

    [self.playerView setPlayer:self.player];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:RATE_KEYPATH] && [keyPath isEqualToString:STATUS_KEYPATH]) {
        return;
    }
    
    long oldValue = [[change objectForKey:NSKeyValueChangeOldKey] longValue];
    long newValue = [[change objectForKey:NSKeyValueChangeNewKey] longValue];
    if (oldValue == newValue) {
        return;
    }
    
    if ([keyPath isEqualToString:RATE_KEYPATH]){
        [self playerDidChangeRate];
        return;
    }
    
    if ([keyPath isEqualToString:STATUS_KEYPATH]) {
        [self playerItemDidChangeStatus];
        return;
    }
}

- (void)playerDidChangeRate{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isPlaying) {
            return;
        }
        // rate = 0 ,表示视频播放被打断
        if (self.player.rate == 0) {
            [self.player pause];
            [self makePlayButtonAppear];
            [self setAudioSessionUnActive];
        } else {
            self.transport.centerPlayBtn.hidden = YES;
            self.transport.playBtn.selected = YES;
        }
    });
}

- (void)playerItemDidChangeStatus{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isAddStatusObserver) {
            [self.playerItem removeObserver:self forKeyPath:STATUS_KEYPATH];
            self.isAddStatusObserver = NO;
        }
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {

            // Set up time observers.
            [self addPlayerItemTimeObserver];
            [self addItemEndObserverForPlayerItem];

            CMTime duration = self.playerItem.duration;

            // Synchronize the time display
            [self.transport setCurrentTime:CMTimeGetSeconds(kCMTimeZero) duration:CMTimeGetSeconds(duration)];

            __weak typeof(self) weakSelf = self;
            [self.player seekToTime:kCMTimeZero
                    toleranceBefore:kCMTimeZero
                     toleranceAfter:kCMTimeZero
                  completionHandler:^(BOOL finished) {
                      [weakSelf.transport readyToPlay];
                      [weakSelf.transport willPlay];
                      if (weakSelf.completion) {
                          weakSelf.completion();
                      }
                  }];

            [self loadMediaOptions];

        } else {
            NSLog(@"Failed to load video %@", self.playerItem.error);
            if (self.error) {
                self.error(self.player.error);
            }
        }
    });
}

- (void)loadMediaOptions {
    NSString *mc = AVMediaCharacteristicLegible;
    AVMediaSelectionGroup *group = [self.asset mediaSelectionGroupForMediaCharacteristic:mc];
    if (group) {
        NSMutableArray *subtitles = [NSMutableArray array];
        for (AVMediaSelectionOption *option in group.options) {
            [subtitles addObject:option.displayName];
        }
    }
}

- (void)subtitleSelected:(NSString *)subtitle {
    NSString *mc = AVMediaCharacteristicLegible;
    AVMediaSelectionGroup *group = [self.asset mediaSelectionGroupForMediaCharacteristic:mc];
    BOOL selected = NO;
    for (AVMediaSelectionOption *option in group.options) {
        if ([option.displayName isEqualToString:subtitle]) {
            [self.playerItem selectMediaOption:option inMediaSelectionGroup:group];
            selected = YES;
        }
    }
    if (!selected) {
        [self.playerItem selectMediaOption:nil inMediaSelectionGroup:group];
    }
}

#pragma mark - Time Observers

- (void)addPlayerItemTimeObserver {

    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        _timeObserver = nil;
    }
    // Create 0.5 second refresh interval - REFRESH_INTERVAL == 0.5
    CMTime interval = CMTimeMakeWithSeconds(REFRESH_INTERVAL, NSEC_PER_SEC);

    // Main dispatch queue
    dispatch_queue_t queue = dispatch_get_main_queue();

    // Create callback block for time observer
    __weak RCSightPlayerController *weakSelf = self;
    NSTimeInterval duration = CMTimeGetSeconds(self.player.currentItem.duration);
    void (^callback)(CMTime time) = ^(CMTime time) {
        NSTimeInterval currentTime = CMTimeGetSeconds(time);
        [weakSelf.transport setCurrentTime:currentTime duration:duration];
    };

    // Add observer and store pointer for future use
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:interval queue:queue usingBlock:callback];
}

- (void)addItemEndObserverForPlayerItem {

    NSString *name = AVPlayerItemDidPlayToEndTimeNotification;

    NSOperationQueue *queue = [NSOperationQueue mainQueue];

    __weak RCSightPlayerController *weakSelf = self;
    void (^callback)(NSNotification *note) = ^(NSNotification *notification) {
        if (weakSelf.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            [weakSelf.player seekToTime:kCMTimeZero
                        toleranceBefore:kCMTimeZero
                         toleranceAfter:kCMTimeZero
                      completionHandler:^(BOOL finished) {
                          if (weakSelf.isLoopPlayback) {
                              weakSelf.isPlaying = YES;
                              [weakSelf.player play];
                          } else {
                              [weakSelf.transport playbackComplete];
                              if ([weakSelf.delegate respondsToSelector:@selector(playToEnd)]) {
                                  [weakSelf.delegate playToEnd];
                              }
                              [weakSelf setAudioSessionUnActive];
                          }
                      }];
        }

    };

    self.itemEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:name
                                                                             object:self.playerItem
                                                                              queue:queue
                                                                         usingBlock:callback];
}

#pragma mark - RCTransportDelegate

- (void)play {
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    ///自动播放需要隐藏中心的播放按钮，因为不是用户触发的
    self.transport.centerPlayBtn.hidden = YES;
    [self.errorTipsLabel removeFromSuperview];
    [self.progressView removeFromSuperview];
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.rcSightURL.path]) {
        __weak typeof(self) weakSelf = self;
        [[RCDownloadHelper new]
         getDownloadFileToken:MediaType_SIGHT
         queryUrl:[self.rcSightURL absoluteString]
         completeBlock:^(NSString *_Nullable token, NSString *_Nullable authInfo) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.view addSubview:weakSelf.progressView];
                [weakSelf.progressView startIndeterminateAnimation];
            });
            NSMutableURLRequest *urlRequest =
            [NSMutableURLRequest requestWithURL:weakSelf.rcSightURL
                                    cachePolicy:NSURLRequestUseProtocolCachePolicy
                                timeoutInterval:30];
            [RCDownloadHelper handleRequest:urlRequest token:token authInfo:authInfo];
            if ([[RCCoreClient sharedCoreClient].downloadInterceptor respondsToSelector:@selector(onDownloadRequest:)]) {
                urlRequest = [[RCCoreClient sharedCoreClient].downloadInterceptor onDownloadRequest:urlRequest];
            }
            weakSelf.session = [NSURLSession
                                sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]
                                delegate:weakSelf
                                delegateQueue:[[NSOperationQueue alloc] init]];
            
            [weakSelf p_startRequest:urlRequest];
        }];

    } else {
        if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            [self.transport readyToPlay];
            [self.transport willPlay];
            self.isPlaying = YES;
            [self.player play];
        } else {
            __weak typeof(self) weakSelf = self;
            [self prepareWithBlock:^{
                [weakSelf.transport willPlay];
                weakSelf.isPlaying = YES;
                [weakSelf.player play];
            }
                error:^(NSError *error){

                }];
        }
    }
}

- (void)p_startRequest:(NSMutableURLRequest *)urlRequest {
    // 有异步拦截 request
    if ([[RCCoreClient sharedCoreClient].downloadInterceptor respondsToSelector:@selector(onDownloadRequest:withRequestHandler:)]) {
        [[RCCoreClient sharedCoreClient].downloadInterceptor onDownloadRequest:urlRequest withRequestHandler:^(NSMutableURLRequest * _Nonnull handledRequest) {
            NSURLSessionDownloadTask *downloadTask;
            if (handledRequest) {
                downloadTask = [self.session downloadTaskWithRequest:handledRequest];
            }else {
                // 返回空，则直接返回错误码
                RCLogE(@"[RCSightPlayerController onDownloadRequest requestHandler:] callback handledRequest nil");
                downloadTask = [self.session downloadTaskWithRequest:urlRequest];
            }
            [downloadTask resume];
        }];
        
        return;
    }
    
    // 无异步拦截 request
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:urlRequest];
    [downloadTask resume];
}

- (void)pause {
    if (!self.isPlaying) {
        return;
    }
    self.lastPlaybackRate = self.player.rate;
    [self.player pause];
    self.isPlaying = NO;
    [self setAudioSessionUnActive];
}

- (void)stop {
    [self.player setRate:0.0f];
    self.isPlaying = NO;
    [self.transport playbackComplete];
    [self setAudioSessionUnActive];
}

- (void)jumpedToTime:(NSTimeInterval)time {
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)
            toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero];
}

- (void)scrubbingDidStart {
    self.lastPlaybackRate = self.player.rate;
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        _timeObserver = nil;
    }
}

- (void)scrubbedToTime:(NSTimeInterval)time {
    if (!self.isAddStatusObserver) {
        [self prepareWithBlock:self.completion error:self.error];
    }
    [self.playerItem cancelPendingSeeks];
    [self.player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)
            toleranceBefore:kCMTimeZero
             toleranceAfter:kCMTimeZero];
}

- (void)scrubbingDidEnd {
    [self addPlayerItemTimeObserver];
    if (self.lastPlaybackRate > 0.0f) {
        self.isPlaying = YES;
    }
}

- (void)cancel {
    [RCSightExtensionModule sharedInstance].isSightPlayerHolding = NO;
    [_player setRate:0.0f];
    if ([self.delegate respondsToSelector:@selector(closeSightPlayer)]) {
        [self.delegate closeSightPlayer];
    }
    self.canceling = YES;
    [self setAudioSessionUnActive];
}

- (BOOL)prefersControlBardHidden {
    if (self.isOverlayHidden) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)prefersBottomBarHidden {
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.rcSightURL.path]) {
        return NO;
    }
    return YES;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
                 didWriteData:(int64_t)bytesWritten
            totalBytesWritten:(int64_t)totalBytesWritten
    totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    CGFloat progress = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:progress animated:YES];
    });
}

- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
    didFinishDownloadingToURL:(NSURL *)location {
    session = nil;
    NSString *cachepath = [RCUtilities rongImageCacheDirectory];
    NSString *currentUserId = [RCCoreClient sharedCoreClient].currentUserInfo.userId;
    NSString *localPath = [cachepath stringByAppendingFormat:@"/%@/RCSightCache/Sight_%@.mp4", currentUserId,
                           [RCFileUtility getFileKey:[self.rcSightURL description]]];
    self.localPath = localPath;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RCKitSightDownloadComplete" object:localPath];
    NSString *directory = [localPath stringByDeletingLastPathComponent];
    if (![[NSFileManager defaultManager] fileExistsAtPath:directory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:location.path]) {
        NSError *error;
        [[NSFileManager defaultManager] moveItemAtPath:location.path toPath:localPath error:&error];
        NSLog(@"%@", error);

        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.5];
            self.rcSightURL = [[NSURL alloc] initFileURLWithPath:localPath];
            if (!self.isAutoPlay || self.canceling) {
                if (self.canceling) {
                    self.canceling = NO;
                }
                self.transport.centerPlayBtn.hidden = NO;
                self.transport.centerPlayBtn.selected = NO;
                [self.transport setControlBarHidden:YES];
                return;
            }
            if([RCCoreClient sharedCoreClient].sdkRunningMode == RCSDKRunningMode_Background) {
                [self makePlayButtonAppear];
                return;
            }
            [self prepareWithBlock:^{
                weakSelf.isPlaying = YES;
                [weakSelf.player play];
            }
                error:^(NSError *error){
                }];
        });
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [session finishTasksAndInvalidate];
    
    //下载失败则把缓存数据清除
    if (error) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.localPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:self.localPath error:nil];
        }
    }
    if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)task.response;
        NSInteger responseCode = [httpURLResponse statusCode];
        if(responseCode == 403 || responseCode == 404) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressView stopIndeterminateAnimation];
                [self.progressView removeFromSuperview];
                CGPoint playBtnCenter = self.transport.centerPlayBtn.center;
                self.errorTipsLabel.center =
                    CGPointMake(playBtnCenter.x, CGRectGetMaxY(self.transport.centerPlayBtn.frame) + 16);
                self.errorTipsLabel.text = NSLocalizedStringFromTable(@"VideoExpired", @"RongCloudKit", nil);
                [self.view addSubview:self.errorTipsLabel];
                self.transport.centerPlayBtn.hidden = YES;
            });
            if ([[NSFileManager defaultManager] fileExistsAtPath:self.localPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:self.localPath error:nil];
            }
            RCLogE(@"download sight error , reason : RC_FILE_EXPIRED ");
            return;
        }
    }
    
    
    if (error) {
        sleep(2);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressView stopIndeterminateAnimation];
            [self.progressView removeFromSuperview];
            [self showDowndLoadFailedControl];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.transport.centerPlayBtn setImage:RCResourceImage(@"play_btn_normal")
                                          forState:UIControlStateNormal];
        });
    }
}

#pragma mark - Notification Selector
- (void)registerNotificationCenter {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self
                      selector:@selector(appWillEnterBackground)
                          name:UIApplicationDidEnterBackgroundNotification
                        object:nil];
    [defaultCenter addObserver:self
                      selector:@selector(appWillEnterBackground)
                          name:@"RCCallNewSessionCreation Notification"
                        object:nil];
    
    [defaultCenter addObserver:self
                      selector:@selector(deviceOrientationDidChange:)
                          name:UIApplicationDidChangeStatusBarFrameNotification
                        object:nil];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    UIDeviceOrientation interfaceOrientation = [UIDevice currentDevice].orientation;
    if (interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight || interfaceOrientation == UIDeviceOrientationPortrait){
        CGRect bounds = [UIScreen mainScreen].bounds;
        self.progressView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
        self.errorTipsLabel.center =
            CGPointMake(self.progressView.center.x, self.progressView.center.y + 47);
    }
}

- (void)appWillEnterBackground {
    if (self.isPlaying) {
        [self.player pause];
        [self makePlayButtonAppear];
        [self setAudioSessionUnActive];
    }
}
//显示播放按钮
- (void)makePlayButtonAppear {
    self.isPlaying = NO;
    self.transport.centerPlayBtn.hidden = NO;
    self.transport.centerPlayBtn.selected = NO;
    self.transport.playBtn.selected = NO;
}
@end
