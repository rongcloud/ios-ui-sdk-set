//
//  RCImagePreviewCell.m
//  RongIMKit
//
//  Created by zhanggaihong on 2021/5/27.
//  Copyright © 2021年 RongCloud. All rights reserved.
//

#import "RCImagePreviewCell.h"
#import "RCloudImageView.h"
#import <RongIMLibCore/RongIMLibCore.h>
#import "RCMessageModel.h"
#import "RCImageMessageProgressView.h"
#import "RCKitCommonDefine.h"
#import "RCBaseScrollView.h"
@interface RCImagePreviewCell () <UIScrollViewDelegate, RCloudImageViewDelegate>
@property (nonatomic, strong) RCBaseScrollView *scrollView;
@property (nonatomic, strong) RCloudImageView *previewImageView;
@property (nonatomic, strong) RCImageMessageProgressView *progressView;
@property(nonatomic, strong) UILabel *labFailed;
@property(nonatomic, strong) UIImageView *imgFailed;
@end

@implementation RCImagePreviewCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self creatPreviewCollectionCell];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.scrollView.frame = self.bounds;
    [self resetSubviews];
    [self.scrollView setContentSize:CGSizeMake(self.previewImageView.frame.size.width, self.previewImageView.frame.size.height)];
    [self.progressView setCenter:CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2)];
}

#pragma mark - Public Methods

- (void)configPreviewCellWithItem:(RCMessageModel *)model {
    self.labFailed.text = nil;
    self.imgFailed.image = nil;
    self.messageModel = model;
    [self.scrollView setZoomScale:1.0];
    [self.progressView setCenter:CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2)];
    RCImageMessage *imageContent = (RCImageMessage *)model.content;
    self.previewImageView.placeholderImage = imageContent.thumbnailImage;
    if (imageContent.localPath.length > 0 &&
        [[NSFileManager defaultManager] fileExistsAtPath:imageContent.localPath]) {
        [self.previewImageView setImageURL:[NSURL URLWithString:imageContent.localPath]];
        [self resizeSubviews];
    } else {
        if ([imageContent.imageUrl hasPrefix:@"http"]) {
            //判断是否已加载
            if ([[RCloudImageLoader sharedImageLoader]
                 hasLoadedImageURL:[NSURL URLWithString:imageContent.imageUrl]]) {
                [self.previewImageView setImageURL:[NSURL URLWithString:imageContent.imageUrl]];
            } else {
                self.previewImageView.delegate = self;
                [self.previewImageView setImageURL:[NSURL URLWithString:imageContent.imageUrl]];
                self.progressView.hidden = NO;
                [self.progressView startAnimating];
            }
        } else {
            [self.previewImageView setImageURL:[NSURL URLWithString:imageContent.imageUrl]];
        }
    }
}

- (void)resetSubviews {
    [self.scrollView setZoomScale:1.0 animated:NO];
    [self resizeSubviews];
}

#pragma mark - UIScrollViewDelegate

- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.previewImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setImageCenter:scrollView];
}

#pragma mark -  RCloudImageViewDelegate

- (void)imageViewLoadedImage:(RCloudImageView *)imageView {
    //图片加载成功后，去掉加载中的标识
    if (!self.progressView.hidden) {
        [self.progressView stopAnimating];
        self.progressView.hidden = YES;
    }
    [self resizeSubviews];
    [self.scrollView setContentSize:CGSizeMake(imageView.frame.size.width, imageView.frame.size.height)];
}

- (void)imageViewFailedToLoadImage:(RCloudImageView *)imageView error:(NSError *)error {
    [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(action:) userInfo:imageView repeats:NO];
}


#pragma mark - target action

- (void)singleTap:(UITapGestureRecognizer *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(imagePreviewCellDidSingleTap:)]) {
        [self.delegate imagePreviewCellDidSingleTap:self];
    }
}

- (void)doubleTap:(UITapGestureRecognizer *)sender {
    if (self.scrollView.contentSize.width > self.frame.size.width) {
        [self.scrollView setZoomScale:1.0 animated:YES];
    } else {
        CGPoint touchPoint = [sender locationInView:self.scrollView];
        CGFloat newZoomScale = self.scrollView.maximumZoomScale;
        CGFloat xsize = self.frame.size.width / newZoomScale;
        CGFloat ysize = self.frame.size.height / newZoomScale;
        [self.scrollView zoomToRect:CGRectMake(touchPoint.x - xsize / 2, touchPoint.y - ysize / 2, xsize, ysize) animated:YES];
    }
}

- (void)longPressed:(UILongPressGestureRecognizer *)sender{
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateEnded) {
        return;
    } else if (press.state == UIGestureRecognizerStateBegan) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(imagePreviewCellDidLongTap:)]) {
            [self.delegate imagePreviewCellDidLongTap:sender];
        }
    }
}

- (UILabel *)labFailed {
    if (!_labFailed) {
        UILabel *failLabel = [[UILabel alloc] init];
        failLabel.textAlignment = NSTextAlignmentCenter;
        failLabel.textColor = RCDynamicColor(@"text_secondary_color", @"0x999999", @"0x999999");
        _labFailed = failLabel;
    }
    return _labFailed;
}

- (UIImageView *)imgFailed {
    if (!_imgFailed) {
        _imgFailed = [UIImageView new];
    }
    return _imgFailed;
}

- (void)action:(NSTimer *)scheduledTimer {
    self.previewImageView.image = nil;
    RCImageMessage *message = (RCImageMessage *)self.messageModel.content;
    NSString *imageUrl = message.imageUrl;
    if (!self.progressView.hidden) {
        [self.progressView stopAnimating];
        [self.progressView setHidden:YES];
    }
    if ([imageUrl hasPrefix:@"http"]) {
        self.imgFailed.image = RCDynamicImage(@"conversation_msg_cell_image_broken_img", @"broken");
        self.imgFailed.frame = CGRectMake(0, 0, 81, 60);
        self.imgFailed.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
        self.labFailed.frame = CGRectMake(self.frame.size.width / 2 - 75, self.frame.size.height / 2 + 44, 150, 30);
        self.labFailed.text = RCLocalizedString(@"ImageLoadFailed");
    } else {
        self.imgFailed.image = RCDynamicImage(@"image_preview_exclamation_img", @"exclamation");
        self.imgFailed.frame = CGRectMake(0, 0, 71, 71);
        self.imgFailed.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
        self.labFailed.frame = CGRectMake(self.frame.size.width / 2 - 75, self.frame.size.height / 2 + 49.5, 150, 30);
        self.labFailed.text = RCLocalizedString(@"ImageHasBeenDeleted");
    }
}

#pragma mark - layout
- (void)creatPreviewCollectionCell {
    [self.contentView addSubview:self.labFailed];
    [self.contentView addSubview:self.imgFailed];
    
    [self.contentView addSubview:self.scrollView];
    [self.scrollView addSubview:self.previewImageView];

    UITapGestureRecognizer *singleTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];

    UITapGestureRecognizer *doubleTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    
    //长按可选择是否保存图片
    UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];

    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.contentView addGestureRecognizer:singleTap];
    [self.contentView addGestureRecognizer:doubleTap];
    [self.contentView addGestureRecognizer:longPress];
}

- (void)resizeSubviews {
    CGFloat width = self.frame.size.width;
    CGFloat height = self.frame.size.height;
    UIImage *image = self.previewImageView.image;
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    if(imageWidth <= 0){
        imageWidth = 1;
    }
    if(imageHeight <= 0) {
        imageHeight = 1;
    }
    CGPoint viewCenter = CGPointMake(width/2, height/2);
    if (width < height) {
        if (imageWidth < width) {
            /*
             图宽＜屏幕宽，高＜屏幕高 宽适配屏幕宽，高不变，水平垂直居中屏幕展示
             图宽＜屏幕宽，高≥屏幕高 宽不变，高不变，水平居中，垂直方向从图片顶端开始展示
             */
            if (imageHeight < height) {
                CGFloat scale = imageHeight / imageWidth;
                imageWidth = width;
                imageHeight = width * scale;
                [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
                self.previewImageView.center = viewCenter;
            } else {
                [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
                self.previewImageView.center = CGPointMake(width / 2, imageHeight / 2);
            }
        } else {
            /*
             图宽大于等于屏幕宽 宽适配屏幕宽，高等比放大或缩小  放大或缩小后的高＜屏幕高，垂直居中屏幕显示
             放大或缩小后的高≥屏幕高，垂直方向从图片顶端开始展示
             */
            CGFloat scale = imageHeight / imageWidth;
            imageWidth = width;
            imageHeight = width * scale;
            [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
            if (imageHeight < height) {
                self.previewImageView.center = viewCenter;
            }
        }
    }else{

        /*
        //横屏
        1、横屏后图宽比图高小于 0.45：
        图宽小于屏幕宽度，宽不变，高不变，水平居中，垂直方向从图片顶端开始展示。
        图宽大于屏幕宽度，等比缩放宽到屏幕尺寸，高等比缩放，水平居中，垂直方向从图片顶端开始展示
        2、横屏后图宽比图高大于等于 0.45 小于 1.7 ：图高适配屏幕高，宽等比放大或缩小，水平居中展示。
        3、横屏后图宽比图高大于等于 1.7 ：图宽适配屏幕宽，高等比放大或缩小，水平居中展示。
         */
        if (imageWidth/imageHeight < 0.45) {
            if (imageWidth < width) {
                [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
            }else{
                CGFloat scale = imageHeight / imageWidth;
                imageWidth = width;
                imageHeight = width * scale;
                [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
            }
            if (imageHeight > height) {
                self.previewImageView.center = CGPointMake(width / 2, imageHeight / 2);
            }else{
                self.previewImageView.center = viewCenter;
            }
        }else if(imageWidth/imageHeight < 1.7){
            CGFloat scale = imageWidth / imageHeight;
            imageWidth = height * scale;
            imageHeight = height;
            [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
            self.previewImageView.center = viewCenter;
        }else{
            CGFloat scale = imageHeight / imageWidth;
            imageWidth = width;
            imageHeight = width * scale;
            [self.previewImageView setFrame:CGRectMake(0, 0, imageWidth, imageHeight)];
            if (imageHeight > height) {
                self.previewImageView.center = CGPointMake(width / 2, imageHeight / 2);
            }else{
                self.previewImageView.center = viewCenter;
            }
        }
    }
}

- (void)setImageCenter:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.frame.size.width > scrollView.contentSize.width)
                          ? (scrollView.frame.size.width - scrollView.contentSize.width) * 0.5
                          : 0.0;
    CGFloat offsetY = (scrollView.frame.size.height > scrollView.contentSize.height)
                          ? (scrollView.frame.size.height - scrollView.contentSize.height) * 0.5
                          : 0.0;
    self.previewImageView.center =
        CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, scrollView.contentSize.height * 0.5 + offsetY);
}

#pragma mark - Getter

- (RCBaseScrollView *)scrollView{
    if (!_scrollView) {
        _scrollView = [[RCBaseScrollView alloc] initWithFrame:self.bounds];
        _scrollView.minimumZoomScale = 1.0;
        _scrollView.maximumZoomScale = 4.0;
        [_scrollView setZoomScale:1.0];
        _scrollView.multipleTouchEnabled = YES;
        _scrollView.delegate = self;
        _scrollView.scrollsToTop = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.delaysContentTouches = NO;
    }
    return _scrollView;
}

- (RCloudImageView *)previewImageView{
    if (!_previewImageView) {
        _previewImageView = [[RCloudImageView alloc] initWithFrame:CGRectZero];
        _previewImageView.clipsToBounds = YES;
        _previewImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _previewImageView;
}

- (RCImageMessageProgressView *)progressView{
    if (!_progressView) {
        _progressView =
            [[RCImageMessageProgressView alloc] initWithFrame:CGRectMake(0, 0, 135, 135)];
        _progressView.label.hidden = YES;
        _progressView.indicatorView.color = RCDynamicColor(@"pop_layer_background_color", @"0x000000", @"0x000000");
        _progressView.backgroundColor = [UIColor clearColor];
        [_progressView setCenter:CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2)];
        _progressView.userInteractionEnabled = NO;
        _progressView.indicatorView.userInteractionEnabled = NO;
        [self.contentView addSubview:_progressView];
    }
    return _progressView;
}
@end
