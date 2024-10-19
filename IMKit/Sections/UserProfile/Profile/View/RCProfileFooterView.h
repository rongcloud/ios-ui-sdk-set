//
//  RCProfileFooterView.h
//  RongIMKit
//
//  Created by zgh on 2024/8/22.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCBaseView.h"
#import "RCButtonItem.h"
NS_ASSUME_NONNULL_BEGIN

@interface RCProfileFooterView : RCBaseView

- (instancetype)initWithTopSpace:(CGFloat)topSpace buttonSpace:(CGFloat)buttonSpace items:(NSArray <RCButtonItem *>*)items;


@end

NS_ASSUME_NONNULL_END
