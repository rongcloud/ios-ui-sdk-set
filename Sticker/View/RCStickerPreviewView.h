//
//  RCStickerPreviewView.h
//  RongSticker
//
//  Created by liyan on 2018/8/17.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCStickerSingle.h"
#import "RongStickerAdaptiveHeader.h"
typedef NS_ENUM(NSInteger, RCStickerPreviewPosition) {
    RCStickerPreviewPositionLeft = 0,
    RCStickerPreviewPositionCenter,
    RCStickerPreviewPositionRight
};

@interface RCStickerPreviewView : RCBaseImageView

@property (nonatomic, strong) RCStickerSingle *stickerModel;
@property (nonatomic, strong) NSString *packageId;
@property (nonatomic, assign) RCStickerPreviewPosition previewPosition;

@end
