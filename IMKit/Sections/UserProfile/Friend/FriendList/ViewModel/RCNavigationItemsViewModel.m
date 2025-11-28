//
//  RCUFriendListNaviItemsViewModel.m
//  RongUserProfile
//
//  Created by RobinCui on 2024/8/16.
//

#import "RCNavigationItemsViewModel.h"
#import "RCUserSearchViewController.h"
#import "RCKitCommonDefine.h"

@interface RCNavigationItemsViewModel()
@end

@implementation RCNavigationItemsViewModel

- (instancetype)initWithResponder:(UIViewController *)responder
{
    self = [super init];
    if (self) {
        self.responder = responder;
    }
    return self;
}

- (NSArray *)rightNavigationBarItems {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn addTarget:self
            action:@selector(rightBarItemClicked:)
  forControlEvents:UIControlEventTouchUpInside];
    UIImage *image = RCResourceImage(@"friend_list_add_new");
    [btn setImage:image forState:UIControlStateNormal];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];
    return @[item];
}

- (void)rightBarItemClicked:(id)sender {
    if (self.responder) {
        RCUserSearchViewModel *vm = [[RCUserSearchViewModel alloc] init];
        RCUserSearchViewController *vc = [[RCUserSearchViewController alloc] initWithViewModel:vm];
        [self.responder.navigationController pushViewController:vc animated:YES];
    }
}

@end
