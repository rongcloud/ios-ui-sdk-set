//
//  RCMessageCell+Internal.h
//  RongIMKit
//
//  Created by RC on 2026/6/4.
//  Copyright © 2026 RongCloud. All rights reserved.
//

#import "RCMessageCell.h"

@interface RCMessageCell (Internal)

/// Updates subviews whose layout depends on the final messageContentView frame or bounds.
- (void)messageContentViewFrameDidChange NS_REQUIRES_SUPER;

@end
