//
//  RCPluginBoardView.h
//  RongExtensionKit
//
//  Created by Liv on 15/3/15.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPluginBoardView.h"
#import "RCPageControl.h"
#import "RCKitCommonDefine.h"
#import "RCPluginBoardHorizontalCollectionViewLayout.h"
#import "RCPluginBoardItem.h"
#import "UIImage+RCDynamicImage.h"
#import "RCExtensionService.h"
#import "RCKitConfig.h"
#define RCPluginBoardCell @"RCPluginBoardCell"

@interface RCPluginBoardView () <UICollectionViewDataSource, UICollectionViewDelegate> {
    RCPageControl *_pageCtrl;
    CGFloat _lastWidth;
    NSInteger _currentIndex;
}
@property (strong, nonatomic) RCPluginBoardHorizontalCollectionViewLayout *layout;
@end

@implementation RCPluginBoardView
#pragma mark - Life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    self.layout = [RCPluginBoardHorizontalCollectionViewLayout new];
    self = [super initWithFrame:frame];
    if (self) {
        _currentIndex = 0;
        CGRect contentViewFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        self.contentView = [[UICollectionView alloc] initWithFrame:contentViewFrame collectionViewLayout:self.layout];
        self.contentView.dataSource = self;
        self.contentView.delegate = self;
        self.contentView.pagingEnabled = YES;
        self.allItems = [@[] mutableCopy];
        self.contentView.scrollEnabled = YES;
        [self addSubview:self.contentView];
        self.extensionView = [[UIView alloc] initWithFrame:contentViewFrame];
        [self.extensionView setHidden:YES];
        self.extensionView.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x1c1c1c);
        [self addSubview:self.extensionView];
        [self.contentView setShowsHorizontalScrollIndicator:NO];
        [self.contentView setShowsVerticalScrollIndicator:NO];
        [self.contentView setBackgroundColor:RCDYCOLOR(0xf5f6f9, 0x1c1c1c)];
        [self.contentView registerClass:[RCPluginBoardItem class] forCellWithReuseIdentifier:RCPluginBoardCell];
        if ([RCKitUtility isRTL]) {
            [self.contentView setTransform:CGAffineTransformMakeScale(-1, 1)];
        }

    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self fitDarkMode];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (_lastWidth != self.bounds.size.width) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.contentView.frame = self.bounds;
            [_contentView reloadData];
            if (_currentIndex == 1 || [RCKitUtility isRTL]) {
                [_contentView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:_currentIndex]
                                     atScrollPosition:[RCKitUtility isRTL] ? UICollectionViewScrollPositionRight : UICollectionViewScrollPositionLeft
                                             animated:[RCKitUtility isRTL] ? NO : YES];
                _pageCtrl.currentPage = _currentIndex;
            }
        });
    }
    _lastWidth = self.bounds.size.width;
}

#pragma mark - Public Methods
- (void)insertItem:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title atIndex:(NSInteger)index tag:(NSInteger)tag{
    RCPluginBoardItem *__item = [[RCPluginBoardItem alloc] initWithTitle:title normalImage:normalImage highlightedImage:highlightedImage tag:tag];
    [self insertItem:__item atIndex:index];
}

- (void)insertItem:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title tag:(NSInteger)tag{
    [self insertItem:normalImage highlightedImage:highlightedImage title:title atIndex:self.allItems.count tag:tag];
}

- (void)updateItemAtIndex:(NSInteger)index normalImage:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title{
    if (index >= 0 && index < self.allItems.count) {
        RCPluginBoardItem *item = self.allItems[index];
        if (normalImage) {
            item.normalImage = normalImage;
        }
        if (highlightedImage) {
            item.highlightedImage = highlightedImage;
        }
        if (title) {
            item.title = title;
        }
        [self.contentView reloadData];
    }
}

- (void)updateItemWithTag:(NSInteger)tag normalImage:(UIImage *)normalImage highlightedImage:(UIImage *)highlightedImage title:(NSString *)title{
    for (int i = 0; i < self.allItems.count; i++) {
        RCPluginBoardItem *item = _allItems[i];
        if (item.tag == tag) {
            if (normalImage) {
                item.normalImage = normalImage;
            }
            if (highlightedImage) {
                item.highlightedImage = highlightedImage;
            }
            if (title) {
                item.title = title;
            }
            [self.contentView reloadData];
        }
    }
}

- (void)removeItemWithTag:(NSInteger)tag {
    for (int i = 0; i < _allItems.count; i++) {
        RCPluginBoardItem *item = _allItems[i];
        if (item.tag == tag) {
            [_allItems removeObjectAtIndex:i];
            [self.contentView reloadData];
        }
    }
}

- (void)removeItemAtIndex:(NSInteger)index {
    if (_allItems) {
        NSInteger _count = [_allItems count];

        if (index >= _count) {
            return;
        }

        [_allItems removeObjectAtIndex:index];
        [self.contentView reloadData];
    }
}

- (void)removeAllItems {
    [self.allItems removeAllObjects];
    [self.contentView reloadData];
}

#pragma mark - UICollectionViewDataSource
//定义展示的UICollectionViewCell的个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ((section + 1) * self.layout.itemsPerSection >= self.allItems.count) {
        return self.allItems.count - section * self.layout.itemsPerSection;
    } else {
        return self.layout.itemsPerSection;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    NSInteger sectionNumber = (NSInteger)ceilf((double)self.allItems.count / self.layout.itemsPerSection);
    [self setPageTips:sectionNumber];
    return sectionNumber;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = RCPluginBoardCell;
    RCPluginBoardItem *cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }
    RCPluginBoardItem *item = _allItems[indexPath.row + indexPath.section * self.layout.itemsPerSection];
    cell.title = item.title;
    cell.normalImage = item.normalImage;
    cell.highlightedImage = item.highlightedImage;
    __weak typeof(self) weakSelf = self;
    [cell setItemclick:^{
        if (weakSelf.pluginBoardDelegate &&
            [weakSelf.pluginBoardDelegate respondsToSelector:@selector(pluginBoardView:clickedItemWithTag:)]) {
            RCPluginBoardItem *item =
                weakSelf.allItems[indexPath.row + indexPath.section * weakSelf.layout.itemsPerSection];
            [weakSelf.pluginBoardDelegate pluginBoardView:weakSelf clickedItemWithTag:item.tag];
        }
    }];
    cell.tag = item.tag;
    [cell loadView];
    if ([RCKitUtility isRTL]) {
        [cell setTransform:CGAffineTransformMakeScale(-1, 1)];
    }
    return cell;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGPoint offset = scrollView.contentOffset;
    CGRect bounds = scrollView.frame;
    int currentIndex = offset.x / bounds.size.width;
    _currentIndex = currentIndex;
    [_pageCtrl setCurrentPage:currentIndex];
}

#pragma mark - Dark Mode
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self fitDarkMode];
}

- (void)fitDarkMode {
    if (!RCKitConfigCenter.ui.enableDarkMode) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        for (RCPluginBoardItem *item in self.allItems) {
            if (item.normalImage.rc_imageLocalPath) {
                item.normalImage = [UIImage rc_imageWithLocalPath:item.normalImage.rc_imageLocalPath];
            }
            if (item.highlightedImage.rc_imageLocalPath) {
                item.highlightedImage = [UIImage rc_imageWithLocalPath:item.highlightedImage.rc_imageLocalPath];
            }
        }
        [self.contentView reloadData];
    }
}

#pragma mark - Private Methods
- (void)setPageTips:(NSInteger)pages {
    if (_pageCtrl) {
        [_pageCtrl removeFromSuperview];
        _pageCtrl = nil;
    }
    _pageCtrl = [[RCPageControl alloc]
        initWithFrame:CGRectMake(0, self.bounds.size.height - 25, self.bounds.size.width, 8)];
    _pageCtrl.currentPage = _currentIndex;
    _pageCtrl.numberOfPages = pages; //当前页
    [self addSubview:_pageCtrl];
    [self bringSubviewToFront:self.extensionView];
}

- (void)insertItem:(RCPluginBoardItem *)item atIndex:(NSInteger)index {
    if (item) {
        if (index > self.allItems.count) {
            index = self.allItems.count;
        }
        [_allItems insertObject:item atIndex:index];
    }
    [self.contentView reloadData];
}

- (float)getBoardViewBottonOriginY {
    float gap = (RC_IOS_SYSTEM_VERSION_LESS_THAN(@"7.0")) ? 64 : 0;
    return [UIScreen mainScreen].bounds.size.height - gap;
}

//用于动画效果
- (void)setHidden:(BOOL)hidden {
    CGRect viewRect = self.frame;
    if (hidden) {
        viewRect.origin.y = [self getBoardViewBottonOriginY];
    } else {
        viewRect.origin.y = [self getBoardViewBottonOriginY] - self.frame.size.height;
    }
    [self setFrame:viewRect];
    [super setHidden:hidden];
}
@end
