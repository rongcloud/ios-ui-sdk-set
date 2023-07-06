//
//  RCIMNotificationDataContext.m
//  RongIMLibCore
//
//  Created by RobinCui on 2022/4/18.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCIMNotificationDataContext.h"
#import "RCIMThreadLock.h"

NSString *const RCIMNotificationDataContextGlobalNotificationLevel = @"RCIMNotificationDataContextGlobalNotificationLevel";

NSString *const RCIMNotificationDataContextNotificationLevelUpdate = @"RCIMNotificationDataContextNotificationLevelUpdate";

NSString *const RCIMNotificationDataContextNotificationType = @"type";
NSString *const RCIMNotificationDataContextNotificationTargetID = @"targetId";
NSString *const RCIMNotificationDataContextNotificationChannelID = @"channelId";
NSString *const RCIMNotificationDataContextNotificationLevel = @"level";
NSString *const RCIMNotificationDataContextNotificationTime = @"time";
NSString *const RCIMNotificationDataContextNotificationDuration = @"duration";

typedef NS_ENUM(NSInteger,RCPushNotificationLevelStrategy) {
    RCPushNotificationLevelStrategyNone,
    RCPushNotificationLevelStrategyCategory,
    RCPushNotificationLevelStrategyTarget,
    RCPushNotificationLevelStrategyChannel,
    RCPushNotificationLevelStrategyGlobal
};

static void *_notificationWorkQueueTag = &_notificationWorkQueueTag;

@interface RCIMNotificationDataContext()
@property (nonatomic, strong) NSMutableDictionary *notificationInfo;
@property (nonatomic, strong) dispatch_queue_t notificationWorkQueue;

@property (nonatomic, strong) NSDateFormatter *formatter;
@property (nonatomic, strong) NSDate *dateBegin;
@property (nonatomic, strong) NSDate *dateEnd;
@property (nonatomic, strong) RCIMThreadLock *threadLock;
@end

static RCIMNotificationDataContext *_instance = nil;
static dispatch_once_t onceToken;
@implementation RCIMNotificationDataContext

+ (instancetype)sharedInstence {
    
    dispatch_once(&onceToken, ^{
        _instance = [[RCIMNotificationDataContext alloc] init];
    });
    return _instance;;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.notificationInfo = [NSMutableDictionary dictionary];
        self.notificationWorkQueue =  dispatch_queue_create("cn.rongcloud.notificationWorkQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(self.notificationWorkQueue, _notificationWorkQueueTag, _notificationWorkQueueTag, NULL);
        self.threadLock = [RCIMThreadLock new];
        [self registerObservers];
    }
    return self;
}
#pragma mark -- Public

/// 依据会话列表更新缓存
/// @param conversations 会话列表
+ (void)updateNotificationLevelWith:(NSArray<RCConversation *> *)conversations {
    RCDLog(@"%lu 个会话", (unsigned long)conversations.count)
    RCIMNotificationDataContext *context = [self currentDataContext];
    [context performOperationQueueBlock:^{
        if (conversations.count) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionary];
            for (RCConversation *conversation in conversations) {
                NSString *key = [self keyStringWith:conversation.conversationType
                                           targetId:conversation.targetId
                                          channelId:conversation.channelId];
                dic[key] = @(conversation.notificationLevel);
            }
            RCIMNotificationDataContext *context = [self currentDataContext];
            [context.threadLock performWriteLockBlock:^{
                [context.notificationInfo addEntriesFromDictionary:dic];
                RCDLog(@"更新后的缓存数据: %@", [context.notificationInfo description])
            }];
        }
    }];
}

/// 获取level
/// @param type 会话类型
/// @param targetId 会话ID
/// @param channelId 频道ID
/// @param successBlock c成功回调
/// @param errorBlock 失败回调
+ (void)queryNotificationLevelWith:(RCConversationType)type
                          targetId:(NSString *__nullable)targetId
                         channelId:(NSString *__nullable )channelId
                        completion:(void (^)(RCPushNotificationLevel level))completion {
    RCIMNotificationDataContext *context = [self currentDataContext];
    [context performOperationQueueBlock:^{
        // 先从global开始查询
        RCDLog(@"即将开始查询 全局设置")
        [self queryGlobalNotificationLevel:^(RCPushNotificationQuietHoursLevel level) {
            if (level == RCPushNotificationQuietHoursLevelDefault) {// 如果全局为默认level, 则进入下一级查询
                RCDLog(@"全局设置: %ld,  即将查询其他配置", (long)level)
                [self queryCommonNotificationLevelWith:type
                                              targetId:targetId
                                             channelId:channelId
                                            completion:completion];
                
            } else if(completion) {// 全局level 不是default 直接上报
                RCDLog(@"上报全局设置: %ld", (long)level)
                completion((RCPushNotificationLevel)level);
            }
        }];
    }];
}

+ (void)destroy {
    onceToken = 0;
    _instance = nil;
}

+ (void)clean  {
    RCIMNotificationDataContext *context = [self currentDataContext];
    [context clean];
}

- (void)clean {
    [self performOperationQueueBlock:^{
        [self.threadLock performWriteLockBlock:^{
            [self.notificationInfo removeAllObjects];
            self.dateBegin = nil;
            self.dateEnd = nil;
            RCDLog(@"清理后的缓存数据: %@", [self.notificationInfo description])
        }];
    }];
}
#pragma mark -- Private

/// 查询全局
/// @param successBlock successBlock
/// @param errorBlock errorBlock
+ (void)queryGlobalNotificationLevel:(void (^)(RCPushNotificationQuietHoursLevel level))completion {
    RCDLog(@"开始全局查询-> ");
    
    RCIMNotificationDataContext *context = [self currentDataContext];
    RCPushNotificationQuietHoursLevel level = RCPushNotificationQuietHoursLevelDefault;
    __block NSNumber *levelNumber = @(RCPushNotificationQuietHoursLevelDefault);
    __block NSDate *dateBegin = nil;
    __block NSDate *dateEnd = nil;
    [context.threadLock performReadLockBlock:^{
        dateBegin = context.dateBegin;
        dateEnd = context.dateEnd;
        levelNumber = context.notificationInfo[RCIMNotificationDataContextGlobalNotificationLevel];
    }];
    
    if (!dateBegin || !dateEnd) { // 全局已没有有效时间
        if (completion) {
            RCDLog(@"全局查询结束->时间无效, level: %ld", (long)level);
            completion(level);
        }
        return;
    }
    NSDate *date = [NSDate date];
    NSTimeInterval current = [date timeIntervalSince1970];
    NSTimeInterval timeBegin = [dateBegin timeIntervalSince1970];
    NSTimeInterval timeEnd = [dateEnd timeIntervalSince1970];
    
    if (timeEnd < current) {// 时间已过期
        [self updateGlobalNotificationLevelWith:nil
                                        dateEnd:nil
                                          level:RCPushNotificationQuietHoursLevelDefault];
        if (completion) {
            RCDLog(@"全局查询结束->时间过期,dateEnd: %@, current :%@ ,level: %ld",[dateEnd description], [date description], (long)level);
            completion(level);
        }
        return;
    }
    
    if (timeBegin > current) { //未到免打扰开始时间
        if (completion) {
            RCDLog(@"全局查询结束->时间未到,dateBegin: %@, current :%@ ,level: %ld",[dateBegin description], [date description], (long)level);
            completion(level);
        }
        return;
    }
    
    
    if (levelNumber) {
        level = (RCPushNotificationQuietHoursLevel)[levelNumber integerValue];
        RCDLog(@"全局查询结束->有缓存,level: %ld", (long)level);
        
        if (completion) {
            completion(level);
        }
    } else {
        RCDLog(@"全局查询结束->没有缓存, 开始查询数据库");
        
        [self queryGlobalNotificationLevelInDB:^(NSString *startTime, int spanMins, RCPushNotificationQuietHoursLevel level) {
            RCDLog(@"全局查询结束->没有缓存, 查询数据库成功, level: %ld", (long)level);
            
            [self updateGlobalNotificationLevelWith:startTime duration:spanMins level:level];
            if (completion) {
                completion(level);
            }
        } error:^(RCErrorCode status) {
            RCDLog(@"全局查询结束->没有缓存, 查询数据库失败");
            if (completion) {
                completion(level);
            }
        }];
    }
}


/// 移除全局等级
+ (void)removeGlobalNotification {
    RCIMNotificationDataContext *context = [self currentDataContext];
    [context.threadLock performWriteLockBlock:^{
        context.notificationInfo[RCIMNotificationDataContextGlobalNotificationLevel] = nil;
        context.dateEnd = nil;
        context.dateEnd = nil;
    }];
}

/// 获取非 Global 的level
/// @param type 会话类型
/// @param targetId 会话ID
/// @param channelId 频道ID
/// @param successBlock c成功回调
/// @param errorBlock 失败回调
+ (void)queryCommonNotificationLevelWith:(RCConversationType)type
                                targetId:(NSString *__nullable)targetId
                               channelId:(NSString *__nullable )channelId
                              completion:(void (^)(RCPushNotificationLevel level))completion {
    RCPushNotificationLevelStrategy strategy = RCPushNotificationLevelStrategyChannel;
    if ([self isStringEmpty:channelId]) { // 如果channelID 为空, 就从 target 开始查
        strategy = RCPushNotificationLevelStrategyTarget;
    }
    if ([self isStringEmpty:targetId]) { // 如果targetID 为空, 就从category开始查
        strategy = RCPushNotificationLevelStrategyCategory;
    }
    
    RCDLog(@"开始通用查询-> type:%ld, targetId:%@ ,channel: %@ , strategy: %ld", (long)type, targetId, channelId, (long)strategy);
    [self queryNotificationLevelWith:type
                            targetId:targetId
                           channelId:channelId
                            strategy:strategy
                       previousLevel:RCPushNotificationLevelDefault
                          completion:completion];
    
}

/// 获取level
/// @param type 会话类型
/// @param targetId 会话ID
/// @param channelId 频道ID
/// @param strategy 遍历策略
/// @param previousLevel 上次的查询结果
/// @param successBlock 成功回调
/// @param errorBlock 失败回调
+ (void)queryNotificationLevelWith:(RCConversationType)type
                          targetId:(NSString *__nullable)targetId
                         channelId:(NSString *__nullable )channelId
                          strategy:(RCPushNotificationLevelStrategy)strategy
                     previousLevel:(RCPushNotificationLevel)previousLevel
                        completion:(void (^)(RCPushNotificationLevel level))completion {
    // 如果已经遍历完全部策略, 或者上次的level不是default
    if (strategy == RCPushNotificationLevelStrategyNone ||
        previousLevel != RCPushNotificationLevelDefault) { // 递归遍历结束
        RCDLog(@"通用查询结束, 上报-> type:%ld, targetId:%@ ,channel: %@ , stratege: %ld, previousLevel: %ld", (long)type, targetId, channelId, strategy, (long)previousLevel);
        if (completion) {
            completion(previousLevel);
            return;
        }
    }
    if (strategy == RCPushNotificationLevelStrategyTarget) {
        channelId = @"";
    } else if(strategy == RCPushNotificationLevelStrategyCategory) {
        channelId = @"";
        targetId = @"";
    }
    
    RCPushNotificationLevelStrategy nextStrategy = strategy-1;//下一个策略
    RCIMNotificationDataContext *context = [self currentDataContext];
    __block RCPushNotificationLevel level = RCPushNotificationLevelDefault;
    __block NSNumber *levelNumber = nil;
    NSString *key = [self keyStringWith:type targetId:targetId channelId:channelId];
    [context.threadLock performReadLockBlock:^{
        levelNumber = [context.notificationInfo objectForKey:key];
        RCDLog(@"通用查询 notificationInfo: %@", [context.notificationInfo description]);
    }];
    
    if (!levelNumber) { // 需要重新查数据库
        RCDLog(@"cache无数据, 开始数据库查询-> type:%ld, targetId:%@ ,channel: %@ , stratege: %ld, ", (long)type, targetId, channelId, (long)strategy);
        
        [self levelInfoInDBWith:type
                       targetId:targetId
                      channelId:channelId
                       strategy:strategy
                        success:^(RCPushNotificationLevel level) {// 如果从数据库查询成功
            [context updateNotificationLevelWith:@(level) byKey:key]; // 保存数据level
            RCDLog(@"cache无数据, 数据库查询结束-> type:%ld, targetId:%@ ,channel: %@ , stratege: %ld, level:%ld ", (long)type, targetId, channelId, (long)strategy, (long)level);
            
            // 进入下一级查询
            [self queryNotificationLevelWith:type
                                    targetId:targetId
                                   channelId:channelId
                                    strategy:nextStrategy
                               previousLevel:level
                                  completion:completion];
        } error:^(RCErrorCode status) {
            RCDLog(@"cache无数据, 数据库查询失败-> type:%ld, targetId:%@ ,channel: %@ , nextStrategy: %ld, level:%ld ", (long)type, targetId, channelId, (long)nextStrategy, (long)level);
            
            // 如果数据库查询失败, 直接进入下一级查询
            [self queryNotificationLevelWith:type
                                    targetId:targetId
                                   channelId:channelId
                                    strategy:nextStrategy
                               previousLevel:previousLevel
                                  completion:completion];
        }];
        
    } else {
        level = (RCPushNotificationLevel)[levelNumber integerValue];
        RCDLog(@"找到cache数据, 进入下级-> type:%ld, targetId:%@ ,channel: %@ , nextStrategy: %ld, level:%ld ", (long)type, targetId, channelId, (long)nextStrategy, (long)level);
        
        // 已查询到level, 进入下一级
        [self queryNotificationLevelWith:type
                                targetId:targetId
                               channelId:channelId
                                strategy:nextStrategy
                           previousLevel:level
                              completion:completion];
    }
}

/// 移除level
/// @param type 会话类型
/// @param targetId 会话ID
/// @param channelId 频道ID
+ (void)removeNotificationLevelWith:(RCConversationType)type
                           targetId:(NSString *__nullable)targetId
                          channelId:(NSString *__nullable )channelId {
    NSString *key = [self keyStringWith:type targetId:targetId channelId:channelId];
    RCIMNotificationDataContext *context = [self currentDataContext];
    [context updateNotificationLevelWith:nil byKey:key];
}

/// 更新全局通知
/// @param timeString 时间戳
/// @param duration 时长
/// @param level 等级
+ (void)updateGlobalNotificationLevelWith:(NSString *__nullable)timeString
                                 duration:(NSTimeInterval)duration
                                    level:(RCPushNotificationQuietHoursLevel)level {
    RCIMNotificationDataContext *context = [self currentDataContext];
    NSString *dateString = [self fullDateStringBy:timeString];
    NSDate *dateBegin = [context.formatter dateFromString:dateString];
    NSDate *dateEnd = [dateBegin dateByAddingTimeInterval:duration*60];
    RCDLog(@"更新全局设置: begin: %@, end: %@, %f, %ld", [dateBegin description],[dateEnd description], duration, (long)level)
    [self updateGlobalNotificationLevelWith:dateBegin dateEnd:dateEnd level:level];
}

/// 更新全局通知
/// @param date 有效时间
/// @param level 等级
+ (void)updateGlobalNotificationLevelWith:(NSDate *)dateBegin
                                  dateEnd:(NSDate *)dateEnd
                                    level:(RCPushNotificationQuietHoursLevel)level {
    RCIMNotificationDataContext *context = [self currentDataContext];
    [context.threadLock performWriteLockBlock:^{
        context.notificationInfo[RCIMNotificationDataContextGlobalNotificationLevel] = @(level);
        context.dateBegin = dateBegin;
        context.dateEnd = dateEnd;
    }];
}


+ (void)refreshGlobalNotificationLevel {
    [self queryGlobalNotificationLevelInDB:^(NSString *startTime, int spanMins, RCPushNotificationQuietHoursLevel level) {
        [self updateGlobalNotificationLevelWith:startTime
                                       duration:spanMins
                                          level:level];
    } error:^(RCErrorCode status) {
        
    }];
}

- (void)registerObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateGlobalNotificationLevel:)
                                                 name:@"RCLibDispatchResetNotificationQuietStatusNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateNotificationLevel:)
                                                 name:RCIMNotificationDataContextNotificationLevelUpdate
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateGlobalNotificationLevel:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/// 更新全局通知设置
/// @param notification 通知
- (void)updateGlobalNotificationLevel:(NSNotification *)notification {
    [[self class] refreshGlobalNotificationLevel];
}

/// 更新普通通知设置
/// @param notification 通知
- (void)updateNotificationLevel:(NSNotification *)notification {
    id obj = notification.object;
    if (obj && [obj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dic = (NSDictionary *)obj;
        NSNumber *type = dic[RCIMNotificationDataContextNotificationType];
        NSString *targetID = dic[RCIMNotificationDataContextNotificationTargetID];
        NSString *channelID = dic[RCIMNotificationDataContextNotificationChannelID];
        NSNumber *level = dic[RCIMNotificationDataContextNotificationLevel];
        if ([type isKindOfClass:[NSNumber class]] &&
            [level isKindOfClass:[NSNumber class]]) {
            NSString *key = [[self class] keyStringWith:[type integerValue]
                                               targetId:targetID
                                              channelId:channelID];
            [self updateNotificationLevelWith:level byKey:key];
        }
    }
}

- (void)dealloc {
    [self removeObservers];
}

+ (void)queryGlobalNotificationLevelInDB:(void(^)(NSString *startTime, int spanMins, RCPushNotificationQuietHoursLevel level))successBlock
                                   error:(void (^)(RCErrorCode status))errorBlock {
    [[RCChannelClient sharedChannelManager] getNotificationQuietHoursLevel:successBlock error:errorBlock];
}

/// 从数据库中重新获取
/// @param type 会话类型
/// @param targetId 会话ID
/// @param channelId 频道ID
/// @param successBlock c成功回调
/// @param errorBlock 失败回调
+ (void)levelInfoInDBWith:(RCConversationType)type
                 targetId:(NSString *__nullable)targetId
                channelId:(NSString *__nullable)channelId
                 strategy:(RCPushNotificationLevelStrategy)strategy
                  success:(void (^)(RCPushNotificationLevel level))successBlock
                    error:(void (^)(RCErrorCode status))errorBlock
{
    if (strategy == RCPushNotificationLevelStrategyCategory) {// 会话类型级别
        [self levelInfoInDBWith:type success:successBlock error:errorBlock];
    } else if (strategy == RCPushNotificationLevelStrategyChannel) { // channel级别
        [self levelInfoInDBWith:type
                       targetId:targetId
                      channelId:channelId
                        success:successBlock
                          error:errorBlock];
    } else if(strategy == RCPushNotificationLevelStrategyTarget) {// 会话级别
        [self levelInfoInDBWith:type
                       targetId:targetId
                      channelId:@""
                        success:successBlock
                          error:errorBlock];
    } else {
        if (successBlock) {
            successBlock(RCPushNotificationLevelDefault);
        }
    }
}
/// 从数据库中重新获取[targetID , channelID, category]
/// @param type 会话类型
/// @param targetId 会话ID
/// @param channelId 频道ID
/// @param successBlock c成功回调
/// @param errorBlock 失败回调
+ (void)levelInfoInDBWith:(RCConversationType)type
                 targetId:(NSString *__nullable)targetId
                channelId:(NSString *__nullable)channelId
                  success:(void (^)(RCPushNotificationLevel level))successBlock
                    error:(void (^)(RCErrorCode status))errorBlock {
    [[RCChannelClient sharedChannelManager] getConversationChannelNotificationLevel:type
                                                                           targetId:targetId
                                                                          channelId:channelId
                                                                            success:successBlock
                                                                              error:errorBlock];
}

/// 从数据库中重新获取会话类型[category]
/// @param type 会话类型
/// @param targetId 会话ID
/// @param channelId 频道ID
/// @param successBlock c成功回调
/// @param errorBlock 失败回调
+ (void)levelInfoInDBWith:(RCConversationType)type
                  success:(void (^)(RCPushNotificationLevel level))successBlock
                    error:(void (^)(RCErrorCode status))errorBlock {
    
    [[RCChannelClient sharedChannelManager] getConversationTypeNotificationLevel:type
                                                                         success:successBlock
                                                                           error:errorBlock];
}

/// 更新本地缓存数据
/// @param level level
/// @param key key
- (void)updateNotificationLevelWith:(NSNumber *__nullable)level byKey:(NSString *)key {
    if (key) {
        [self.threadLock performWriteLockBlock:^{
            self.notificationInfo[key] = level;
            RCDLog(@"更新 notificationInfo: %@", [self.notificationInfo description]);
        }];
        
    }
}

/// 获取数据上下文
+ (RCIMNotificationDataContext *)currentDataContext {
    RCIMNotificationDataContext *context = [RCIMNotificationDataContext sharedInstence];
    return context;
}


/// key字符串
/// @param type 会话类型
/// @param targetId 会话ID
/// @param channelId 频道ID
+ (NSString *)keyStringWith:(RCConversationType)type
                   targetId:(NSString *__nullable)targetId
                  channelId:(NSString *__nullable)channelId {
    targetId = targetId ?: @"";
    channelId = channelId ?: @"";
    NSString *key = [NSString stringWithFormat:@"%lu;;;%@;%@", (unsigned long)type, targetId, channelId];
    return key;
}


/// 判断会话类型合法性
/// @param type 类型
+ (BOOL)IsConversationTypeValid:(RCConversationType)type {
    BOOL result = NO;
    switch (type) {
        case RCPushNotificationLevelAllMessage:
        case RCPushNotificationLevelDefault:
        case RCPushNotificationLevelMention:
        case RCPushNotificationLevelMentionUsers:
        case RCPushNotificationLevelMentionAll:
        case RCPushNotificationLevelBlocked:
            result = YES;
            break;
            
        default:
            break;
    }
    return result;
}

- (void)performOperationQueueBlock:(dispatch_block_t)block {
    if (dispatch_get_specific(_notificationWorkQueueTag)) {
        block();
    }
    else {
        dispatch_async(self.notificationWorkQueue, block);
    }
}
+ (NSString *)fullDateStringBy:(NSString *)time {
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger  unitFlags=NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear;
    NSDateComponents * conponent= [calendar components:unitFlags fromDate:date];
    NSInteger year=[conponent year];
    NSInteger month=[conponent month];
    NSInteger day=[conponent day];
    NSString *dateString= [NSString  stringWithFormat:@"%4ld-%2ld-%2ld",(long)year,(long)month,(long)day];
    NSString *timeString = time?:@"00:00:00";
    return [NSString stringWithFormat:@"%@ %@", dateString, timeString];;
}

- (NSDateFormatter *)formatter {
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
        [_formatter setTimeZone:[NSTimeZone localTimeZone]];
    }
    return _formatter;
}

+ (BOOL)isStringEmpty:(NSString *)string {
    NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
    if (![string isKindOfClass:[NSString class]]) {
        return YES;
    }
    else if (string.length == 0) {
        return YES;
    } else if([[string stringByTrimmingCharactersInSet:set] length] == 0) {
        return YES;
    }
    
    return NO;
}
@end
