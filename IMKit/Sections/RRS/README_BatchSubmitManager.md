# 批量提交管理器 (RCBatchSubmitManager)

## 概述

`RCBatchSubmitManager` 是一个通用的批量提交管理器，用于将高频调用的操作进行批量处理，减少网络请求次数。在 RRS V5 已读回执场景中，它用于优化消息曝光时的已读回执响应。

## 功能特性

1. **防抖动**：在指定延迟时间内的多次调用会被合并成一次提交
2. **状态机管理**：使用清晰的状态转换避免竞态条件
   - IDLE（空闲状态）：没有待处理数据，没有安排任务
   - ACTIVE（活跃状态）：有待处理数据或正在处理中
3. **线程安全**：使用统一的状态锁确保多线程安全
4. **自动去重**：使用 NSSet 存储待处理项，自动去除重复数据

## 使用场景

### RRS V5 已读回执响应

在消息列表快速滚动时，会频繁触发 cell 的曝光事件。如果每次曝光都立即调用 `sendReadReceiptResponseV5` 接口，会产生大量网络请求。使用 `RCBatchSubmitManager` 可以将这些请求批量合并，在指定延迟后统一提交。

## 实现原理

### 参考设计

iOS 实现参考了 Android 的 `BatchSubmitManager.java`，保持了以下一致的设计：

```
Java (Android)                    Objective-C (iOS)
-------------------------         -------------------------
BatchSubmitManager<T>      →      RCBatchSubmitManager
SubmitState enum           →      RCSubmitState enum
Handler                    →      performSelector:withObject:afterDelay:
HashSet<T>                 →      NSMutableSet
synchronized               →      @synchronized
```

### 工作流程

1. **添加任务**：
   ```
   [manager addSubmitTask:messageUId]
   ```
   - 将 messageUId 添加到待处理集合
   - 如果当前状态是 IDLE，安排延迟任务并切换到 ACTIVE 状态
   - 如果当前状态是 ACTIVE，只添加到集合（利用现有的延迟任务）

2. **延迟执行**（默认 100ms）：
   - 时间到后，复制待处理集合并清空
   - 调用批量提交回调，传入所有待提交的项
   - 保持 ACTIVE 状态等待回调结果

3. **提交完成**：
   - 如果没有新数据，切换到 IDLE 状态
   - 如果有新数据（在处理期间又添加了新任务），安排下一轮延迟提交

## 使用示例

### 基本使用

```objective-c
// 1. 创建管理器
RCBatchSubmitManager *manager = [[RCBatchSubmitManager alloc] init];

// 2. 设置批量提交回调
[manager setSubmitCallback:^(NSArray *items, RCBatchSubmitResultCallback resultCallback) {
    // 执行批量操作
    [YourService batchProcess:items completion:^(NSInteger code) {
        // 通知管理器操作完成
        if (resultCallback) {
            resultCallback(code);
        }
    }];
}];

// 3. 添加任务（高频调用）
for (NSString *item in itemsArray) {
    [manager addSubmitTask:item];
}

// 4. 清理（页面退出时）
[manager cleanup];
```

### RCConversationViewController 中的实际应用

```objective-c
// 初始化（在 rcinit 中）
- (void)setupReadReceiptBatchManager {
    self.readReceiptBatchManager = [[RCBatchSubmitManager alloc] init];
    __weak typeof(self) weakSelf = self;
    [self.readReceiptBatchManager setSubmitCallback:^(NSArray *items, RCBatchSubmitResultCallback resultCallback) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            if (resultCallback) {
                resultCallback(-1);
            }
            return;
        }
        
        NSArray *messageUIds = items;
        if (messageUIds.count == 0) {
            if (resultCallback) {
                resultCallback(0);
            }
            return;
        }
        
        RCConversationIdentifier *identifier = [RCConversationIdentifier new];
        identifier.type = strongSelf.conversationType;
        identifier.targetId = strongSelf.targetId;
        identifier.channelId = strongSelf.channelId;
        
        [[RCCoreClient sharedCoreClient] sendReadReceiptResponseV5:identifier
                                                       messageUIds:messageUIds
                                                        completion:^(RCErrorCode code) {
            if (resultCallback) {
                resultCallback(code);
            }
        }];
    }];
}

// Cell 曝光时添加任务
- (void)collectionView:(UICollectionView *)collectionView 
       willDisplayCell:(UICollectionViewCell *)cell 
    forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= self.conversationDataRepository.count) {
        return;
    }
    
    RCMessageModel *model = [self.conversationDataRepository objectAtIndex:indexPath.row];
    if ([model rrs_shouldResponseReadReceiptV5] && model.messageUId) {
        // 使用批量管理器处理已读回执 V5 响应
        [self.readReceiptBatchManager addSubmitTask:model.messageUId];
    }
}

// 页面退出时清理
- (void)quitConversationViewAndClear {
    // ... 其他清理逻辑 ...
    
    // 清理批量提交管理器
    [self.readReceiptBatchManager cleanup];
}
```

## 配置选项

### 自定义延迟时间

默认延迟时间为 100ms，可以根据需要调整：

```objective-c
// 设置延迟时间为 200ms
[manager setDelayMs:200];
```

## 性能优化

### 场景分析

假设用户快速滚动消息列表，在 1 秒内曝光了 50 条消息：

**不使用批量管理器**：
- 发起 50 次网络请求
- 每次请求都有网络开销和服务器处理成本

**使用批量管理器（100ms 延迟）**：
- 快速滚动过程中，所有曝光的 messageUId 都被添加到待处理集合
- 滚动停止后 100ms，触发一次批量提交
- 只发起 1 次网络请求，包含所有 50 个 messageUId
- **请求次数减少 98%**

### 性能优势

1. **减少网络请求次数**：合并多次调用为一次批量请求
2. **降低服务器压力**：减少服务器处理次数
3. **节省流量**：减少重复的 HTTP 头和握手开销
4. **自动去重**：避免对同一消息的重复处理

## 注意事项

1. **Callback 必须调用**：
   - 批量提交回调中必须调用 `resultCallback`，否则状态机无法正确转换
   - 即使操作失败，也应该调用 `resultCallback` 通知管理器

2. **内存管理**：
   - 页面退出时必须调用 `cleanup` 方法
   - `cleanup` 会取消所有待处理任务并清空队列

3. **线程安全**：
   - 管理器内部使用 `@synchronized` 保证线程安全
   - 可以在任何线程调用 `addSubmitTask:`

4. **数据去重**：
   - 使用 `NSSet` 存储待处理项，自动去重
   - 相同的 messageUId 只会被提交一次

## 状态机

```
IDLE (空闲)
  │
  │ addSubmitTask (第一个任务)
  │
  ↓
ACTIVE (活跃) ───┐
  ↑             │
  │             │ executeBatchSubmit
  │             │ (提交完成，有新数据)
  │             │
  └─────────────┘
  
  │ executeBatchSubmit
  │ (提交完成，无新数据)
  ↓
IDLE (空闲)
```

## 与 Android 实现的对比

| 特性 | Android | iOS |
|------|---------|-----|
| 语言 | Java | Objective-C |
| 泛型支持 | `<T>` | 使用 `id` 类型 |
| 线程安全 | `synchronized (mStateLock)` | `@synchronized (stateLock)` |
| 延迟执行 | `Handler.postDelayed` | `performSelector:withObject:afterDelay:` |
| 集合类型 | `HashSet<T>` | `NSMutableSet` |
| 状态机 | `enum SubmitState` | `typedef NS_ENUM` |
| 日志 | `RLog` | `NSLog` |

## 扩展性

`RCBatchSubmitManager` 是一个通用的批量提交管理器，除了 RRS V5 已读回执，还可以用于其他需要批量处理的场景：

- 批量上报埋点事件
- 批量同步数据状态
- 批量上传日志
- 其他高频操作的批量处理

只需要设置不同的 `submitCallback` 即可适配不同的业务场景。

