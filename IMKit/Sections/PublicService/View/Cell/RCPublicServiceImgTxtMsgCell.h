//
//  RCPublicServiceImgTxtMsgCell.h
//  RongIMKit
//
//  Created by litao on 15/4/15.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCMessageBaseCell.h"
#import "RCMessageCellDelegate.h"

@interface RCPublicServiceImgTxtMsgCell : RCMessageBaseCell
@property (nonatomic, weak) id<RCPublicServiceMessageCellDelegate> publicServiceDelegate;
@end
