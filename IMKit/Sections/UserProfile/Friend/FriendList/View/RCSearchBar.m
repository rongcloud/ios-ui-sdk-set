//
//  RCSearchBar.m
//  RongIMKit
//
//  Created by RobinCui on 2024/8/21.
//  Copyright © 2024 RongCloud. All rights reserved.
//

#import "RCSearchBar.h"
#import "RCKitUtility.h"
#import "RCKitCommonDefine.h"

@interface RCSearchBar ()<UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;
@end

@implementation RCSearchBar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 设置 RTL 布局支持
        [self updateRTLUI];
        
        // 获取 textField
        if (@available(iOS 13.0, *)) {
            self.textField = self.searchTextField;
        } else {
            self.textField = [self valueForKey:@"searchField"];
        }
        
        // 设置文本框背景色（支持深色模式）
        self.textField.backgroundColor = [UIColor clearColor];
        self.showsCancelButton = NO;
        
        // 设置搜索图标颜色
        if (@available(iOS 13.0, *)) {
            UIImageView *iconView = (UIImageView *)self.searchTextField.leftView;
            if (iconView && [iconView isKindOfClass:[UIImageView class]]) {
                iconView.tintColor = RCDynamicColor(@"primary_color", @"0x0047ff", @"0x0047ff");
            }
        }
        UIColor *color = RCDynamicColor(@"text_secondary_color", @"0x7C838E", @"0x7C838E");;
        if (!color) {
            color = [UIColor lightGrayColor];
        }
        NSString *placeholderText =  RCLocalizedString(@"ToSearch");
        NSDictionary *attributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:17],
            NSForegroundColorAttributeName:color  // 可选：设置placeholder颜色
        };
        // 赋值给 attributedPlaceholder
        self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText attributes:attributes];
           
        self.textField.delegate = self;
        
        // 设置所有背景为透明
        self.backgroundColor = [UIColor clearColor];
        self.barTintColor = [UIColor clearColor];
        self.backgroundImage = [UIImage new];
        
        // 移除边框
        self.layer.borderWidth = 0;
        
    }
    return self;
}

- (void)updateRTLUI {
    if ([RCKitUtility isRTL]) {
        self.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
    } else {
        self.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    BOOL retValue = YES;
    if ([self.delegate respondsToSelector:@selector(searchBarShouldBeginEditing:)]) {
        retValue = [self.delegate searchBarShouldBeginEditing:self];
    }
    return retValue;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    BOOL retValue = YES;
    if ([self.delegate respondsToSelector:@selector(searchBarShouldEndEditing:)]) {
        retValue = [self.delegate searchBarShouldEndEditing:self];
    }
    return retValue;
}


@end
