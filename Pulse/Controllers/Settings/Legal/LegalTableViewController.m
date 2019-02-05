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

@interface LegalTableViewController ()

@end

@implementation LegalTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
}

- (void)setup {
    self.title = @"Legal";
    self.smartListDelegate = self;
    
    [self setJsonFile:@"Legal"];
}

- (void)tableView:(UITableView *)tableView didSelectRowWithId:(NSString *)rowId {
    if ([rowId isEqualToString:@"terms_and_conditions"]) {
        [[Launcher sharedInstance] openURL:@"https://google.com"];
    }
    if ([rowId isEqualToString:@"privacy_policy"]) {
        [[Launcher sharedInstance] openURL:@"https://google.com"];
    }
    if ([rowId isEqualToString:@"open_source_libraries"]) {
        OpenSourceLibrariesTableViewController *openSourceLibrariesTableVC = [[OpenSourceLibrariesTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [[Launcher sharedInstance] push:openSourceLibrariesTableVC animated:YES];
    }
}

@end
