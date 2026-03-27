//
//  RCNameEditView.m
//  RongUserProfile
//
//  Created by zgh on 2024/8/20.
//

#import "RCNameEditView.h"
#import "RCKitCommonDefine.h"

#define RCNameEditViewEditViewTop 15
#define RCNameEditViewEditViewHeight 44
#define RCNameEditViewLabelLeading 12
#define RCNameEditViewTextFieldLeadingSpace 20
#define RCNameEditViewTipFont 13.5
#define RCNameEditViewContentFont 17


@interface RCNameEditView ()

@property (nonatomic, strong) UIView *editView;

@end

@implementation RCNameEditView

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.contentLabel sizeToFit];
    self.contentLabel.center = CGPointMake(RCNameEditViewLabelLeading + self.contentLabel.frame.size.width/2, self.editView.bounds.size.height/2);
    
    CGRect frame = self.tipLabel.frame;
    frame.size.width = self.frame.size.width - RCNameEditViewLabelLeading * 2;
    frame.origin.x = RCNameEditViewLabelLeading;
    self.tipLabel.frame = frame;
    [self.tipLabel sizeToFit];
    self.tipLabel.center = CGPointMake(self.center.x, CGRectGetMaxY(self.editView.frame) + RCNameEditViewEditViewTop + self.tipLabel.frame.size.height / 2);
    
    CGFloat x = CGRectGetMaxX(self.contentLabel.frame) + RCNameEditViewTextFieldLeadingSpace;
    self.textField.frame = CGRectMake(x, 0, self.editView.frame.size.width - x - RCNameEditViewLabelLeading, self.editView.frame.size.height);
}

#pragma mark -- private

- (void)setupView {
    [super setupView];
    self.backgroundColor = RCDYCOLOR(0xf5f6f9, 0x111111);
    [self addSubview:self.editView];
    [self addSubview:self.tipLabel];
    [self.editView addSubview:self.contentLabel];
    [self.editView addSubview:self.textField];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    // 设置点击次数（默认为1）
    tapGesture.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tapGesture];
    self.userInteractionEnabled = YES;
}


- (void)handleTap {
    if ([self.textField isFirstResponder]) {
        [self.textField resignFirstResponder];
    }
}

#pragma mark -- getter

- (UIView *)editView {
    if (!_editView) {
        _editView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, RCNameEditViewEditViewHeight)];
        _editView.backgroundColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0xffffff)
                                                             darkColor:HEXCOLOR(0x1c1c1e)];
        RCDYCOLOR(0xf5f6f9, 0x111111);

    }
    return _editView;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [[UITextField alloc] init];
        [_textField setTextColor:[RCKitUtility generateDynamicColor:HEXCOLOR(0x000000) darkColor:RCMASKCOLOR(0xffffff, 0.8)]];
    }
    return _textField;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
//        _contentLabel.textColor = HEXCOLOR(0x000000);
        _contentLabel.font = [UIFont systemFontOfSize:RCNameEditViewContentFont];
        _contentLabel.textAlignment = NSTextAlignmentRight;
    }
    return _contentLabel;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] init];
        _tipLabel.textColor = RCDYCOLOR(0xa0a5ab, 0x9f9f9f);
        _tipLabel.font = [UIFont systemFontOfSize:RCNameEditViewTipFont];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.numberOfLines = 0;
    }
    return _tipLabel;
}
@end
