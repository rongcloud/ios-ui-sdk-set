//
//  RCEmoticonPackage.m
//  RongExtensionKit
//
//  Created by 杜立召 on 16/7/27.
//  Copyright © 2016年 RongCloud. All rights reserved.
//

#import "RCEmoticonPackage.h"
#import "RCEmojiBoardView+internal.h"
@interface RCEmoticonPackage () <UIScrollViewDelegate>
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIView *> *loadedEmoticonPage;

@end

@implementation RCEmoticonPackage
#pragma mark - UIScrollViewDelegate
//停止滚动的时候
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.frame;
    int currentIndex = offset.x / bounds.size.width;
    int totalPages = scrollView.contentSize.width / bounds.size.width;

    [self.emojBoardView setCurrentIndex:currentIndex withTotalPages:totalPages];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    CGFloat pageWidth = CGRectGetWidth(scrollView.bounds);
    if (pageWidth <= 0) {
        return;
    }
    int currentIndex = scrollView.contentOffset.x / pageWidth;
    [self loadEmoticonPage:currentIndex + 1];
    [self loadEmoticonPage:currentIndex];
}

#pragma mark - Public Methods
- (id)initEmoticonPackage:(UIImage *)tabImage withTotalCount:(int)pageCount {
    self = [super init];
    if (self) {
        self.totalPage = pageCount;
        self.tabImage = tabImage;
        self.loadedEmoticonPage = [NSMutableDictionary new];
    }
    return self;
}

- (void)showEmoticonView:(int)index {
    if (self.tabSource && index >= 0 && index < self.totalPage) {
        [self loadEmoticonPage:index];
        CGSize viewSize = self.emotionContainerView.bounds.size;
        CGRect rect = CGRectMake(index * viewSize.width, 0, viewSize.width, viewSize.height);
        [self.emotionContainerView scrollRectToVisible:rect animated:NO];
        [self.emojBoardView setCurrentIndex:index withTotalPages:self.totalPage];
    }
}

- (void)setNeedLayout {
    CGSize viewSize = self.emotionContainerView.bounds.size;
    self.emotionContainerView.contentSize = CGSizeMake(viewSize.width * self.totalPage, viewSize.height);
    [self.loadedEmoticonPage enumerateKeysAndObjectsUsingBlock:^(NSNumber *page, UIView *view, BOOL *stop) {
        view.frame = CGRectMake(viewSize.width * page.intValue, 0, viewSize.width, viewSize.height);
    }];
}

- (void)loadEmoticonPage:(int)index {
    if (!self.tabSource || index < 0 || index >= self.totalPage) {
        return;
    }
    UIView *page = self.loadedEmoticonPage[@(index)];
    if (!page) {
        page = [self.tabSource loadEmoticonView:self.identify index:index];
        if (!page) {
            return;
        }
        self.loadedEmoticonPage[@(index)] = page;
    }
    CGSize viewSize = self.emotionContainerView.bounds.size;
    page.frame = CGRectMake(viewSize.width * index, 0, viewSize.width, viewSize.height);
    if (page.superview != self.emotionContainerView) {
        [self.emotionContainerView addSubview:page];
    }
}

#pragma mark - Getters and Setters
- (RCBaseScrollView *)emotionContainerView {
    if (!_emotionContainerView) {
        _emotionContainerView =
            [[RCBaseScrollView alloc] initWithFrame:CGRectMake(0, 0, self.emojBoardView.frame.size.width, 186)];
        _emotionContainerView.pagingEnabled = YES;
        _emotionContainerView.showsHorizontalScrollIndicator = NO;
        _emotionContainerView.showsVerticalScrollIndicator = NO;
        _emotionContainerView.delegate = self;
        _emotionContainerView.contentSize = CGSizeMake(self.emojBoardView.frame.size.width * self.totalPage, 186);
    }
    return _emotionContainerView;
}
@end
