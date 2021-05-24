//
//  RCCSEvaluateView.m
//  RongSelfBuiltCustomerDemo
//
//  Created by 张改红 on 2016/12/5.
//  Copyright © 2016年 rongcloud. All rights reserved.
//

#import "RCCSEvaluateView.h"
#import "RCCSSolveView.h"
#import "RCCSStarView.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
#import "RCKitConfig.h"
@interface RCCSEvaluateView () <UITextViewDelegate>
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *starView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *satisfyLabel;
@property (nonatomic, strong) RCCSSolveView *solveView;
@property (nonatomic, strong) UITextView *suggestText;
@property (nonatomic, strong) UIButton *submitButton;

@property (nonatomic, strong) UITextView *placeHolderText;

@property (nonatomic, assign) int source;
@property (nonatomic, assign) int solveStatus;
@end
@implementation RCCSEvaluateView
- (instancetype)initWithFrame:(CGRect)frame showSolveView:(BOOL)isShowSolveView {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat height;
        if (isShowSolveView) {
            height = 385;
        } else {
            height = 291;
        }
        self.source = 5;
        self.solveStatus = 1;
        self.frame = [UIScreen mainScreen].bounds;
        self.backgroundColor = [UIColor colorWithRed:102 / 255.0 green:102 / 255.0 blue:102 / 255.0 alpha:0.5];
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, height)];
        self.backgroundView.backgroundColor = [UIColor whiteColor];
        self.backgroundView.center = self.center;
        self.backgroundView.layer.cornerRadius = 5;
        [self addSubview:self.backgroundView];
        [self setupSubviews:isShowSolveView];

        //注册通知,监听键盘弹出事件
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];

        //注册通知,监听键盘消失事件
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidHidden)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

#pragma mark - Public Method

- (void)show {
    if ([NSThread isMainThread]) {
        [self showAtWindow:YES];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAtWindow:YES];
        });
    }
}

- (void)hide {
    if ([NSThread isMainThread]) {
        [self showAtWindow:NO];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAtWindow:NO];
        });
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self.suggestText becomeFirstResponder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self.suggestText resignFirstResponder];
        return NO;
    }

    if (![text isEqualToString:@""]) {
        self.placeHolderText.text = nil;
    }

    if ([text isEqualToString:@""] && range.location == 0 && range.length == 1) {
        self.placeHolderText.text = @"欢迎给我们的服务提建议~";
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    if (![textView.text isEqualToString:@""]) {
        self.placeHolderText.text = nil;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    //隐藏键盘
    [self.suggestText resignFirstResponder];
}

#pragma mark – Private Methods

- (void)keyboardDidShow:(NSNotification *)notification {
    [self.suggestText becomeFirstResponder];
    //获取键盘高度
    NSValue *keyboardObject = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [keyboardObject CGRectValue];
    if (CGRectGetMaxY(self.backgroundView.frame) > keyboardRect.origin.y) {
        CGRect rect = self.backgroundView.frame;
        rect.origin.y -= CGRectGetMaxY(self.backgroundView.frame) - keyboardRect.origin.y;
        [UIView animateKeyframesWithDuration:0.0f
            delay:0.0
            options:UIViewKeyframeAnimationOptionCalculationModeLinear
            animations:^{
                [UIView addKeyframeWithRelativeStartTime:0.0
                                        relativeDuration:0.0
                                              animations:^{
                                                  self.backgroundView.transform = CGAffineTransformMakeTranslation(
                                                      0, -(CGRectGetMaxY(self.backgroundView.frame) -
                                                           keyboardRect.origin.y));
                                              }];
            }
            completion:^(BOOL finished){

            }];

        self.backgroundView.frame = rect;
    }
}

- (void)keyboardDidHidden {
    [UIView animateWithDuration:0.1
                     animations:^{
                         self.backgroundView.transform = CGAffineTransformIdentity;
                     }];
}

- (void)submitSuggest {
    [self.suggestText resignFirstResponder];
    if (self.evaluateResult) {
        self.evaluateResult(self.source, self.solveStatus, self.suggestText.text);
    }
    [self hide];
}

- (void)cancellEva {
    [self hide];
}

- (void)showAtWindow:(BOOL)isShow {
    if (isShow) {
        [[RCKitUtility getKeyWindow] addSubview:self];
    } else {
        [self removeFromSuperview];
    }
}

- (void)setupSubviews:(BOOL)isShowEva {
    self.cancelButton = [[UIButton alloc] init];
    [self.cancelButton setBackgroundImage:RCResourceImage(@"close") forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(cancellEva) forControlEvents:UIControlEventTouchUpInside];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"请对我们本次的服务进行评价";
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = HEXCOLOR(0x353535);

    self.starView = [[UIView alloc] init];

    self.satisfyLabel = [[UILabel alloc] init];
    self.satisfyLabel.text = @"非常满意";
    self.satisfyLabel.textAlignment = NSTextAlignmentCenter;
    self.satisfyLabel.textColor = HEXCOLOR(0xf4aa3a);
    self.satisfyLabel.font = [[RCKitConfig defaultConfig].font fontOfSecondLevel];

    self.solveView = [[RCCSSolveView alloc] init];

    self.suggestText = [[UITextView alloc] init];
    self.suggestText.layer.borderWidth = 0.5;
    self.suggestText.layer.borderColor = HEXCOLOR(0xbababa).CGColor;
    self.suggestText.layer.cornerRadius = 5;
    self.suggestText.delegate = self;
    self.suggestText.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
    self.suggestText.textColor = HEXCOLOR(0x676e6f);
    self.suggestText.backgroundColor = [UIColor clearColor];
    self.suggestText.delegate = self;

    self.placeHolderText = [[UITextView alloc] init];
    self.placeHolderText.font = [[RCKitConfig defaultConfig].font fontOfAnnotationLevel];
    self.placeHolderText.editable = NO;
    self.placeHolderText.textColor = RGBCOLOR(188, 188, 194);
    self.placeHolderText.backgroundColor = HEXCOLOR(0xefefef);
    self.placeHolderText.layer.borderWidth = 0.5;
    self.placeHolderText.layer.borderColor = HEXCOLOR(0xbababa).CGColor;
    self.placeHolderText.layer.cornerRadius = 5;
    self.placeHolderText.text = @"欢迎给我们的服务提建议~";

    self.submitButton = [[UIButton alloc] init];
    self.submitButton.layer.cornerRadius = 5;
    [self.submitButton setBackgroundImage:RCResourceImage(@"blue") forState:UIControlStateNormal];
    [self.submitButton setBackgroundImage:RCResourceImage(@"blue－hover") forState:UIControlStateHighlighted];

    [self.submitButton setTitle:@"提交评价" forState:UIControlStateNormal];
    [self.submitButton addTarget:self action:@selector(submitSuggest) forControlEvents:UIControlEventTouchUpInside];

    [self.backgroundView addSubview:self.cancelButton];
    [self.backgroundView addSubview:self.titleLabel];
    [self.backgroundView addSubview:self.starView];
    [self.backgroundView addSubview:self.satisfyLabel];
    [self.backgroundView addSubview:self.solveView];
    [self.backgroundView addSubview:self.placeHolderText];
    [self.backgroundView addSubview:self.suggestText];
    [self.backgroundView addSubview:self.submitButton];

    self.cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.satisfyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.solveView.translatesAutoresizingMaskIntoConstraints = NO;
    self.suggestText.translatesAutoresizingMaskIntoConstraints = NO;
    self.submitButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.starView.translatesAutoresizingMaskIntoConstraints = NO;
    self.placeHolderText.translatesAutoresizingMaskIntoConstraints = NO;

    NSDictionary *views = NSDictionaryOfVariableBindings(_cancelButton, _titleLabel, _starView, _satisfyLabel,
                                                         _solveView, _suggestText, _submitButton, _placeHolderText);
    if (isShowEva) {
        [self.backgroundView
            addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-8-[_cancelButton(15)]-8-[_titleLabel(20)]-15-[_"
                                                           @"starView(32)]-20-[_satisfyLabel(16)]-20-[_solveView(78)]-"
                                                           @"14-[_suggestText(68)]-21-[_submitButton(27)]"
                                                   options:0
                                                   metrics:nil
                                                     views:views]];
        [self.backgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[_solveView]-10-|"
                                                                                    options:0
                                                                                    metrics:nil
                                                                                      views:views]];
        self.solveView.hidden = NO;
    } else {
        [self.backgroundView
            addConstraints:
                [NSLayoutConstraint
                    constraintsWithVisualFormat:@"V:|-8-[_cancelButton(15)]-8-[_titleLabel(20)]-15-[_starView(32)]-20-["
                                                @"_satisfyLabel(16)]-18-[_suggestText(68)]-21-[_submitButton(27)]"
                                        options:0
                                        metrics:nil
                                          views:views]];
        self.solveView.hidden = YES;
    }
    [self.backgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_cancelButton(15)]-8-|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:views]];

    [self.backgroundView
        addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[_titleLabel(>=15)]-10-|"
                                                               options:0
                                                               metrics:nil
                                                                 views:views]];

    [self.backgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_starView(210)]"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:views]];

    [self.backgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-10-[_satisfyLabel]-10-|"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:views]];

    [self.backgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_suggestText(205)]"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:views]];

    [self.backgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_placeHolderText(205)]"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:views]];

    [self.backgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_placeHolderText(68)]"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:views]];

    [self.backgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_submitButton(135)]"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:views]];

    [self.backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_suggestText
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_suggestText.superview
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1
                                                                     constant:0]];

    [self.backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_placeHolderText
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_suggestText
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1
                                                                     constant:0]];

    [self.backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_placeHolderText
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_suggestText
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1
                                                                     constant:0]];

    [self.backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_starView
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_starView.superview
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1
                                                                     constant:0]];

    [self.backgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_submitButton
                                                                    attribute:NSLayoutAttributeCenterX
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:_submitButton.superview
                                                                    attribute:NSLayoutAttributeCenterX
                                                                   multiplier:1
                                                                     constant:0]];

    RCCSStarView *starView = [[RCCSStarView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width - 50, 32)
                                                       starIndex:5
                                                       starWidth:32
                                                           space:12
                                                    defaultImage:nil
                                                      lightImage:nil
                                                        isCanTap:YES];
    __weak typeof(self) weakSelf = self;
    [starView setStarEvaluateBlock:^(RCCSStarView *starView, NSInteger starIndex) {
        NSString *str = nil;
        if (starIndex == 1) {
            str = @"很不满意";
        } else if (starIndex == 2) {
            str = @"不满意";
        } else if (starIndex == 3) {
            str = @"一般";
        } else if (starIndex == 4) {
            str = @"满意";
        } else if (starIndex == 5) {
            str = @"非常满意";
        }
        weakSelf.source = (int)starIndex;
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.satisfyLabel.text = str;
        });

    }];
    [self.starView addSubview:starView];

    [self.solveView setIsSolveBlock:^(RCCSResolveStatus solveStatus) {
        weakSelf.solveStatus = (int)solveStatus;
    }];
}
@end
