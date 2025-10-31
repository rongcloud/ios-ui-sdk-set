# 消息阅读状态详情页使用说明

## 概述

`RCReadReceiptDetailViewController` 是一个用于显示消息阅读状态详情的页面，支持查看已读和未读用户列表。

## 功能特性

✅ 顶部可配置的消息显示区域  
✅ 已读/未读 Tab 切换  
✅ 已读列表显示阅读时间  
✅ 未读列表不显示时间  
✅ 自动分页加载  
✅ 支持自定义样式配置  

## 文件结构

```
RRS/
├── RCReadReceiptDetailViewController.h/m      # 主控制器
├── RCReadReceiptDetailConfig.h/m              # 配置类
├── RCReadReceiptDetailTabView.h/m             # Tab 切换视图
└── RCReadReceiptDetailUserCell.h/m            # 用户信息 Cell
```

## 快速开始

### 1. 基础用法

```objc
#import "RCReadReceiptDetailViewController.h"

// 创建控制器
RCReadReceiptDetailViewController *detailVC = 
    [[RCReadReceiptDetailViewController alloc] initWithMessageModel:messageModel config:nil];

// 显示
[self.navigationController pushViewController:detailVC animated:YES];
```

### 2. 自定义配置

```objc
// 创建配置
RCReadReceiptDetailConfig *config = [[RCReadReceiptDetailConfig alloc] init];

// 配置顶部消息视图
UIView *messageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 120)];
// ... 自定义消息视图内容
config.messageView = messageView;
config.messageViewHeight = 120;

// 配置 Tab 样式
config.selectedColor = [UIColor systemBlueColor];
config.unselectedColor = [UIColor grayColor];
config.readTabTitle = @"已读";
config.unreadTabTitle = @"未读";

// 配置分页大小
config.pageSize = 30;

// 创建控制器
RCReadReceiptDetailViewController *detailVC = 
    [[RCReadReceiptDetailViewController alloc] initWithMessageModel:messageModel config:config];

[self.navigationController pushViewController:detailVC animated:YES];
```

### 3. 自定义消息显示视图示例

```objc
- (UIView *)createMessageViewForModel:(RCMessageModel *)model {
    UIView *messageView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 100)];
    messageView.backgroundColor = [UIColor whiteColor];
    
    // 添加消息内容
    UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, 
                                                                       messageView.bounds.size.width - 30, 60)];
    contentLabel.numberOfLines = 0;
    contentLabel.font = [UIFont systemFontOfSize:15];
    contentLabel.text = [model messageContent];  // 获取消息内容
    [messageView addSubview:contentLabel];
    
    // 添加分隔线
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 99.5, 
                                                                  messageView.bounds.size.width, 0.5)];
    separator.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    [messageView addSubview:separator];
    
    return messageView;
}
```

## API 文档

### RCReadReceiptDetailViewController

#### 初始化

```objc
- (instancetype)initWithMessageModel:(RCMessageModel *)messageModel 
                              config:(nullable RCReadReceiptDetailConfig *)config;
```

**参数**：
- `messageModel`: 消息模型，必须包含 `readReceiptInfoV5` 信息
- `config`: 配置对象，传 `nil` 使用默认配置

#### 属性

```objc
@property (nonatomic, strong, readonly) RCMessageModel *messageModel;  // 消息模型
@property (nonatomic, strong, readonly) RCReadReceiptDetailConfig *config;  // 配置
```

---

### RCReadReceiptDetailConfig

#### 配置项

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `messageView` | UIView | nil | 顶部消息显示视图 |
| `messageViewHeight` | CGFloat | 100 | 顶部视图高度 |
| `tabHeight` | CGFloat | 44 | Tab 高度 |
| `readTabTitle` | NSString | "已读" | 已读 Tab 标题 |
| `unreadTabTitle` | NSString | "未读" | 未读 Tab 标题 |
| `selectedColor` | UIColor | systemBlue | 选中颜色 |
| `unselectedColor` | UIColor | gray | 未选中颜色 |
| `pageSize` | NSInteger | 20 | 分页大小 |

---

### RCReadReceiptDetailTabView

#### 初始化

```objc
- (instancetype)initWithFrame:(CGRect)frame
                    readCount:(NSInteger)readCount
                  unreadCount:(NSInteger)unreadCount
                selectedColor:(UIColor *)selectedColor
              unselectedColor:(UIColor *)unselectedColor;
```

#### 代理方法

```objc
@protocol RCReadReceiptDetailTabViewDelegate <NSObject>

/// Tab 切换回调
- (void)tabView:(RCReadReceiptDetailTabView *)tabView 
didSelectTabAtIndex:(RCReadReceiptDetailTabType)tabType;

@end
```

---

### RCReadReceiptDetailUserCell

#### 配置方法

```objc
- (void)configureWithUserInfo:(RCUserInfo *)userInfo readTime:(long long)readTime;
```

**参数**：
- `userInfo`: 用户信息
- `readTime`: 已读时间（未读时传 0）

#### Cell 标识

```objc
+ (NSString *)reuseIdentifier;  // 返回 Cell 重用标识
```

---

## 数据流程

```
1. 用户进入页面
   ↓
2. 从 messageModel.readReceiptInfoV5 获取已读/未读数量
   ↓
3. 显示 Tab (已读 N / 未读 M)
   ↓
4. 默认显示已读列表，调用 getMessagesReadReceiptUsersByPageV5 接口
   ↓
5. 加载用户列表（RCUserInfo + readTime）
   ↓
6. 显示在列表中
   ↓
7. 滚动到底部自动加载下一页
   ↓
8. 切换 Tab 重复 4-7 步骤
```

## 时间格式化

已读时间显示格式：
- **今天**: `HH:mm`（如：14:30）
- **昨天**: `昨天 HH:mm`（如：昨天 09:15）
- **今年**: `MM-dd HH:mm`（如：10-15 18:20）
- **往年**: `yyyy-MM-dd HH:mm`（如：2024-10-15 18:20）

## 分页逻辑

- 默认每页加载 20 条（可配置）
- 滚动到倒数第 3 行时自动触发下一页加载
- 已读和未读列表独立分页
- 无更多数据时停止加载

## 注意事项

1. ⚠️ **必须条件**: `messageModel` 必须包含有效的 `readReceiptInfoV5` 对象
2. ⚠️ **网络请求**: 页面会自动调用 SDK 接口获取用户列表
3. ⚠️ **头像加载**: 当前示例未实现图片加载，需要集成图片库（如 SDWebImage）
4. ⚠️ **用户信息**: 如果 SDK 返回的 `RCUserInfo` 缺少用户名，会显示 userId

## 扩展建议

### 1. 添加图片加载

```objc
// 在 RCReadReceiptDetailUserCell.m 中
#import <SDWebImage/SDWebImage.h>

- (void)configureWithUserInfo:(RCUserInfo *)userInfo readTime:(long long)readTime {
    // ...
    
    if (userInfo.portraitUri.length > 0) {
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:userInfo.portraitUri]
                                placeholderImage:[self placeholderImage]];
    }
}

- (UIImage *)placeholderImage {
    // 返回默认头像
}
```

### 2. 添加空状态视图

```objc
// 在 RCReadReceiptDetailViewController.m 中
- (void)showEmptyView {
    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.text = @"暂无数据";
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.textColor = [UIColor grayColor];
    self.tableView.backgroundView = emptyLabel;
}
```

### 3. 添加下拉刷新

```objc
#import <MJRefresh/MJRefresh.h>

- (void)setupRefreshControl {
    __weak typeof(self) weakSelf = self;
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakSelf refreshData];
    }];
}

- (void)refreshData {
    // 重置分页
    self.currentReadPage = 1;
    [self.readUserList removeAllObjects];
    [self.readTimeList removeAllObjects];
    
    // 重新加载
    [self loadReadUsers];
    [self.tableView.mj_header endRefreshing];
}
```

## 示例代码

完整的使用示例：

```objc
#import "RCReadReceiptDetailViewController.h"

- (void)showReadReceiptDetailForMessage:(RCMessageModel *)messageModel {
    // 检查是否有 V5 已读回执信息
    if (!messageModel.readReceiptInfoV5) {
        NSLog(@"消息没有已读回执信息");
        return;
    }
    
    // 创建配置
    RCReadReceiptDetailConfig *config = [[RCReadReceiptDetailConfig alloc] init];
    
    // 创建自定义消息视图
    UIView *messageView = [self createMessageViewForModel:messageModel];
    config.messageView = messageView;
    config.messageViewHeight = 120;
    
    // 自定义样式
    config.selectedColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    config.unselectedColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    
    // 创建并显示控制器
    RCReadReceiptDetailViewController *detailVC = 
        [[RCReadReceiptDetailViewController alloc] initWithMessageModel:messageModel config:config];
    
    [self.navigationController pushViewController:detailVC animated:YES];
}
```

## 常见问题

### Q: 如何获取 messageModel 的 readReceiptInfoV5？

A: 在发送消息时设置 `needReceipt = YES`，SDK 会自动维护 `readReceiptInfoV5` 信息。

### Q: 用户头像不显示？

A: 需要集成图片加载库（如 SDWebImage），参考"扩展建议"章节。

### Q: 如何自定义 Cell 样式？

A: 可以继承 `RCReadReceiptDetailUserCell` 并重写 `setupUI` 方法，或者创建新的 Cell 类并在控制器中注册。

### Q: 分页加载失败怎么办？

A: 检查网络连接和 SDK 初始化状态，可以在 `completion` 回调中添加错误处理。

## 性能优化

1. ✅ 使用 Cell 复用机制
2. ✅ 分页加载数据，避免一次性加载过多
3. ✅ 图片异步加载（需要集成图片库）
4. ✅ 提前 3 行触发分页，优化用户体验

## 更新日志

### v1.0.0 (2025-10-15)
- ✨ 初始版本
- ✨ 支持已读/未读列表切换
- ✨ 支持分页加载
- ✨ 支持自定义配置

---

**作者**: Lang  
**日期**: 2025-10-15  
**SDK 版本**: 5.x+

