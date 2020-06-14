//
//  AppIconTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "AppIconTableViewController.h"
#import "Launcher.h"

@import Firebase;

@interface AppIconTableViewController ()

@end

@implementation AppIconTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Settings / App Icon" screenClass:nil];
}

- (void)setup {
    self.title = @"App Icon";
    self.smartListDelegate = self;
    
    [self setJsonFile:@"AppIcon"];
}

- (void)tableView:(UITableView *)tableView didSelectRowWithId:(NSString *)rowId {
    if ([rowId isEqualToString:@"app_icon_default"]) {
        [[UIApplication sharedApplication] setAlternateIconName:nil completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"error setting alternate app icon: %@", error);
            }
        }];
    }
    else if ([rowId isEqualToString:@"app_icon_blm"]) {
        [[UIApplication sharedApplication] setAlternateIconName:@"AlternativeAppIcon_blm" completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"error setting alternate app icon: %@", error);
            }
        }];
    }
    else if ([rowId isEqualToString:@"app_icon_retro"]) {
        [[UIApplication sharedApplication] setAlternateIconName:@"AlternativeAppIcon_retro" completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"error setting alternate app icon: %@", error);
            }
        }];
    }
    else if ([rowId isEqualToString:@"app_icon_sunrise"]) {
        [[UIApplication sharedApplication] setAlternateIconName:@"AlternativeAppIcon_sunrise" completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"error setting alternate app icon: %@", error);
            }
        }];
    }
    else if ([rowId isEqualToString:@"app_icon_campgrounds"]) {
        [[UIApplication sharedApplication] setAlternateIconName:@"AlternativeAppIcon_campgrounds" completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"error setting alternate app icon: %@", error);
            }
        }];
    }
    else if ([rowId isEqualToString:@"app_icon_skeuomorphic"]) {
        [[UIApplication sharedApplication] setAlternateIconName:@"AlternativeAppIcon_skeuomorphic" completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"error setting alternate app icon: %@", error);
            }
        }];
    }
    else if ([rowId isEqualToString:@"suggest_app_icon"]) {
        Camp *camp = [[Camp alloc] initWithDictionary:@{@"id": @"-EZ4QV73yVPo9"} error:nil];
        [Launcher openCamp:camp];
    }
}

@end
