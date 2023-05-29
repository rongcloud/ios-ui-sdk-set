//
//  RongLocationKit.h
//  RongLocationKit
//
//  Created by zgh on 2022/2/17.
//

#import <Foundation/Foundation.h>

//! Project version number for RongLocationKit.RongLocationKitAdaptiveHeader
FOUNDATION_EXPORT double RongLocationKitVersionNumber;

//! Project version string for RongLocationKit.
FOUNDATION_EXPORT const unsigned char RongLocationKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <RongLocationKit/PublicHeader.h>

#if __has_include(<RongLocationKit/RCLocationMessageCell.h>)

#import <RongLocationKit/RCLocationMessageCell.h>
#import <RongLocationKit/RCLocationPickerViewController.h>
#import <RongLocationKit/RCLocationViewController.h>
#import <RongLocationKit/RongLocationKitAdaptiveHeader.h>


#else

#import "RCLocationMessageCell.h"
#import "RCLocationPickerViewController.h"
#import "RCLocationViewController.h"
#import "RongLocationKitAdaptiveHeader.h"

#endif

