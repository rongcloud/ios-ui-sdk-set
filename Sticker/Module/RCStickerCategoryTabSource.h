//
//  RCStickerCategoryTabSource.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/8/13.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RongIMKitHeader.h"
#import "RCStickerDataManager.h"

@interface RCStickerCategoryTabSource : NSObject <RCEmoticonTabSource>

@property (nonatomic, assign) RCStickerCategoryType categoryType;

@end
