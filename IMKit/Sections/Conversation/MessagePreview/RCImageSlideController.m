//
//  RCImageSlideController.m
//  RongIMKit
//
//  Created by liulin on 16/5/18.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCImageSlideController.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCMessageModel.h"
#import "RCloudImageLoader.h"
#import "RCloudImageView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "RCIM.h"
#import "RCAlertView.h"
#import "RCActionSheetView.h"
@interface RCImageSlideController () <UIScrollViewDelegate, RCloudImageViewDelegate>
// scrollView
@property (nonatomic, strong) UIScrollView *scrollView;
//当前图片消息的数据模型
@property (nonatomic, strong) NSMutableArray<RCMessageModel *> *imageArray;
//当前图片消息的index
@property (nonatomic, assign) NSInteger currentIndex;
//当前图片的View
@property (nonatomic, strong) RCloudImageView *currentImageView;
//滑动时的offset
@property (nonatomic, assign) CGFloat newContentOffsetX;
@property (nonatomic, assign) CGFloat offsettest;
@property (nonatomic, assign) CGFloat ContentOffset;
@property (nonatomic, assign) NSInteger preSelectIndex;
//图片列表
@property (nonatomic, strong) NSMutableArray<RCloudImageView *> *imageViewList;
@property (nonatomic, strong) NSMutableArray<RCImageMessage *> *imagemessageList;
@property (nonatomic, strong) NSMutableDictionary *imageProgressList;

@end

@implementation RCImageSlideController {
    BOOL _statusBarHidden;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.imageProgressList = [NSMutableDictionary new];
    //取当前界面中一定数量的图片
    [self getMessageFromModel:self.messageModel];
    self.scrollView = [[UIScrollView alloc]
        initWithFrame:CGRectMake(0, 0, (self.view.bounds.size.width + 20), self.view.bounds.size.height)];
    [self.scrollView setBackgroundColor:[UIColor blackColor]];
    [self.scrollView setDelegate:self];
    [self.scrollView setPagingEnabled:YES];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setShowsVerticalScrollIndicator:NO];
    [self.scrollView setContentSize:CGSizeMake([self.imageArray count] * (self.view.bounds.size.width + 20), 0)];
    if ([RCKitUtility isRTL]) {
        [self.scrollView setTransform:CGAffineTransformMakeScale(-1, 1)];
    }

    //长按可选择是否保存图片
    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];

    self.imageViewList = [NSMutableArray new];
    self.imagemessageList = [NSMutableArray new];
    self.currentImageView = [RCloudImageView new];

    //添加图片到scroll子视图
    [self refreshimage:self.imageArray];
    [self refreshScrollView:self.imageViewList];

    self.ContentOffset = 0;
    self.offsettest = 0.0;
    self.scrollView.contentOffset = CGPointMake(self.currentIndex * (self.view.bounds.size.width + 20), 0);
    self.ContentOffset = self.currentIndex * (self.view.bounds.size.width + 20);
    self.automaticallyAdjustsScrollViewInsets = NO;
    if (self.imageViewList.count > self.currentIndex) {
        self.currentImageView = self.imageViewList[self.currentIndex];
    }

    [self.view addSubview:self.scrollView];
    [self.view addGestureRecognizer:longPress];
    [self performSelector:@selector(setStatusBarHidden:) withObject:@(YES) afterDelay:0.4];
    [self registerNotificationCenter];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    return _statusBarHidden;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIScrollViewDelegate

// scrollView 开始拖动
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.newContentOffsetX = self.scrollView.contentOffset.x;
    if (self.scrollView != scrollView) {
        return;
    }

    if (self.newContentOffsetX < self.ContentOffset && self.currentIndex <= (self.imageViewList.count - 1)) {
        self.currentImageView = self.imageViewList[self.currentIndex];
    }

    if (self.currentIndex >= self.imagemessageList.count)
        return;
    if (self.currentIndex >= self.imageViewList.count)
        return;

    self.currentIndex = scrollView.contentOffset.x / (self.view.bounds.size.width + 20);

    RCImageMessage *cImageMessage = self.imagemessageList[self.currentIndex];
    RCloudImageView *cImageView = self.imageViewList[self.currentIndex];
    cImageView.delegate = self;
    for (int i = 0; i < self.imageViewList.count; i++) {
        if (i != self.currentIndex) {
            RCloudImageView *cImageView = self.imageViewList[i];
            cImageView.originalImageData = nil;
        }
    }
    if (cImageMessage.localPath.length > 0 &&
        [[NSFileManager defaultManager] fileExistsAtPath:[RCUtilities getCorrectedFilePath:cImageMessage.localPath]]) {
        cImageView.PlaceholderImage = cImageMessage.thumbnailImage;
        [cImageView setImageURL:[NSURL URLWithString:[RCUtilities getCorrectedFilePath:cImageMessage.localPath]]];
        [self resizeSubviews:cImageView];
    } else {

        if ([cImageMessage.imageUrl hasPrefix:@"http"]) {
            //判断当前图片是否已记载大图，如果已加载，跳过；如果没有，加载
            if ([[RCloudImageLoader sharedImageLoader]
                    hasLoadedImageURL:[NSURL URLWithString:cImageMessage.imageUrl]]) {
                [cImageView setImageURL:[NSURL URLWithString:cImageMessage.imageUrl]];
                [self resizeSubviews:cImageView];
            } else {
                cImageView.delegate = self;
                cImageView.PlaceholderImage = cImageMessage.thumbnailImage;
                [cImageView setImageURL:[NSURL URLWithString:cImageMessage.imageUrl]];
                [self resizeSubviews:cImageView];
            }
        } else {
            cImageView.PlaceholderImage = cImageMessage.thumbnailImage;
            [cImageView setImageURL:[NSURL URLWithString:cImageMessage.imageUrl]];
            [self resizeSubviews:cImageView];
        }
        if (self.preSelectIndex != self.currentIndex) {
            [self refreshScrollView:self.imageViewList];
            self.preSelectIndex = self.currentIndex;
        }
    }
    //当左滑到第二张图片，或快速滑动到第一张图片时，获取更多的历史数据中的图片消息
    if (self.newContentOffsetX < self.ContentOffset && (self.currentIndex == 0 || self.currentIndex == 1)) {
        NSArray *imageMessageForward = nil;
        if (!self.onlyPreviewCurrentMessage) {
            imageMessageForward = [self getOlderMessagesThanModel:self.imageArray[0] count:5 times:0];
        }

        //判断是否已经没有图片可取了
        if ([imageMessageForward count] > 0) {
            NSMutableArray *imageArr = [[NSMutableArray alloc] init];
            for (NSInteger j = [imageMessageForward count] - 1; j >= 0; j--) {
                RCMessage *rcMsg = [imageMessageForward objectAtIndex:j];
                if (rcMsg.content) {
                    RCMessageModel *modelindex = [RCMessageModel modelWithMessage:rcMsg];
                    [imageArr addObject:modelindex];
                }
            }
            NSMutableArray *imageList;
            NSMutableArray *msgList;
            if (self.currentIndex == 0) {
                imageList = [[NSMutableArray alloc] initWithObjects:self.imageViewList[0], self.imageViewList[1], nil];
                msgList =
                    [[NSMutableArray alloc] initWithObjects:self.imagemessageList[0], self.imagemessageList[1], nil];
            } else {
                imageList = [[NSMutableArray alloc]
                    initWithObjects:self.imageViewList[0], self.imageViewList[1], self.imageViewList[2], nil];
                msgList = [[NSMutableArray alloc]
                    initWithObjects:self.imagemessageList[0], self.imagemessageList[1], self.imagemessageList[2], nil];
            }
            //把拉取到的图片放进数组里
            [self refreshimage:imageArr];
            //把当前图片列表中的前三张加进新的列表中，确保从当前第二张往前往后滑动时都可以正常进行
            for (int i = 0; i < [imageList count]; i++) {
                [self.imageViewList addObject:[imageList objectAtIndex:i]];
                [self.imagemessageList addObject:[msgList objectAtIndex:i]];
            }
            //添加到scrollView
            [self refreshScrollView:self.imageViewList];
            //刷新self.imageArray
            [imageArr addObject:self.imageArray[0]];
            [imageArr addObject:self.imageArray[1]];
            if (self.currentIndex == 1) {
                [imageArr addObject:self.imageArray[2]];
            }
            [self.imageArray removeAllObjects];
            for (int i = 0; i < imageArr.count; i++) {
                [self.imageArray addObject:imageArr[i]];
            }
            //设置ContentSize
            [self.scrollView setContentSize:CGSizeMake([imageArr count] * (self.view.bounds.size.width + 20), 0)];
            //更新当前图片的索引和坐标
            self.currentIndex = [imageArr count] - 2;
            self.preSelectIndex = self.currentIndex;
            [scrollView setContentOffset:CGPointMake(self.newContentOffsetX +
                                                         imageMessageForward.count * (self.view.bounds.size.width + 20),
                                                     0)];
            if (self.currentIndex <= (self.imageViewList.count - 1)) {
                self.currentImageView = self.imageViewList[self.currentIndex];
            }
        }
    } else if (self.newContentOffsetX > self.ContentOffset &&
               (self.currentIndex == self.imageArray.count - 1 || self.currentIndex == self.imageArray.count - 2)) {
        NSArray *imageMessagebackward = nil;
        if (!self.onlyPreviewCurrentMessage) {
            //当右滑到倒数第二张图片或快速滑动到最后一张图片时，获取更多的历史数据中的图片消息
            imageMessagebackward =
                [self getLaterMessagesThanModel:self.imageArray[self.imageArray.count - 1] count:5 times:0];
        }
        //判断是否已经没有图片可取了
        if ([imageMessagebackward count] > 0) {
            NSMutableArray *imageArr = [[NSMutableArray alloc] init];

            for (int i = 0; i < [imageMessagebackward count]; i++) {
                RCMessage *rcMsg = [imageMessagebackward objectAtIndex:i];
                if (rcMsg.content) {
                    RCMessageModel *modelindex = [RCMessageModel modelWithMessage:rcMsg];
                    [imageArr addObject:modelindex];
                }
            }
            //如果当前图片多于两张，把当前图片列表中的最后三张加进新的列表中，确保从当前倒数第二张往前往后滑动时都可以正常进行；如果当前图片只有两张，全部加进新的列表中。
            NSMutableArray *imageList;
            NSMutableArray *msgList;
            if (self.currentIndex == self.imageArray.count - 2 && self.imageArray.count > 2) {
                imageList =
                    [[NSMutableArray alloc] initWithObjects:self.imageViewList[self.imageViewList.count - 3],
                                                            self.imageViewList[self.imageViewList.count - 2],
                                                            self.imageViewList[self.imageViewList.count - 1], nil];
                msgList = [[NSMutableArray alloc]
                    initWithObjects:self.imagemessageList[self.imagemessageList.count - 3],
                                    self.imagemessageList[self.imagemessageList.count - 2],
                                    self.imagemessageList[self.imagemessageList.count - 1], nil];
            } else {
                imageList =
                    [[NSMutableArray alloc] initWithObjects:self.imageViewList[self.imageViewList.count - 2],
                                                            self.imageViewList[self.imageViewList.count - 1], nil];
                msgList = [[NSMutableArray alloc]
                    initWithObjects:self.imagemessageList[self.imagemessageList.count - 2],
                                    self.imagemessageList[self.imagemessageList.count - 1], nil];
            }
            //把拉取到的图片放进数组里
            [self refreshimage:imageArr];
            for (NSInteger i = imageList.count - 1; i >= 0; i--) {
                [self.imageViewList insertObject:[imageList objectAtIndex:i] atIndex:0];
                [self.imagemessageList insertObject:[msgList objectAtIndex:i] atIndex:0];
            }
            //添加到scrollView
            [self refreshScrollView:self.imageViewList];
            //刷新self.imageArray
            [imageArr insertObject:self.imageArray[self.imageArray.count - 1] atIndex:0];
            [imageArr insertObject:self.imageArray[self.imageArray.count - 2] atIndex:0];
            if (self.currentIndex == self.imageArray.count - 2 && self.imageArray.count > 2) {
                [imageArr insertObject:self.imageArray[self.imageArray.count - 3] atIndex:0];
            }
            [self.imageArray removeAllObjects];
            for (int i = 0; i < imageArr.count; i++) {
                [self.imageArray addObject:imageArr[i]];
            }
            //设置ContentSize
            [self.scrollView setContentSize:CGSizeMake([imageArr count] * (self.view.bounds.size.width + 20), 0)];

            self.currentIndex = 1;
            self.preSelectIndex = self.currentIndex;
            if (self.currentIndex <= (self.imageViewList.count - 1)) {
                self.currentImageView = self.imageViewList[self.currentIndex];
            }
            [self.scrollView setContentOffset:CGPointMake((self.view.bounds.size.width + 20), 0)];
            self.currentImageView = self.imageViewList[self.currentIndex];
            //                  }
        }
    }

    self.ContentOffset = self.newContentOffsetX;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if ([scrollView.subviews count] > 0) {
        return scrollView.subviews[0];
    } else {
        return nil;
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setImageCenter:scrollView];
}

#pragma mark -  RCloudImageViewDelegate

- (void)imageViewLoadedImage:(RCloudImageView *)imageView {
    //图片加载成功后，去掉加载中的标识
    RCImageMessageProgressView *imageProressView = self.imageProgressList[imageView.imageURL.absoluteString];
    if (imageProressView) {
        [imageProressView stopAnimating];
        [imageProressView setHidden:YES];
    }
    [self resizeSubviews:imageView];
    UIScrollView *superView = (UIScrollView *)imageView.superview;
    [superView setContentSize:CGSizeMake(imageView.frame.size.width, imageView.frame.size.height)];
}

- (void)imageViewFailedToLoadImage:(RCloudImageView *)imageView error:(NSError *)error {
    [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(action:) userInfo:imageView repeats:NO];
}

#pragma mark - Notification
- (void)registerNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveRecallMessageNotification:)
                                                 name:RCKitDispatchRecallMessageNotification
                                               object:nil];
}

- (void)didReceiveRecallMessageNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        long recalledMsgId = [notification.object longValue];
        RCMessageModel *currentModel = self.imageArray[self.currentIndex];
        //产品需求：当前正在查看的图片被撤回，dismiss 预览页面，否则不做处理
        if (recalledMsgId == currentModel.messageId) {
            UIAlertController *alertController = [UIAlertController
                alertControllerWithTitle:nil
                                 message:RCLocalizedString(@"MessageRecallAlert")
                          preferredStyle:UIAlertControllerStyleAlert];
            [alertController
                addAction:[UIAlertAction actionWithTitle:RCLocalizedString(@"Confirm")
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                     [self.navigationController dismissViewControllerAnimated:YES
                                                                                                   completion:nil];
                                                 }]];
            [self.navigationController presentViewController:alertController animated:YES completion:nil];
        }
    });
}

#pragma mark - Target Action
- (void)singleTap:(UITapGestureRecognizer *)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)doubleTap:(UITapGestureRecognizer *)sender {
    UIScrollView *subview = self.scrollView.subviews[self.currentIndex];
    if (subview.contentSize.width > self.view.frame.size.width) {
        [subview setZoomScale:1.0 animated:YES];
    } else {
        CGPoint touchPoint = [sender locationInView:subview];
        CGFloat newZoomScale = subview.maximumZoomScale;
        CGFloat xsize = self.view.frame.size.width / newZoomScale;
        CGFloat ysize = self.view.frame.size.height / newZoomScale;
        [subview zoomToRect:CGRectMake(touchPoint.x - xsize / 2, touchPoint.y - ysize / 2, xsize, ysize) animated:YES];
    }
}

- (void)longPressed:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        [RCActionSheetView showActionSheetView:nil cellArray:@[RCLocalizedString(@"Save")] cancelTitle:RCLocalizedString(@"Cancel") selectedBlock:^(NSInteger index) {
            [self saveImage];
        } cancelBlock:^{
                
        }];
    }
}

#pragma mark - Private Methods
////取当前界面中一定数量的图片
- (void)getMessageFromModel:(RCMessageModel *)model {
    if (!model) {
        NSLog(@"Parameters are not allowed to be nil");
        return;
    }
    NSMutableArray *ImageArr = [[NSMutableArray alloc] init];
    if (self.onlyPreviewCurrentMessage) {
        [ImageArr addObject:model];
    } else {
        NSArray *imageArrayForward = [self getOlderMessagesThanModel:model count:5 times:0];
        NSArray *imageArrayBackward = [self getLaterMessagesThanModel:model count:5 times:0];
        for (NSInteger j = [imageArrayForward count] - 1; j >= 0; j--) {
            RCMessage *rcMsg = [imageArrayForward objectAtIndex:j];
            if (rcMsg.content) {
                RCMessageModel *modelindex = [RCMessageModel modelWithMessage:rcMsg];
                [ImageArr addObject:modelindex];
            }
        }
        [ImageArr addObject:model];
        for (int i = 0; i < [imageArrayBackward count]; i++) {
            RCMessage *rcMsg = [imageArrayBackward objectAtIndex:i];
            if (rcMsg.content) {
                RCMessageModel *modelindex = [RCMessageModel modelWithMessage:rcMsg];
                [ImageArr addObject:modelindex];
            }
        }
    }

    self.imageArray = ImageArr;
    for (int i = 0; i < ImageArr.count; i++) {
        RCMessageModel *modelindex1 = [ImageArr objectAtIndex:i];
        if (model.messageId == modelindex1.messageId) {
            self.currentIndex = i;
            self.preSelectIndex = self.currentIndex;
        }
    }
}

- (NSArray<RCMessageModel *> *)getLaterMessagesThanModel:(RCMessageModel *)model
                                                   count:(NSInteger)count
                                                   times:(int)times {
    NSArray<RCMessageModel *> *imageArrayBackward =
        [[RCIMClient sharedRCIMClient] getHistoryMessages:model.conversationType
                                                 targetId:model.targetId
                                               objectName:[RCImageMessage getObjectName]
                                            baseMessageId:model.messageId
                                                isForward:false
                                                    count:(int)count];
    NSArray *messages = [self filterDestructImageMessage:imageArrayBackward];
    if (times < 2 && messages.count == 0 && imageArrayBackward.count == count) {
        messages = [self getLaterMessagesThanModel:imageArrayBackward.lastObject count:count times:times + 1];
    }
    return messages;
}

- (NSArray<RCMessageModel *> *)getOlderMessagesThanModel:(RCMessageModel *)model
                                                   count:(NSInteger)count
                                                   times:(int)times {
    NSArray<RCMessageModel *> *imageArrayForward =
        [[RCIMClient sharedRCIMClient] getHistoryMessages:model.conversationType
                                                 targetId:model.targetId
                                               objectName:[RCImageMessage getObjectName]
                                            baseMessageId:model.messageId
                                                isForward:true
                                                    count:(int)count];
    NSArray *messages = [self filterDestructImageMessage:imageArrayForward];
    if (times < 2 && imageArrayForward.count == count && messages.count == 0) {
        messages = [self getOlderMessagesThanModel:imageArrayForward.lastObject count:count times:times + 1];
    }
    return messages;
}

//过滤阅后即焚图片消息
- (NSArray *)filterDestructImageMessage:(NSArray *)array {
    NSMutableArray *backwardMessages = [NSMutableArray array];
    for (RCMessageModel *model in array) {
        if (!(model.content.destructDuration > 0)) {
            [backwardMessages addObject:model];
        }
    }
    return backwardMessages.copy;
}

- (void)showAlertController:(NSString *)title message:(NSString *)message cancelTitle:(NSString *)cancelTitle {
    [RCAlertView showAlertController:title message:message cancelTitle:cancelTitle inViewController:self];
}

- (void)saveImage {
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status == ALAuthorizationStatusRestricted || status == ALAuthorizationStatusDenied) {
        [self showAlertController:RCLocalizedString(@"AccessRightTitle")
                          message:RCLocalizedString(@"photoAccessRight")
                      cancelTitle:RCLocalizedString(@"OK")];
        return;
    }
    RCImageMessage *cImageMessage = self.imagemessageList[self.currentIndex];
    RCloudImageView *cImageView = self.imageViewList[self.currentIndex];
    NSData *imageData;
    if (cImageMessage.localPath.length > 0 &&
        [[NSFileManager defaultManager] fileExistsAtPath:[RCUtilities getCorrectedFilePath:cImageMessage.localPath]]) {
        NSString *path = [RCUtilities getCorrectedFilePath:cImageMessage.localPath];
        imageData = [[NSData alloc] initWithContentsOfFile:path];
    } else {
        [cImageView setImageURL:[NSURL URLWithString:cImageMessage.imageUrl]];
        imageData = cImageView.originalImageData;
    }
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    [assetsLibrary
        writeImageDataToSavedPhotosAlbum:imageData
                                metadata:nil
                         completionBlock:^(NSURL *assetURL, NSError *error) {
                             if (error != NULL) {
                                 //失败
                                 DebugLog(@" save image fail");
                                 [self showAlertController:nil
                                                   message:RCLocalizedString(@"SavePhotoFailed")
                                               cancelTitle:RCLocalizedString(@"OK")];
                             } else {
                                 //成功
                                 DebugLog(@"save image succeed");
                                 [self showAlertController:nil
                                                   message:RCLocalizedString(@"SavePhotoSuccess")
                                               cancelTitle:RCLocalizedString(@"OK")];
                             }

                         }];
}

//调整图片大小
- (void)resizeSubviews:(RCloudImageView *)ImageView {
    ImageView.contentMode = UIViewContentModeScaleAspectFit;
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    UIImage *image = ImageView.image;
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    if (imageWidth < width) {
        /*
         图宽＜屏幕宽，高＜屏幕高 宽适配屏幕宽，高不变，水平垂直居中屏幕展示
         图宽＜屏幕宽，高≥屏幕高 宽不变，高不变，水平居中，垂直方向从图片顶端开始展示
         */
        if (imageHeight < height) {
            CGFloat scale = imageHeight / imageWidth;
            imageWidth = width;
            imageHeight = width * scale;
            [ImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
            ImageView.center = self.view.center;
        } else {
            [ImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
            ImageView.center = CGPointMake(width / 2, imageHeight / 2);
        }
    } else {
        /*
         图宽大于等于屏幕宽 宽适配屏幕宽，高等比放大或缩小  放大或缩小后的高＜屏幕高，垂直居中屏幕显示
         放大或缩小后的高≥屏幕高，垂直方向从图片顶端开始展示
         */
        CGFloat scale = imageHeight / imageWidth;
        imageWidth = width;
        imageHeight = width * scale;
        [ImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
        if (imageHeight < height) {
            ImageView.center = self.view.center;
        }
    }
}

- (void)resetProgressViewFrame:(RCloudImageView *)imageView {
    if (imageView.subviews.count > 0) {
        for (UIView *subView in imageView.subviews) {
            if ([subView isKindOfClass:[RCImageMessageProgressView class]] && subView.hidden == NO) {
                if (CGPointEqualToPoint(imageView.center, self.view.center)) {
                    [subView setCenter:CGPointMake(imageView.frame.size.width / 2, imageView.frame.size.height / 2)];
                } else {
                    [subView setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2)];
                }
                break;
            }
        }
    }
}

- (void)refreshimage:(NSMutableArray *)imagearray {
    [self.imageViewList removeAllObjects];
    [self.imagemessageList removeAllObjects];

    for (int i = 0; i < imagearray.count; i++) {
        RCMessageModel *model = imagearray[i];
        RCImageMessage *imageMessage = (RCImageMessage *)model.content;
        if (imageMessage) {
            [self.imagemessageList addObject:imageMessage];
            RCloudImageView *imageView = [[RCloudImageView alloc] init];
            imageView.delegate = self;
            //判断图片路径

            if (imageMessage.localPath.length > 0 &&
                [[NSFileManager defaultManager]
                    fileExistsAtPath:[RCUtilities getCorrectedFilePath:imageMessage.localPath]]) {
                imageView.PlaceholderImage = imageMessage.thumbnailImage;
                [imageView setImageURL:[NSURL URLWithString:[RCUtilities getCorrectedFilePath:imageMessage.localPath]]];
            } else {

                if ([imageMessage.imageUrl hasPrefix:@"http"]) {
                    RCImageMessageProgressView *imageProressView =
                        [[RCImageMessageProgressView alloc] initWithFrame:CGRectMake(0, 0, 135, 135)];
                    imageProressView.label.hidden = YES;
                    imageProressView.indicatorView.color = [UIColor blackColor];
                    imageProressView.backgroundColor = [UIColor clearColor];
                    [imageProressView
                        setCenter:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)];
                    [imageView addSubview:imageProressView];
                    if (imageMessage.imageUrl) {
                        [self.imageProgressList setObject:imageProressView forKey:imageMessage.imageUrl];
                    }
                    //判断是否已加载
                    if ([[RCloudImageLoader sharedImageLoader]
                            hasLoadedImageURL:[NSURL URLWithString:imageMessage.imageUrl]]) {
                        [imageView setImageURL:[NSURL URLWithString:imageMessage.imageUrl]];
                    } else {
                        imageView.delegate = self;
                        imageView.PlaceholderImage = imageMessage.thumbnailImage;
                        [imageProressView startAnimating];
                    }
                } else {
                    imageView.PlaceholderImage = imageMessage.thumbnailImage;
                    [imageView setImageURL:[NSURL URLWithString:imageMessage.imageUrl]];
                }
            }

            imageView.tag = i + 1;
            [self resizeSubviews:imageView];
            [self resetProgressViewFrame:imageView];
            [self.imageViewList addObject:imageView];
        }
    }
}

- (void)refreshScrollView:(NSMutableArray *)imageViewList {

    while (self.scrollView.subviews.count > 0) {
        [self.scrollView.subviews[0] removeFromSuperview];
    }

    for (int i = 0; i < imageViewList.count; i++) {
        // scrollView
        UIScrollView *imagesrcoll;
        if (i == imageViewList.count - 1) {
            imagesrcoll = [[UIScrollView alloc]
                initWithFrame:CGRectMake(i * (self.view.bounds.size.width + 20), 0, self.view.frame.size.width,
                                         self.view.frame.size.height)];
        } else {
            imagesrcoll = [[UIScrollView alloc]
                initWithFrame:CGRectMake(i * (self.view.bounds.size.width + 20), 0, (self.view.bounds.size.width + 20),
                                         self.view.frame.size.height)];
        }
        [imagesrcoll setContentSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height)];

        imagesrcoll.delegate = self;

        UIImageView *imageView = imageViewList[i];
        RCloudImageView *newImageView = [[RCloudImageView alloc]
            initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        newImageView.contentMode = UIViewContentModeScaleAspectFit;
        newImageView.PlaceholderImage = self.imagemessageList[i].thumbnailImage;
        newImageView.delegate = self;
        NSString *imageLocalPath = self.imagemessageList[i].localPath;
        if (imageLocalPath.length > 0 &&
            [[NSFileManager defaultManager] fileExistsAtPath:[RCUtilities getCorrectedFilePath:imageLocalPath]]) {
            newImageView.PlaceholderImage = self.imagemessageList[i].thumbnailImage;
            [newImageView setImageURL:[NSURL URLWithString:[RCUtilities getCorrectedFilePath:imageLocalPath]]];
            //      [self resizeSubviews:newImageView];
        } else {

            if ([self.imagemessageList[i].imageUrl hasPrefix:@"http"]) {
                RCImageMessageProgressView *imageProressView =
                    [[RCImageMessageProgressView alloc] initWithFrame:CGRectMake(0, 0, 135, 135)];
                imageProressView.label.hidden = YES;
                imageProressView.indicatorView.color = [UIColor blackColor];
                imageProressView.backgroundColor = [UIColor clearColor];
                [imageProressView
                    setCenter:CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2)];
                if (self.imagemessageList[i].imageUrl) {
                    [self.imageProgressList setObject:imageProressView forKey:self.imagemessageList[i].imageUrl];
                }

                [newImageView addSubview:imageProressView];
                //判断是否已加载
                if ([[RCloudImageLoader sharedImageLoader]
                        hasLoadedImageURL:[NSURL URLWithString:self.imagemessageList[i].imageUrl]]) {
                    [newImageView setImageURL:[NSURL URLWithString:self.imagemessageList[i].imageUrl]];

                } else {
                    newImageView.PlaceholderImage = self.imagemessageList[i].thumbnailImage;
                    [imageProressView startAnimating];
                    [newImageView setImageURL:[NSURL URLWithString:self.imagemessageList[i].imageUrl]];
                }
            } else {

                newImageView.image = imageView.image;
            }
        }
        [self resizeSubviews:newImageView];
        [self resetProgressViewFrame:newImageView];

        [imagesrcoll addSubview:newImageView];
        UITapGestureRecognizer *singleTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        [imagesrcoll addGestureRecognizer:singleTap];

        //双击放大或缩小
        UITapGestureRecognizer *doubleTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        [singleTap requireGestureRecognizerToFail:doubleTap];
        doubleTap.numberOfTapsRequired = 2;
        imagesrcoll.userInteractionEnabled = YES;
        [imagesrcoll addGestureRecognizer:doubleTap];

        [self.scrollView addSubview:imagesrcoll];
        if ([RCKitUtility isRTL]) {
            [imagesrcoll setTransform:CGAffineTransformMakeScale(-1, 1)];
        }
        imagesrcoll.minimumZoomScale = 1.0;
        imagesrcoll.maximumZoomScale = 4.0;
        [imagesrcoll setZoomScale:1.0];
    }
}

- (void)setImageCenter:(UIScrollView *)scrollView {
    UIScrollView *subview = self.scrollView.subviews[self.currentIndex];
    CGFloat offsetX = (subview.frame.size.width > subview.contentSize.width)
                          ? (subview.frame.size.width - subview.contentSize.width) * 0.5
                          : 0.0;
    CGFloat offsetY = (subview.frame.size.height > subview.contentSize.height)
                          ? (subview.frame.size.height - subview.contentSize.height) * 0.5
                          : 0.0;
    for (UIView *subView in scrollView.subviews) {
        if ([subView isKindOfClass:[RCloudImageView class]]) {
            subView.center =
                CGPointMake(subview.contentSize.width * 0.5 + offsetX, subview.contentSize.height * 0.5 + offsetY);
        }
    }
}

- (void)action:(NSTimer *)scheduledTimer {
    RCloudImageView *imageView = (RCloudImageView *)(scheduledTimer.userInfo);
    NSString *imageUrl = [imageView.imageURL absoluteString];
    RCImageMessageProgressView *imageProressView = self.imageProgressList[imageUrl];
    if (imageProressView) {
        [imageProressView stopAnimating];
        [imageProressView setHidden:YES];
    }
    imageView.frame = self.view.frame;
    if ([imageUrl hasPrefix:@"http"]) {
        UIImage *image = RCResourceImage(@"broken");
        imageView.image = nil;
        UIImageView *imageViewTip = [[UIImageView alloc] initWithImage:image];
        [imageViewTip setFrame:CGRectMake(0, 0, 81, 60)];
        [imageViewTip setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2)];
        [imageView addSubview:imageViewTip];
        UILabel *failLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 75,
                                                                       self.view.frame.size.height / 2 + 44, 150, 30)];
        failLabel.text = RCLocalizedString(@"ImageLoadFailed");
        failLabel.textAlignment = NSTextAlignmentCenter;
        failLabel.textColor = HEXCOLOR(0x999999);
        [imageView addSubview:failLabel];
    } else {
        UIImage *image = RCResourceImage(@"exclamation");
        imageView.image = nil;
        UIImageView *imageViewTip = [[UIImageView alloc] initWithImage:image];
        [imageViewTip setFrame:CGRectMake(0, 0, 71, 71)];
        [imageViewTip setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2)];
        [imageView addSubview:imageViewTip];
        UILabel *failLabel =
            [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 75,
                                                      self.view.frame.size.height / 2 + 49.5, 150, 30)];
        failLabel.text = RCLocalizedString(@"ImageHasBeenDeleted");
        failLabel.textAlignment = NSTextAlignmentCenter;
        failLabel.textColor = HEXCOLOR(0x999999);
        [imageView addSubview:failLabel];
    }
}

#pragma mark - Getters and Setters
- (RCImageMessage *)currentPreviewImage {
    if (self.currentIndex < self.imageViewList.count) {
        return self.imagemessageList[self.currentIndex];
    }
    return nil;
}

- (void)setStatusBarHidden:(NSNumber *)hidden {
    _statusBarHidden = [hidden boolValue];
    [UIView animateWithDuration:0.25
                     animations:^{
                         [self setNeedsStatusBarAppearanceUpdate];
                     }];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}
@end
