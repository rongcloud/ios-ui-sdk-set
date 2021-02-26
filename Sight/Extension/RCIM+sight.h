//
//  RCIM+sight.h
//  RongSight
//
//  Created by 张改红 on 2020/12/23.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#ifndef RCIM_sight_h
#define RCIM_sight_h
@interface RCIM : NSObject
+ (instancetype)sharedRCIM;
@property (nonatomic, assign) NSUInteger sightRecordMaxDuration;
@end

#endif /* RCIM_sight_h */
