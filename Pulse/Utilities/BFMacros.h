//
//  BFMacros.h
//  Pulse
//
//  Created by Austin Valleskey on 5/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#ifndef BFMacros_h
#define BFMacros_h

#define APP_DOWNLOAD_LINK @"https://testflight.apple.com/join/dvJgSQhf"

#define HALF_PIXEL (1 / [UIScreen mainScreen].scale)
#define IPAD_CONTENT_MAX_WIDTH 560

//////////////////////////////////////////////////////////////////
// Cache Keys
//////////////////////////////////////////////////////////////////
#define MY_CAMPS_CAN_POST_KEY @"my_camps_can_post"

#ifdef DEBUG
    #define DLog(FORMAT, ...) printf("%s: %s   %s\n", __PRETTY_FUNCTION__, [[NSString stringWithFormat:@"%d", __LINE__] UTF8String], [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String])
    #define DSpacer() printf("\n")
#else
    #define DLog(...) {}
    #define DSpacer() {}
#endif

#define CLAMP(x, low, high) ({\
    __typeof__(x) __x = (x); \
    __typeof__(low) __low = (low);\
    __typeof__(high) __high = (high);\
    __x > __high ? __high : (__x < __low ? __low : __x);\
})

//////////////////////////////////////////////////////////////////
// CGRect
//////////////////////////////////////////////////////////////////

#define SetX(v, x)               v.frame = CGRectMake(x, v.frame.origin.y, v.frame.size.width, v.frame.size.height)
#define SetY(v, y)               v.frame = CGRectMake(v.frame.origin.x, y, v.frame.size.width, v.frame.size.height)
#define SetWidth(v, w)           v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y, w, v.frame.size.height)
#define SetHeight(v, h)          v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y, v.frame.size.width, h)
#define SetOrigin(v, x, y)       v.frame = CGRectMake(x, y, v.frame.size.width, v.frame.size.height)
#define SetSize(v, w, h)         v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y, w, h)
#define SetFrame(v, x, y, w, h)  v.frame = CGRectMake(x, y, w, h)
#define AddX(v, offset)          v.frame = CGRectMake(v.frame.origin.x + offset, v.frame.origin.y, v.frame.size.width, v.frame.size.height)
#define AddY(v, offset)          v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y + offset, v.frame.size.width, v.frame.size.height)

#define X(v)                     v.frame.origin.x
#define Y(v)                     v.frame.origin.y
#define Width(v)                 v.frame.size.width
#define Height(v)                v.frame.size.height
#define Origin(v)                v.frame.origin
#define Size(v)                  v.frame.size

//////////////////////////////////////////////////////////////////
// Color
//////////////////////////////////////////////////////////////////

#define RGB(r, g, b)        [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]
#define RGBA(r, g, b, a)    [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

#define diff(p1, p2) (p1 != p2)
#define wait(delay, block) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), block);

#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE_X ([[UIScreen mainScreen] bounds].size.height==812)
#define IS_IPHONE_MAX ([[UIScreen mainScreen] bounds].size.height==896)
#define IS_IPHONE_XR ([[UIScreen mainScreen] bounds].size.height==896)
#define IS_IPHONE_5 ([[UIScreen mainScreen] bounds].size.height == 568.0)
#define HAS_ROUNDED_CORNERS (IS_IPHONE_X || IS_IPHONE_MAX || IS_IPHONE_XR)

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#endif /* BFMacros_h */
