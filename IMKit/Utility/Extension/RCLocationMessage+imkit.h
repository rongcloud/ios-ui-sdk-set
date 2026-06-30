//
//  RCLocationMessage+imkit.h
//  RongIMKit
//
//  Created by chinaspx on 2022/7/7.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#ifndef RCLocationMessage_imkit_h
#define RCLocationMessage_imkit_h

@interface RCLocationMessage : RCMessageContent <NSCoding>

@property (nonatomic, copy) NSString *locationName;
@property (nonatomic, assign, readonly) double latitude;
@property (nonatomic, assign, readonly) double longitude;

+ (instancetype)messageWithLocationImage:(UIImage *)image
                                location:(CLLocationCoordinate2D)location
                            locationName:(NSString *)locationName;

@end

#endif /* RCLocationMessage_imkit_h */
