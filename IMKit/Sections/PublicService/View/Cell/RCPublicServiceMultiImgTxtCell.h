//
//  RCPublicServiceMultiImgTxtCell.h
//  RongIMKit
//
//  Created by litao on 15/4/14.
//  Copyright (c) 2015 RongCloud. All rights reserved.
//

#import "RCMessageBaseCell.h"
#import "RCMessageCellDelegate.h"

@interface RCPublicServiceMultiImgTxtCell : RCMessageBaseCell
@property (nonatomic, weak) id<RCPublicServiceMessageCellDelegate> publicServiceDelegate;
@end
