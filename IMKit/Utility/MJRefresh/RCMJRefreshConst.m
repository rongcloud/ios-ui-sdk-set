//  代码地址: https://github.com/CoderMJLee/RCMJRefresh
//  代码地址:
//  http://code4app.com/ios/%E5%BF%AB%E9%80%9F%E9%9B%86%E6%88%90%E4%B8%8B%E6%8B%89%E4%B8%8A%E6%8B%89%E5%88%B7%E6%96%B0/52326ce26803fabc46000000
#import <UIKit/UIKit.h>

const CGFloat RCMJRefreshLabelLeftInset = 25;
const CGFloat RCMJRefreshHeaderHeight = 54.0;
const CGFloat RCMJRefreshFooterHeight = 44.0;
const CGFloat RCMJRefreshFastAnimationDuration = 0.25;
const CGFloat RCMJRefreshSlowAnimationDuration = 0.4;

NSString *const RCMJRefreshKeyPathContentOffset = @"contentOffset";
NSString *const RCMJRefreshKeyPathContentInset = @"contentInset";
NSString *const RCMJRefreshKeyPathContentSize = @"contentSize";
NSString *const RCMJRefreshKeyPathPanState = @"state";

NSString *const RCMJRefreshHeaderLastUpdatedTimeKey = @"RCMJRefreshHeaderLastUpdatedTimeKey";

NSString *const RCMJRefreshHeaderIdleText = @"RCMJRefreshHeaderIdleText";
NSString *const RCMJRefreshHeaderPullingText = @"RCMJRefreshHeaderPullingText";
NSString *const RCMJRefreshHeaderRefreshingText = @"RCMJRefreshHeaderRefreshingText";

NSString *const RCMJRefreshAutoFooterIdleText = @"RCMJRefreshAutoFooterIdleText";
NSString *const RCMJRefreshAutoFooterRefreshingText = @"RCMJRefreshAutoFooterRefreshingText";
NSString *const RCMJRefreshAutoFooterNoMoreDataText = @"RCMJRefreshAutoFooterNoMoreDataText";

NSString *const RCMJRefreshBackFooterIdleText = @"RCMJRefreshBackFooterIdleText";
NSString *const RCMJRefreshBackFooterPullingText = @"RCMJRefreshBackFooterPullingText";
NSString *const RCMJRefreshBackFooterRefreshingText = @"RCMJRefreshBackFooterRefreshingText";
NSString *const RCMJRefreshBackFooterNoMoreDataText = @"RCMJRefreshBackFooterNoMoreDataText";

NSString *const RCMJRefreshHeaderLastTimeText = @"RCMJRefreshHeaderLastTimeText";
NSString *const RCMJRefreshHeaderDateTodayText = @"RCMJRefreshHeaderDateTodayText";
NSString *const RCMJRefreshHeaderNoneLastDateText = @"RCMJRefreshHeaderNoneLastDateText";
