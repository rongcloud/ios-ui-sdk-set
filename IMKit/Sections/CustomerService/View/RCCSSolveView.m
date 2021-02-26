//
//  RCCSSolveView.m
//  RongSelfBuiltCustomerDemo
//
//  Created by 张改红 on 2016/12/5.
//  Copyright © 2016年 rongcloud. All rights reserved.
//

#import "RCCSSolveView.h"
#import "RCKitCommonDefine.h"
#import "RCKitUtility.h"
@interface RCCSSolveView ()
@property (nonatomic, strong) UILabel *title;
@property (nonatomic, strong) UIButton *solved;
@property (nonatomic, strong) UIButton *solving;
@property (nonatomic, strong) UIButton *noSolve;
@end
@implementation RCCSSolveView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    self.title = [[UILabel alloc] init];
    self.title.textAlignment = NSTextAlignmentCenter;
    self.title.text = @"是否解决了您的问题";
    self.title.textColor = HEXCOLOR(0x353535);

    self.solved = [[UIButton alloc] init];
    [self.solved setBackgroundImage:RCResourceImage(@"Resolved") forState:UIControlStateNormal];
    [self.solved setBackgroundImage:RCResourceImage(@"Resolved-hover") forState:UIControlStateSelected];
    self.solved.layer.cornerRadius = 5;
    [self.solved addTarget:self action:@selector(isSolveQuestion:) forControlEvents:UIControlEventTouchUpInside];
    self.solved.selected = YES;
    self.solved.tag = RCCSResolved;

    self.solving = [[UIButton alloc] init];
    [self.solving setBackgroundImage:RCResourceImage(@"follow") forState:UIControlStateNormal];
    [self.solving setBackgroundImage:RCResourceImage(@"follow-hover") forState:UIControlStateSelected];
    self.noSolve.layer.cornerRadius = 5;
    [self.solving addTarget:self action:@selector(isSolveQuestion:) forControlEvents:UIControlEventTouchUpInside];
    self.solving.tag = RCCSResolving;

    self.noSolve = [[UIButton alloc] init];
    [self.noSolve setBackgroundImage:RCResourceImage(@"noSolve") forState:UIControlStateNormal];
    [self.noSolve setBackgroundImage:RCResourceImage(@"noSolve-hover") forState:UIControlStateSelected];
    self.noSolve.layer.cornerRadius = 5;
    [self.noSolve addTarget:self action:@selector(isSolveQuestion:) forControlEvents:UIControlEventTouchUpInside];
    self.noSolve.tag = RCCSUnresolved;

    [self addSubview:self.title];
    [self addSubview:self.solved];
    [self addSubview:self.solving];
    [self addSubview:self.noSolve];

    self.title.translatesAutoresizingMaskIntoConstraints = NO;
    self.solved.translatesAutoresizingMaskIntoConstraints = NO;
    self.solving.translatesAutoresizingMaskIntoConstraints = NO;
    self.noSolve.translatesAutoresizingMaskIntoConstraints = NO;

    NSDictionary *viewDic = NSDictionaryOfVariableBindings(_title, _solved, _solving, _noSolve);

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[_title(20)]-18-[_solved(39)]"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:viewDic]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_title]-0-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:viewDic]];

    [self addConstraints:[NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:[_solved(62)]-10-[_solving(62)]-10-[_noSolve(62)]"
                                                 options:0
                                                 metrics:nil
                                                   views:viewDic]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_solving(39)]"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:viewDic]];

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_noSolve(39)]"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:viewDic]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.solving
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1
                                                      constant:0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.solving
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.solved
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.noSolve
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self.solved
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1
                                                      constant:0]];
}

- (void)isSolveQuestion:(UIButton *)sender {
    if (sender.tag == RCCSResolved) {
        self.solving.selected = NO;
        self.noSolve.selected = NO;
        self.solved.selected = YES;
        self.isSolveBlock(RCCSResolved);
    } else if (sender.tag == RCCSResolving) {
        self.solving.selected = YES;
        self.noSolve.selected = NO;
        self.solved.selected = NO;
        self.isSolveBlock(RCCSResolving);
    } else if (sender.tag == RCCSUnresolved) {
        self.solving.selected = NO;
        self.noSolve.selected = YES;
        self.solved.selected = NO;
        self.isSolveBlock(RCCSUnresolved);
    }
}

@end
