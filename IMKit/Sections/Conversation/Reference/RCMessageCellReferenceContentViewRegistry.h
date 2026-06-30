//
//  RCMessageCellReferenceContentViewRegistry.h
//  RongIMKit
//
//  Created by RongCloud on 2026/6/25.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCMessageCellReferenceContentView.h"

/// 消息 cell 内引用展示 View 的内部注册表。
@interface RCMessageCellReferenceContentViewRegistry : NSObject

+ (void)registerContentViewClass:(Class)viewClass forMessageClass:(Class)messageClass;
+ (Class)contentViewClassForMessageContent:(RCMessageContent *)content objectName:(NSString *)objectName;

@end
