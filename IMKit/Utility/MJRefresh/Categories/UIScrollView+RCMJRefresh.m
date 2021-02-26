//  代码地址: https://github.com/CoderMJLee/RCMJRefresh
//  代码地址:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
//  UIScrollView+RCMJRefresh.m
//  RCMJRefreshExample
//
//  Created by MJ Lee on 15/3/4.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import "UIScrollView+RCMJRefresh.h"
#import "RCMJRefreshFooter.h"
#import <objc/runtime.h>

static const char RCMJRefreshFooterKey = '\0';

@implementation UIScrollView (RCMJRefresh)

#pragma mark - footer
- (void)setRcmj_footer:(RCMJRefreshFooter *)mj_footer {
    if (mj_footer != self.rcmj_footer) {
        // 删除旧的，添加新的
        [self.rcmj_footer removeFromSuperview];
        [self insertSubview:mj_footer atIndex:0];

        // 存储新的
        objc_setAssociatedObject(self, &RCMJRefreshFooterKey, mj_footer, OBJC_ASSOCIATION_RETAIN);
    }
}

- (RCMJRefreshFooter *)rcmj_footer {
    return objc_getAssociatedObject(self, &RCMJRefreshFooterKey);
}

#pragma mark - 过期
- (void)setRcfooter:(RCMJRefreshFooter *)footer {
    self.rcmj_footer = footer;
}

- (RCMJRefreshFooter *)rcfooter {
    return self.rcmj_footer;
}

#pragma mark - other
- (NSInteger)rcmj_totalDataCount {
    NSInteger totalCount = 0;
    if ([self isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView *)self;

        for (NSInteger section = 0; section < tableView.numberOfSections; section++) {
            totalCount += [tableView numberOfRowsInSection:section];
        }
    } else if ([self isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self;

        for (NSInteger section = 0; section < collectionView.numberOfSections; section++) {
            totalCount += [collectionView numberOfItemsInSection:section];
        }
    }
    return totalCount;
}

@end
