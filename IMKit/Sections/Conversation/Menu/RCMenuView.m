//
//  RCMenuView.m
//  PopMenu
//
//  Created by RobinCui on 2025/10/18.
//

#import "RCMenuView.h"
#import "RCMenuItem.h"
#import "RCMenuItemView.h"
#import "RCKitCommonDefine.h"

@interface RCMenuView ()

@property (nonatomic, strong, readwrite) NSArray<RCMenuItem *> *menuItems;
@property (nonatomic, strong) UIStackView *mainStackView;
@property (nonatomic, copy) void (^actionHandler)(RCMenuItem *menuItem, NSInteger index);
@property (nonatomic, strong) NSLayoutConstraint *widthConstraint;

@end

@implementation RCMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupDefaultValues];
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefaultValues];
        [self setupUI];
    }
    return self;
}

- (void)setupDefaultValues {
    _maxItemsPerRow = 5;
    _itemSpacing = 0;
    _rowSpacing = 0;
}

- (void)setupUI {
    // 创建主 StackView（垂直布局，用于容纳多行）
    _mainStackView = [[UIStackView alloc] init];
    _mainStackView.axis = UILayoutConstraintAxisVertical;
    _mainStackView.alignment = UIStackViewAlignmentFill;
    _mainStackView.distribution = UIStackViewDistributionFill;
    _mainStackView.spacing = self.rowSpacing;
    _mainStackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:_mainStackView];
    
    // 添加内边距
    CGFloat padding = 10;
    
    // 设置约束
    [NSLayoutConstraint activateConstraints:@[
        [_mainStackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:padding],
        [_mainStackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-padding],
        [_mainStackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:padding],
        [_mainStackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-padding]
    ]];
    
    // 设置背景和圆角
    self.backgroundColor = RCDynamicColor(@"pop_layer_background_color", @"0x323232", @"0x323232");
    self.layer.cornerRadius = 12;
    self.layer.masksToBounds = NO;
    
    // 添加阴影
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 2);
    self.layer.shadowOpacity = 0.15;
    self.layer.shadowRadius = 8;
}

- (void)configureWithMenuItems:(NSArray<RCMenuItem *> *)menuItems
                 actionHandler:(void (^)(RCMenuItem *menuItem, NSInteger index))actionHandler {
    self.menuItems = menuItems;
    self.actionHandler = actionHandler;
    
    // 清除之前的视图
    for (UIView *subview in self.mainStackView.arrangedSubviews) {
        [self.mainStackView removeArrangedSubview:subview];
        [subview removeFromSuperview];
    }
    
    if (menuItems.count == 0) {
        return;
    }
    
    // 计算每个菜单项的固定宽度
    CGFloat itemWidth = 60; // 每个菜单项的固定宽度
    
    // 按行分组菜单项
    NSInteger totalItems = menuItems.count;
    NSInteger numberOfRows = (totalItems + self.maxItemsPerRow - 1) / self.maxItemsPerRow;
    
    for (NSInteger row = 0; row < numberOfRows; row++) {
        NSInteger startIndex = row * self.maxItemsPerRow;
        NSInteger endIndex = MIN(startIndex + self.maxItemsPerRow, totalItems);
        NSInteger itemsInThisRow = endIndex - startIndex;
        
        // 创建行 StackView（水平布局）
        UIStackView *rowStackView = [[UIStackView alloc] init];
        rowStackView.axis = UILayoutConstraintAxisHorizontal;
        rowStackView.alignment = UIStackViewAlignmentFill; // Fill，让高度自适应
        rowStackView.distribution = UIStackViewDistributionFill; // Fill，不自动等宽
        rowStackView.spacing = self.itemSpacing;
        rowStackView.translatesAutoresizingMaskIntoConstraints = NO;
        
        // 添加菜单项视图到行中
        for (NSInteger i = startIndex; i < endIndex; i++) {
            RCMenuItem *menuItem = menuItems[i];
            RCMenuItemView *itemView = [[RCMenuItemView alloc] init];
            itemView.translatesAutoresizingMaskIntoConstraints = NO;
            [itemView configureWithMenuItem:menuItem];
            
            // 设置菜单项的固定宽度约束
            [itemView.widthAnchor constraintEqualToConstant:itemWidth].active = YES;
            
            // 设置点击回调
            NSInteger index = i;
            itemView.actionHandler = ^{
                if (actionHandler) {
                    actionHandler(menuItem, index);
                }
            };
            
            [rowStackView addArrangedSubview:itemView];
        }
        
        // 如果这一行不满（不是第一行或者不满5个），添加一个弹性空白视图推动菜单项到左边
        if (itemsInThisRow < self.maxItemsPerRow && numberOfRows > 1 && row > 0) {
            UIView *spacerView = [[UIView alloc] init];
            spacerView.backgroundColor = [UIColor clearColor];
            spacerView.translatesAutoresizingMaskIntoConstraints = NO;
            
            // 设置 spacer 的 content hugging priority 为最低，让它占据剩余空间
            [spacerView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
            [spacerView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
            
            [rowStackView addArrangedSubview:spacerView];
        }
        
        [self.mainStackView addArrangedSubview:rowStackView];
    }
    
    // 更新间距
    self.mainStackView.spacing = self.rowSpacing;
    
    // 计算并设置整体宽度约束（根据实际菜单项数量）
    CGFloat padding = 10;
    NSInteger itemsInFirstRow = MIN(self.maxItemsPerRow, totalItems);
    CGFloat totalWidth = itemsInFirstRow * itemWidth + (itemsInFirstRow - 1) * self.itemSpacing + padding * 2;
    
    // 移除旧的宽度约束
    if (self.widthConstraint) {
        self.widthConstraint.active = NO;
    }
    
    // 设置新的宽度约束
    self.widthConstraint = [self.widthAnchor constraintEqualToConstant:totalWidth];
    self.widthConstraint.active = YES;
}

- (void)setItemSpacing:(CGFloat)itemSpacing {
    _itemSpacing = itemSpacing;
    for (UIView *subview in self.mainStackView.arrangedSubviews) {
        if ([subview isKindOfClass:[UIStackView class]]) {
            ((UIStackView *)subview).spacing = itemSpacing;
        }
    }
}

- (void)setRowSpacing:(CGFloat)rowSpacing {
    _rowSpacing = rowSpacing;
    self.mainStackView.spacing = rowSpacing;
}

@end

