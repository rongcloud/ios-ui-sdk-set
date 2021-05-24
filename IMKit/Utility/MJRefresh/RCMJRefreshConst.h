//  代码地址: https://github.com/CoderMJLee/RCMJRefresh
//  代码地址:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
#import <UIKit/UIKit.h>
#import <objc/message.h>

// 弱引用
#define MJWeakSelf __weak typeof(self) weakSelf = self;

// 日志输出
#ifdef DEBUG
#define RCMJRefreshLog(...) NSLog(__VA_ARGS__)
#else
#define RCMJRefreshLog(...)
#endif

// 过期提醒
#define RCMJRefreshDeprecated(instead) NS_DEPRECATED(2_0, 2_0, 2_0, 2_0, instead)

// 运行时objc_msgSend
#define RCMJRefreshMsgSend(...) ((void (*)(void *, SEL, UIView *))objc_msgSend)(__VA_ARGS__)
#define RCMJRefreshMsgTarget(target) (__bridge void *)(target)

// RGB颜色
#define RCMJRefreshColor(r, g, b) [UIColor colorWithRed:(r) / 255.0 green:(g) / 255.0 blue:(b) / 255.0 alpha:1.0]

// 文字颜色
#define RCMJRefreshLabelTextColor RCMJRefreshColor(90, 90, 90)

// 字体大小
#define RCMJRefreshLabelFont [UIFont boldSystemFontOfSize:14]

// 常量
UIKIT_EXTERN const CGFloat RCMJRefreshLabelLeftInset;
UIKIT_EXTERN const CGFloat RCMJRefreshHeaderHeight;
UIKIT_EXTERN const CGFloat RCMJRefreshFooterHeight;
UIKIT_EXTERN const CGFloat RCMJRefreshFastAnimationDuration;
UIKIT_EXTERN const CGFloat RCMJRefreshSlowAnimationDuration;

UIKIT_EXTERN NSString *const RCMJRefreshKeyPathContentOffset;
UIKIT_EXTERN NSString *const RCMJRefreshKeyPathContentSize;
UIKIT_EXTERN NSString *const RCMJRefreshKeyPathContentInset;
UIKIT_EXTERN NSString *const RCMJRefreshKeyPathPanState;

UIKIT_EXTERN NSString *const RCMJRefreshHeaderLastUpdatedTimeKey;

UIKIT_EXTERN NSString *const RCMJRefreshHeaderIdleText;
UIKIT_EXTERN NSString *const RCMJRefreshHeaderPullingText;
UIKIT_EXTERN NSString *const RCMJRefreshHeaderRefreshingText;

UIKIT_EXTERN NSString *const RCMJRefreshAutoFooterIdleText;
UIKIT_EXTERN NSString *const RCMJRefreshAutoFooterRefreshingText;
UIKIT_EXTERN NSString *const RCMJRefreshAutoFooterNoMoreDataText;

UIKIT_EXTERN NSString *const RCMJRefreshBackFooterIdleText;
UIKIT_EXTERN NSString *const RCMJRefreshBackFooterPullingText;
UIKIT_EXTERN NSString *const RCMJRefreshBackFooterRefreshingText;
UIKIT_EXTERN NSString *const RCMJRefreshBackFooterNoMoreDataText;

UIKIT_EXTERN NSString *const RCMJRefreshHeaderLastTimeText;
UIKIT_EXTERN NSString *const RCMJRefreshHeaderDateTodayText;
UIKIT_EXTERN NSString *const RCMJRefreshHeaderNoneLastDateText;

// 状态检查
#define RCMJRefreshCheckState                                                                                          \
    RCMJRefreshState oldState = self.state;                                                                            \
    if (state == oldState)                                                                                             \
        return;                                                                                                        \
    [super setState:state];

// 异步主线程执行，不强持有Self
#define RCMJRefreshDispatchAsyncOnMainQueue(x)                                                                         \
    __weak typeof(self) weakSelf = self;                                                                               \
    dispatch_async(dispatch_get_main_queue(), ^{                                                                       \
        typeof(weakSelf) self = weakSelf;                                                                              \
        { x }                                                                                                          \
    });
