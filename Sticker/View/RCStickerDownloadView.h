//
//  RCStickerDownloadView.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/15.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RCStickerDownloadViewDelegate <NSObject>

- (void)beginDownloadPackage;

@end

typedef NS_ENUM(NSUInteger, RCStickerDownloadViewStstus) {
    RCStickerDownloadViewStstusUnDownload = 0,
    RCStickerDownloadViewStstusDownloading = 1,
    RCStickerDownloadViewStstusUnknow = 2
};

@interface RCStickerDownloadView : UIView

@property (nonatomic, weak) id<RCStickerDownloadViewDelegate> delegate;

- (void)setCurrentStstus:(RCStickerDownloadViewStstus)currentStatus progress:(float)progress;

@end
