//
//  RCSelectConversationCell.h
//  RongCallKit
//
//  Created by RongCloud on 16/3/15.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RongIMLib/RongIMLib.h>

@interface RCSelectConversationCell : UITableViewCell

- (void)setConversation:(RCConversation *)conversation ifSelected:(BOOL)ifSelected;

@end
