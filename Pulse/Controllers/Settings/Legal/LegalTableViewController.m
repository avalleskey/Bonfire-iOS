//
//  LegalTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "LegalTableViewController.h"
#import "Open Source Libraries/OpenSourceLibrariesTableViewController.h"
#import "Launcher.h"

@import Firebase;

@interface LegalTableViewController ()

@end

@implementation LegalTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Settings / Legal" screenClass:nil];
}

- (void)setup {
    self.title = @"Legal";
    self.smartListDelegate = self;
    
    [self setJsonFile:@"Legal"];
}

- (void)tableView:(UITableView *)tableView didSelectRowWithId:(NSString *)rowId {
    if ([rowId isEqualToString:@"terms_and_conditions"]) {
        [Launcher openURL:@"https://bonfire.camp/legal/terms"];
    }
    if ([rowId isEqualToString:@"privacy_policy"]) {
        [Launcher openURL:@"https://bonfire.camp/legal/privacy"];
    }
    if ([rowId isEqualToString:@"open_source_libraries"]) {
        OpenSourceLibrariesTableViewController *openSourceLibrariesTableVC = [[OpenSourceLibrariesTableViewController alloc] init];
        SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:openSourceLibrariesTableVC];
        [simpleNav setLeftAction:SNActionTypeBack];
        
        [Launcher push:simpleNav animated:YES];
    }
}

@end
