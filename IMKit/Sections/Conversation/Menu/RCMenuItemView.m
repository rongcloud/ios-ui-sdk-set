//
//  RCMenuItemView.m
//  PopMenu
//
//  Created by RobinCui on 2025/10/18.
//

#import "RCMenuItemView.h"
#import "RCMenuItem.h"
#import "RCKitCommonDefine.h"

@interface RCMenuItemView ()

@property (nonatomic, strong, readwrite) UIImageView *iconImageView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong) UIStackView *stackView;

@end

@implementation RCMenuItemView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    // 创建图标视图
    _iconImageView = [[UIImageView alloc] init];
    _iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    _iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 创建标题标签
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont systemFontOfSize:12];
    _titleLabel.textColor = RCDynamicColor(@"control_title_white_color", @"0xffffff", @"0xffffff");
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.numberOfLines = 2; // 支持换行
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 使用 UIStackView 垂直布局
    _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_iconImageView, _titleLabel]];
    _stackView.axis = UILayoutConstraintAxisVertical;
    _stackView.alignment = UIStackViewAlignmentCenter; // 图标和文字水平居中
    _stackView.distribution = UIStackViewDistributionFill;
    _stackView.spacing = 6;
    _stackView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:_stackView];
    
    // 设置约束 - 让 StackView 顶部对齐，底部不固定
    [NSLayoutConstraint activateConstraints:@[
        // StackView 顶部对齐
        [_stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:8],
        [_stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:4],
        [_stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-4],
        
        // 图标固定尺寸
        [_iconImageView.widthAnchor constraintEqualToConstant:24],
        [_iconImageView.heightAnchor constraintEqualToConstant:24]
    ]];
    
    // 添加底部约束，但优先级较低，让高度由内容决定
    NSLayoutConstraint *bottomConstraint = [_stackView.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-8];
    bottomConstraint.priority = UILayoutPriorityDefaultHigh;
    bottomConstraint.active = YES;
    
    // 添加点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:tapGesture];
    
    // 设置背景色和圆角
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = 8;
    self.layer.masksToBounds = YES;
}

- (void)configureWithMenuItem:(RCMenuItem *)menuItem {
    self.iconImageView.image = menuItem.image;
    self.titleLabel.text = menuItem.title;
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    // 添加点击动画效果
    [UIView animateWithDuration:0.1 animations:^{
        self.transform = CGAffineTransformMakeScale(0.95, 0.95);
        self.backgroundColor = RCDynamicColor(@"selected_background_color", @"0xFFFFFF14", @"0xFFFFFF14");
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformIdentity;
            self.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            if (self.actionHandler) {
                self.actionHandler();
            }
        }];
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.backgroundColor = RCDynamicColor(@"selected_background_color", @"0x0000001A", @"0x0000001A");
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.backgroundColor = [UIColor clearColor];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.backgroundColor = [UIColor clearColor];
}

@end

