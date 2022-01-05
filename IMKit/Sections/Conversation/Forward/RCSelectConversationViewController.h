//
//  RCSelectConversationViewController.h
//  RongCallKit
//
//  Created by RongCloud on 16/3/12.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RongIMLib/RongIMLib.h>
#import "RCBaseViewController.h"

@interface RCSelectConversationViewController : RCBaseViewController

- (instancetype)initSelectConversationViewControllerCompleted:
    (void (^)(NSArray<RCConversation *> *conversationList))completedBlock;

@end
