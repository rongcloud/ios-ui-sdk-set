//
//  RCNaviDataManager+sight.h
//  RongSight
//
//  Created by 张改红 on 2020/12/23.
//  Copyright © 2020 RongCloud. All rights reserved.
//

#ifndef RCNaviDataManager_sight_h
#define RCNaviDataManager_sight_h

@interface RCNaviDataInfo : NSObject

@property (nonatomic, assign) NSTimeInterval uploadVideoDurationLimit;

@end

@interface RCNaviDataManager : NSObject

@property (nonatomic, readonly, strong) RCNaviDataInfo *naviData;

+ (instancetype)sharedInstance;

@end

#endif /* RCNaviDataManager_sight_h */
