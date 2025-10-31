//
//  RCMenuViewController.m
//  PopMenu
//
//  Created by RobinCui on 2025/10/18.
//

#import "RCMenuController.h"
#import "RCMenuView.h"
#import "RCMenuItem.h"
#import "RCKitCommonDefine.h"

// 三角形指示器视图
@interface RCArrowView : UIView
@property (nonatomic, assign) BOOL pointingUp; // YES: 向上指，NO: 向下指
@end

@implementation RCArrowView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *color = RCDynamicColor(@"pop_layer_background_color", @"0x323232", @"0x323232");
    // 设置填充颜色（与菜单背景色一致）
    if (color) {
        [color setFill];
    }
    
    // 绘制三角形
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    CGContextBeginPath(context);
    
    if (self.pointingUp) {
        // 向上的三角形
        CGContextMoveToPoint(context, width / 2, 0);           // 顶点
        CGContextAddLineToPoint(context, 0, height);           // 左下
        CGContextAddLineToPoint(context, width, height);       // 右下
    } else {
        // 向下的三角形
        CGContextMoveToPoint(context, 0, 0);                   // 左上
        CGContextAddLineToPoint(context, width, 0);            // 右上
        CGContextAddLineToPoint(context, width / 2, height);   // 底部顶点
    }
    
    CGContextClosePath(context);
    CGContextFillPath(context);
}

@end

// 菜单容器视图
@interface RCMenuHolderView : UIView
@property (nonatomic, strong) RCMenuView *menuView;
@property (nonatomic, strong) RCArrowView *arrowView;
@property (nonatomic, assign) BOOL arrowPointingUp;
@end

@implementation RCMenuHolderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

@end

@interface RCMenuController ()

@property (nonatomic, assign, readwrite, getter=isMenuVisible) BOOL menuVisible;
@property (nonatomic, strong) UIView *overlayView; // 遮罩视图，用于拦截背景点击
@property (nonatomic, strong) RCMenuHolderView *containerView;
@property (nonatomic, copy) void (^actionHandler)(RCMenuItem *menuItem, NSInteger index);

@end

@implementation RCMenuController

+ (instancetype)sharedMenuController {
    static RCMenuController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _menuVisible = NO;
    }
    return self;
}

- (void)showMenuFromView:(UIView *)targetView
               menuItems:(NSArray<RCMenuItem *> *)menuItems
           actionHandler:(void (^)(RCMenuItem *menuItem, NSInteger index))actionHandler {
    NSMutableArray *items = [NSMutableArray array];
    for (UIMenuItem *item in menuItems) {
        if ([item isKindOfClass:[RCMenuItem class]]) {
            [items addObject:item];
        } else if ([item isKindOfClass:[UIMenuItem class]]) {
            RCMenuItem *obj = [RCMenuItem menuItemWithItem:item];
            if (obj) {
                [items addObject:obj];
            }
           
        }
    }
    [self showMenuFromRect:targetView.bounds
                    inView:targetView
                 menuItems:items
             actionHandler:actionHandler];
}

- (void)showMenuFromRect:(CGRect)targetRect
                  inView:(UIView *)targetView
               menuItems:(NSArray<RCMenuItem *> *)menuItems
           actionHandler:(void (^)(RCMenuItem *menuItem, NSInteger index))actionHandler {
    if (menuItems.count == 0) {
        return;
    }
    
    // 隐藏之前的菜单
    [self hideMenuAnimated:NO];
    
    self.actionHandler = actionHandler;
    
    // 获取当前 window
    UIWindow *currentWindow = targetView.window;
    if (!currentWindow) {
        currentWindow = [UIApplication sharedApplication].keyWindow;
    }
    if (!currentWindow) {
        currentWindow = [UIApplication sharedApplication].windows.firstObject;
    }
    if (!currentWindow) {
        return;
    }
    
    // 创建遮罩视图
    [self createOverlayViewInWindow:currentWindow];
    
    // 创建菜单视图
    RCMenuView *menuView = [[RCMenuView alloc] init];
    menuView.translatesAutoresizingMaskIntoConstraints = NO;
    menuView.maxItemsPerRow = 5;
    menuView.itemSpacing = 0;
    menuView.rowSpacing = 0;
    
    __weak typeof(self) weakSelf = self;
    [menuView configureWithMenuItems:menuItems actionHandler:^(RCMenuItem *menuItem, NSInteger index) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.actionHandler) {
            strongSelf.actionHandler(menuItem, index);
        }
        [strongSelf hideMenuAnimated:YES];
    }];
    
    // 使用 Auto Layout 计算菜单大小
    // 先添加到一个临时容器中进行布局计算
    UIView *tempContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1000, 1000)];
    [tempContainer addSubview:menuView];
    
    // 强制布局计算
    [menuView setNeedsLayout];
    [menuView layoutIfNeeded];
    
    // 获取计算后的大小
    CGSize menuSize = [menuView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    // 从临时容器中移除
    [menuView removeFromSuperview];
        
    // 计算目标视图在屏幕上的位置
    UIWindow *targetWindow = targetView.window;
    if (!targetWindow) {
        targetWindow = [UIApplication sharedApplication].windows.firstObject;
    }
    
    CGRect targetRectInWindow = [targetView convertRect:targetRect toView:targetWindow];
    CGPoint targetCenter = CGPointMake(CGRectGetMidX(targetRectInWindow), CGRectGetMidY(targetRectInWindow));
    
    // 计算菜单位置
    CGFloat arrowHeight = 8;
    CGFloat arrowWidth = 16;
    CGFloat padding = 10;
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGFloat menuWidth = menuSize.width;
    CGFloat menuHeight = menuSize.height;
    
    // 判断菜单应该显示在目标视图上方还是下方
    BOOL showAbove = (targetRectInWindow.origin.y - menuHeight - arrowHeight - padding) > 0;
    
    CGFloat menuX = targetCenter.x - menuWidth / 2;
    CGFloat menuY;
    
    if (showAbove) {
        menuY = CGRectGetMinY(targetRectInWindow) - menuHeight - arrowHeight - padding;
    } else {
        menuY = CGRectGetMaxY(targetRectInWindow) + arrowHeight + padding;
    }
    
    // 确保菜单不超出屏幕边界
    if (menuX < padding) {
        menuX = padding;
    } else if (menuX + menuWidth > screenBounds.size.width - padding) {
        menuX = screenBounds.size.width - menuWidth - padding;
    }
    
    if (menuY < padding) {
        menuY = padding;
        showAbove = NO;
    } else if (menuY + menuHeight > screenBounds.size.height - padding) {
        menuY = screenBounds.size.height - menuHeight - padding;
        showAbove = YES;
    }
    
    // 创建容器视图
    CGFloat containerHeight = menuHeight + arrowHeight;
    CGFloat containerY = showAbove ? menuY : (menuY - arrowHeight);
    
    self.containerView = [[RCMenuHolderView alloc] initWithFrame:CGRectMake(menuX, containerY, menuWidth, containerHeight)];
    self.containerView.arrowPointingUp = !showAbove;
    
    // 创建三角形指示器
    RCArrowView *arrowView = [[RCArrowView alloc] init];
    arrowView.pointingUp = !showAbove;
    
    CGFloat arrowX = targetCenter.x - menuX - arrowWidth / 2;
    arrowX = MAX(10, MIN(arrowX, menuWidth - arrowWidth - 10)); // 确保箭头在菜单范围内
    
    // 设置菜单视图和箭头的 frame
    // 注意：menuView 使用 Auto Layout，所以需要重新设置 translatesAutoresizingMaskIntoConstraints
    menuView.translatesAutoresizingMaskIntoConstraints = YES;
    
    if (showAbove) {
        arrowView.frame = CGRectMake(arrowX, menuHeight, arrowWidth, arrowHeight);
        menuView.frame = CGRectMake(0, 0, menuWidth, menuHeight);
    } else {
        arrowView.frame = CGRectMake(arrowX, 0, arrowWidth, arrowHeight);
        menuView.frame = CGRectMake(0, arrowHeight, menuWidth, menuHeight);
    }
    
    self.containerView.menuView = menuView;
    self.containerView.arrowView = arrowView;
    
    [self.containerView addSubview:menuView];
    [self.containerView addSubview:arrowView];
    
    // 添加到遮罩视图
    [self.overlayView addSubview:self.containerView];

    // 显示动画
    self.containerView.alpha = 0;
    self.containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.containerView.alpha = 1;
        self.containerView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.menuVisible = YES;
    }];
}

- (void)hideMenuAnimated:(BOOL)animated {
    if (!self.menuVisible) {
        return;
    }
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            self.containerView.alpha = 0;
            self.containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            [self cleanupMenu];
        }];
    } else {
        [self cleanupMenu];
    }
}

- (void)cleanupMenu {
    [self.containerView removeFromSuperview];
    self.containerView = nil;
    
    [self.overlayView removeFromSuperview];
    self.overlayView = nil;
    
    self.menuVisible = NO;
    self.actionHandler = nil;
}

- (void)createOverlayViewInWindow:(UIWindow *)window {
    // 创建透明遮罩视图，用于拦截背景点击
    self.overlayView = [[UIView alloc] initWithFrame:window.bounds];
    self.overlayView.backgroundColor = [UIColor clearColor];
    self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // 添加背景点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    [self.overlayView addGestureRecognizer:tapGesture];
    
    // 添加到 window 的最上层
    [window addSubview:self.overlayView];
}

- (void)backgroundTapped:(UITapGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.overlayView];
    
    // 如果点击的不是菜单区域，隐藏菜单
    if (!CGRectContainsPoint(self.containerView.frame, location)) {
        [self hideMenuAnimated:YES];
    }
}

- (CGSize)calculateMenuSizeForItemCount:(NSInteger)itemCount {
    // 每个菜单项的宽度
    CGFloat itemWidth = 60;
    CGFloat itemHeight = 70;
    
    // 计算行数和每行的项数
    NSInteger maxItemsPerRow = 5;
    NSInteger numberOfRows = (itemCount + maxItemsPerRow - 1) / maxItemsPerRow;
    NSInteger itemsInLastRow = itemCount % maxItemsPerRow;
    if (itemsInLastRow == 0) {
        itemsInLastRow = maxItemsPerRow;
    }
    
    // 计算宽度（取最后一行的宽度，因为可能不满5个）
    CGFloat width = itemWidth * MIN(itemCount, maxItemsPerRow);
    
    // 计算高度
    CGFloat height = itemHeight * numberOfRows;
    
    // 添加内边距
    CGFloat padding = 16;
    width += padding * 2;
    height += padding * 2;
    
    return CGSizeMake(width, height);
}

@end

