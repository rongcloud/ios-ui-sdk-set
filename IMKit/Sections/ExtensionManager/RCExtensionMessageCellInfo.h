//
//  RCExtensionMessageCellInfo.h
//  RongIMExtension
//
//  Created by RongCloud on 2016/10/18.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 MessageCell info class
 */
@interface RCExtensionMessageCellInfo : NSObject

@property (nonatomic, strong) Class messageContentClass;
@property (nonatomic, strong) Class messageCellClass;

@end
