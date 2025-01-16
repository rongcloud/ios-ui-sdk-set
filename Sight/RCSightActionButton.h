//
//  RCSightActionButton.h
//  RongExtensionKit
//
//  Created by zhaobingdong on 2017/4/25.
//  Copyright © 2017年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, RCSightActionState) {
    RCSightActionStateBegin = 0,
    RCSightActionStateMoving,
    RCSightActionStateWillCancel,
    RCSightActionStateDidCancel,
    RCSightActionStateEnd,
    RCSightActionStateClick
};

@interface RCSightActionButton : UIView

@property (nonatomic, assign) BOOL supportLongPress;

@property (nonatomic, assign) NSUInteger canRecordMaxDuration;

@property (nonatomic, copy) void (^action)(RCSightActionState state);

- (void)quit;

@end
