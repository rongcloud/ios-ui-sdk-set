//
//  RCCustomIOSAlertView.h
//  RCCustomIOSAlertView
//
//  Created by Richard on 20/09/2013.
//  Copyright (c) 2013-2015 Wimagguc.
//
//  Lincesed under The MIT License (MIT)
//  http://opensource.org/licenses/MIT
//

#import <UIKit/UIKit.h>

@protocol RCCustomIOSAlertViewDelegate

- (void)customIOS7dialogButtonTouchUpInside:(id)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@interface RCCustomIOSAlertView : UIView <RCCustomIOSAlertViewDelegate>

@property (nonatomic, retain) UIView *parentView;    // The parent view this 'dialog' is attached to
@property (nonatomic, retain) UIView *dialogView;    // Dialog's container view
@property (nonatomic, retain) UIView *containerView; // Container within the dialog (place your ui elements here)

@property (nonatomic, weak) id<RCCustomIOSAlertViewDelegate> delegate;
@property (nonatomic, retain) NSArray *buttonTitles;
@property (nonatomic, assign) BOOL useMotionEffects;

@property (nonatomic, copy) void (^onButtonTouchUpInside)(RCCustomIOSAlertView *alertView, int buttonIndex);

- (id)init;

/*!
 DEPRECATED: Use the [RCCustomIOSAlertView init] method without passing a parent view.
 */
- (id)initWithParentView:(UIView *)_parentView __attribute__((deprecated));

- (void)show;
- (void)close;

- (IBAction)customIOS7dialogButtonTouchUpInside:(id)sender;
- (void)dismissWithClickedButtonIndex:(int)index;
- (void)dealloc;

@end
