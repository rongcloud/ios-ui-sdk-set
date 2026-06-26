//
//  RCSightMessage+imkit.h
//  RongIMKit
//
//  Created by 张改红 on 2020/12/23.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#ifndef RCSightMessage_imkit_h
#define RCSightMessage_imkit_h

@interface RCSightMessage ()
+ (instancetype)messageWithAsset:(AVAsset *)asset thumbnail:(UIImage *)image duration:(NSUInteger)duration;
@end

#endif /* RCSightMessage_imkit_h */
