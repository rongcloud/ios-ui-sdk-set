//
//  RCSendCardMessageView+internal.h
//  RongContactCard
//
//  Created by 张改红 on 2020/12/23.
//  Copyright © 2020 ios-rongContactCard. All rights reserved.
//

#ifndef RCSendCardMessageView_internal_h
#define RCSendCardMessageView_internal_h

@interface RCSendCardMessageView ()
@property (nonatomic) RCConversationType conversationType;
@property (nonatomic, strong) NSString *targetId;
@property (nonatomic, assign) NSInteger destructDuration;
@end

#endif /* RCSendCardMessageView_internal_h */
