//
//  RCSTTContentView.m
//  RongIMKit
//
//  Created by RobinCui on 2025/5/27.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCSTTContentView.h"
#import "RCDotLoadingView.h"
#import "RCSTTFailureView.h"
#import "RCSTTDetailView.h"
#import "RCMessageCellTool.h"
#import "RCMessageModel+STT.h"
@interface RCSTTContentView()<RCSTTContentViewModelDelegate> {
    RCSTTContentStatus _status;
}
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) RCSTTContentViewModel *viewModel;
@property (nonatomic, weak) UICollectionView *collectionView;
@property (nonatomic, strong) RCSTTDetailView *detailView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, weak) id<RCMessageCellDelegate> gestureDelegate;
@property (nonatomic, assign) RCSTTContentStatus status;
@property (nonatomic, strong) UIView *loadingView;
@property (nonatomic, strong) UIView *failureView;
@end

@implementation RCSTTContentView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.masksToBounds = YES;
        [self.containerView addSubview:self.detailView];
        [self.containerView addSubview:self.loadingView];
        [self.containerView addSubview:self.failureView];
    }
    return self;
}

- (void)layoutContentView  {
    RCSTTLog(@"layoutContentView before: %@", self);
    self.frame = CGRectMake(self.frame.origin.x,
                            self.frame.origin.y,
                            self.frame.size.width,
                            [self.viewModel speedToTextContentHeight]);
    RCSTTLog(@"layoutContentView after: %@", self);

}

- (void)refreshViewFrameForMessageDirection:(RCMessageDirection)direction
                                  baseFrame:(CGRect)frame {
    CGFloat width = [RCMessageCellTool getMessageContentViewMaxWidth];
    if (direction == MessageDirection_SEND) {
        CGFloat xOffset = CGRectGetMaxX(frame);
        self.frame = CGRectMake(xOffset - width,
                                CGRectGetMaxY(frame)+4,
                                width,
                                [self.viewModel speedToTextContentHeight]);
    } else {
        self.frame = CGRectMake(CGRectGetMinX(frame), CGRectGetMaxY(frame)+4, width, 0);
    }
}

- (void)bindGestureDelegate:(id<RCMessageCellDelegate>)delegate {
    self.gestureDelegate = delegate;
}

- (void)bindCollectionView:(UICollectionView *)collectionView {
    if (self.collectionView != collectionView) {
        self.collectionView = collectionView;
    }
}

- (void)bindViewModel:(RCSTTContentViewModel *)viewModel
            baseFrame:(CGRect)frame {
    if (viewModel == self.viewModel) {
        return;
    }
    [self refreshViewFrameForMessageDirection:viewModel.model.messageDirection
                                    baseFrame:frame];
    RCSTTLog(@"Bind : model delegate to nil %@ on %p model %p", self.viewModel.model.messageUId, self, self.viewModel.model);
    viewModel.delegate = self;
    RCSTTLog(@"Bind model delegate to self %@ on %p model %p", viewModel.model.messageUId, self, viewModel.model);
    self.viewModel = viewModel;
    self.detailView.messageSent = self.viewModel.model.messageDirection == MessageDirection_SEND;
    [viewModel refreshStatus];
}

- (void)showViewByStatus:(RCSTTContentStatus)status {
    RCSTTLog("UID: %@, showViewByStatus: %ld ",self.viewModel.model.messageUId, (long)status);
    switch (status) {
        case RCSTTContentStatusText: {
            self.detailView.hidden = NO;
            self.loadingView.hidden = YES;
            self.failureView.hidden = YES;
            self.contentView = self.detailView;
        }
            break;
            
        case RCSTTContentStatusFailed:{
            self.detailView.hidden = YES;
            self.loadingView.hidden = YES;
            self.failureView.hidden = NO;
            self.contentView = self.failureView;
        }
            break;
        case RCSTTContentStatusLoading: {
            self.detailView.hidden = YES;
            self.loadingView.hidden = NO;
            self.failureView.hidden = YES;
            self.contentView = self.loadingView;
        }
            break;
        default: {
            self.detailView.hidden = YES;
            self.loadingView.hidden = YES;
            self.failureView.hidden = YES;
            self.contentView = nil;
        }
            break;
    }
}


- (void)setupView {
    [super setupView];
    [self addSubview:self.containerView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    RCSTTLog("UID:%@, contentView layoutSubviews :  size:%f - %f",self.viewModel.model.messageUId, self.bounds.size.width, self.bounds.size.height);
    self.containerView.frame = self.bounds;
}

- (void)longPressedSTTInfoContentView:(id)sender {
    UILongPressGestureRecognizer *press = (UILongPressGestureRecognizer *)sender;
    if (press.state == UIGestureRecognizerStateBegan) {
        [self.detailView detailViewHighlight:YES];
        if ([self.gestureDelegate respondsToSelector:@selector(didLongTouchSTTInfo:inView:)]) {
            [self.gestureDelegate didLongTouchSTTInfo:self.viewModel.model inView:self.detailView];
        }
        return;
    }
    [self.detailView detailViewHighlight:NO];
    
}

- (void)scrollToCurrentMessageIfNeeded {
    if (!self.collectionView || !self.contentView || self.contentView.hidden) {
        return;
    }
    
    // 获取 contentView 在 collectionView 中的下边缘位置
    CGRect detailViewFrame = [self.contentView convertRect:self.contentView.bounds toView:self.collectionView];
    CGFloat detailViewBottom = CGRectGetMaxY(detailViewFrame);
    
    // 获取 collectionView 可视区域的下边缘位置
    CGFloat visibleBottom = self.collectionView.contentOffset.y + self.collectionView.frame.size.height;
    
    // 如果 detailView 的下边缘超出了可视区域，需要滚动
    if (detailViewBottom > visibleBottom) {
        CGFloat scrollOffset = detailViewBottom - visibleBottom + 10; // 额外增加10pt边距
        CGPoint newOffset = CGPointMake(0, self.collectionView.contentOffset.y + scrollOffset);
        
        // 确保不超过最大滚动范围
        CGFloat maxOffsetY = self.collectionView.contentSize.height - self.collectionView.frame.size.height;
        newOffset.y = MIN(newOffset.y, maxOffsetY);
        newOffset.y = MAX(0, newOffset.y);
        
        [self.collectionView setContentOffset:newOffset animated:YES];
        RCSTTLog(@"UID:%@, detailView bottom: %f, visible bottom: %f, scrolling offset: %f", 
                 self.viewModel.model.messageUId, detailViewBottom, visibleBottom, scrollOffset);
    } else {
        RCSTTLog(@"UID:%@, detailView is fully visible, no need to scroll (bottom: %f, visible: %f)", 
                 self.viewModel.model.messageUId, detailViewBottom, visibleBottom);
    }
}

#pragma mark - RCSTTContentViewModelDelegate
- (void)sttViewModelUpdateSTTContentViewLayout:(RCSTTContentViewModel *)viewModel {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.viewModel != viewModel) {
            return;
        }
        RCSTTLog("UID:%@, updateSTTContentViewLayout: %ld", self.viewModel.model.messageUId, (long)self.status);
        if (self.status == RCSTTContentStatusText ) {
            // 先执行CALayer动画（独立执行，避免UIView动画块干扰）
            [self.detailView animateIfNeeded];
            // 获取CollectionView的方法
            UICollectionView *collectionView = [self collectionView];
            if (!collectionView) {
                RCSTTLog("UID:%@, collectionView is nil, retry after delay", self.viewModel.model.messageUId);
        
                return;
            }

            // 再执行UIView动画进行布局更新
            [UIView animateWithDuration:0.35
                             animations:^{
                [self.collectionView.collectionViewLayout invalidateLayout];
                [self.collectionView layoutIfNeeded];
            } completion:^(BOOL finished) {
                // 布局更新完成后，滚动到包含当前消息的位置，确保新增内容可见
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self scrollToCurrentMessageIfNeeded];
                });
            }];
        } else {
            [self.collectionView.collectionViewLayout invalidateLayout];
            // 布局更新完成后，滚动到包含当前消息的位置，确保新增内容可见
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self scrollToCurrentMessageIfNeeded];
            });
        }
    });
}

- (void)sttViewModel:(RCSTTContentViewModel *)viewModel
        changeStatus:(RCSTTContentStatus)status {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.viewModel != viewModel) {
            return;
        }

        RCSTTLog("UID:%@, changeSTTContentViewStatus: %ld", self.viewModel.model.messageUId, (long)status);
        self.status = status;
    });
}

- (void)sttViewModel:(RCSTTContentViewModel *)viewModel
        displayText:(NSString *)text
               size:(CGSize)size
          animation:(BOOL)animation {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.viewModel != viewModel) {
            return;
        }
        RCSTTLog("UID:%@, displaySTTContentViewText: %@ size:%f - %f, animation: %d",self.viewModel.model.messageUId, text, size.width, size.height, animation);
        self.detailView.bounds = CGRectMake(0, 0, size.width, size.height);
        [self.detailView showText:text size:size animation:animation];
    });
}

- (void)sttViewModel:(RCSTTContentViewModel *)viewModel speechToTextFinished:(BOOL)result {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.viewModel != viewModel) {
            return;
        }
        if (self.sttFinishedBlock) {
            self.sttFinishedBlock();
        }
    });
}
#pragma mark - Getter
- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [UIView new];
    }
    return _containerView;;
}

- (RCSTTDetailView *)detailView {
    if (!_detailView) {
        _detailView = [[RCSTTDetailView alloc] initWithFrame:CGRectMake(0, 0, 270, 40)];
        UILongPressGestureRecognizer *longPress =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressedSTTInfoContentView:)];
        [_detailView addGestureRecognizer:longPress];
        _detailView.hidden = YES;
    }
    return _detailView;
}

- (RCSTTContentStatus)status {
    return _status;
}

- (void)setStatus:(RCSTTContentStatus)status {
    if (_status != status) {
        _status = status;
            [self showViewByStatus:status];
    }
    if (!self.contentView) {
        return;
    }
        if (self.viewModel.model.messageDirection == MessageDirection_SEND) {
            self.contentView.frame = CGRectMake(CGRectGetMaxX(self.containerView.bounds) - self.contentView.frame.size.width,
                                                0,
                                                self.contentView.frame.size.width,
                                                self.contentView.frame.size.height);
            RCSTTLog(@"UID:%@, contentView right:%@ ", self.viewModel.model.messageUId, self.contentView.description);
        } else {
            self.contentView.frame = CGRectMake(0,
                                                0,
                                                self.contentView.frame.size.width,
                                                self.contentView.frame.size.height);
            RCSTTLog(@"UID:%@,  contentView left :%@ ", self.viewModel.model.messageUId,self.contentView.description);
            
        }
    [self setNeedsDisplay];
    [self layoutIfNeeded];
}

- (UIView *)failureView {
    if (!_failureView) {
        RCSTTFailureView *failView = [RCSTTFailureView new];
        failView.layer.cornerRadius = 8;
        failView.layer.masksToBounds = YES;
        CGRect frame = CGRectMake(0, 0, CGRectGetWidth(failView.bounds), 40);
        failView.frame = frame;
        UIView *view = [[UIView alloc] initWithFrame:frame];
        [view addSubview:failView];
        view.hidden = YES;
        _failureView = view;
    }
    return _failureView;
}

- (UIView *)loadingView {
    if (!_loadingView) {
        RCDotLoadingView *dot = [[RCDotLoadingView alloc] initWithFrame:CGRectMake(0, 0, 54, 40)];
        [dot startAnimating];
        dot.layer.cornerRadius = 8;
        dot.layer.masksToBounds = YES;
        CGRect frame = CGRectMake(0, 0, 54, 40);
        if (self.viewModel.model.messageDirection == MessageDirection_SEND) {
            frame = CGRectMake(CGRectGetMaxX(self.bounds)-54, 0, 54, 40);
        }
        UIView *view = [[UIView alloc] initWithFrame:frame];
        [view addSubview:dot];
        view.hidden = YES;
        _loadingView = view;
    }
    return _loadingView;
}
@end
