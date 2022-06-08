//
//  RCLocationViewController+imkit.h
//  RongIMKit
//
//  Created by zgh on 2022/2/21.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#ifndef RCLocationViewController_imkit_h
#define RCLocationViewController_imkit_h

@interface RCLocationViewController : RCBaseViewController
@property (nonatomic, copy) NSString *locationName;
- (void)setLatitude:(double)latitude longitude:(double)longitude;
@end
#endif /* RCLocationViewController_imkit_h */
