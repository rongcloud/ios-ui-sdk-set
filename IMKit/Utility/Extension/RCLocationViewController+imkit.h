//
//  RCLocationViewController+imkit.h
//  RongIMKit
//
//  Created by zgh on 2022/2/21.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#ifndef RCLocationViewController_imkit_h
#define RCLocationViewController_imkit_h

@class RCLocationMessage;
@interface RCLocationViewController : RCBaseViewController
- (void)setLatitude:(double)latitude longitude:(double)longitude locationName:(NSString *)locationName;
- (instancetype)initWithLocationMessage:(RCLocationMessage *)locationMessage;

@end
#endif /* RCLocationViewController_imkit_h */
