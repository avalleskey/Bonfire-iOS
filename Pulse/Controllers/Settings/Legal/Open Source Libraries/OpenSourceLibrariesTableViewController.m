//
//  OpenSourceLibrariesTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "OpenSourceLibrariesTableViewController.h"
#import <SafariServices/SafariServices.h>
#import "Launcher.h"

@import Firebase;

@interface OpenSourceLibrariesTableViewController ()

@end

@implementation OpenSourceLibrariesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Settings / Legal / Open Source" screenClass:nil];
}

- (void)setup {
    self.title = @"Open Source";
    self.smartListDelegate = self;
    
    [self setJsonFile:@"OpenSource"];
}

- (void)tableView:(UITableView *)tableView didSelectRowWithId:(NSString *)rowId {
    NSString *url = @"";
    
    if ([rowId isEqualToString:@"blocks_kit"]) {
        // mit
        url = @"https://github.com/BlocksKit/BlocksKit/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"afnetworking"]) {
        // mit
        url = @"https://github.com/AFNetworking/AFNetworking/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"shimmer"]) {
        // BSD
        url = @"https://github.com/facebook/Shimmer/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"uitextview_placeholder"]) {
        // mit
        url = @"https://github.com/devxoul/UITextView-Placeholder/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"sdwebimage"]) {
        // mit
        url = @"https://github.com/SDWebImage/SDWebImage/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"haptic_helper"]) {
        // mit
        url = @"https://github.com/emreyanik/HapticHelper/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"jts_image_view_controller"]) {
        // mit
        url = @"https://github.com/jaredsinclair/JTSImageViewController/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"uinavigationitem_margin"]) {
        // mit
        url = @"https://github.com/devxoul/UINavigationItem-Margin/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"lockbox"]) {
        // mit
        url = @"https://github.com/granoff/Lockbox/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"l360_confetti"]) {
        // apache 2.0
        url = @"https://github.com/life360/confetti/blob/master/iOS/LICENSE.md";
    }
    if ([rowId isEqualToString:@"json_model"]) {
        // mit
        url = @"https://github.com/jsonmodel/jsonmodel/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"rsk_image_cropper"]) {
        // mit
        url = @"https://github.com/ruslanskorb/RSKImageCropper/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"jg_progress_hud"]) {
        // mit
        url = @"https://github.com/JonasGessner/JGProgressHUD/blob/master/LICENSE.txt";
    }
    if ([rowId isEqualToString:@"ap_address_book"]) {
        // mit
        url = @"https://github.com/Alterplay/APAddressBook/blob/master/LICENSE.txt";
    }
    if ([rowId isEqualToString:@"lib_phone_number"]) {
        // apache 2.0
        url = @"https://github.com/iziz/libPhoneNumber-iOS/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"responsive_label"]) {
        // mit
        url = @"https://github.com/hsusmita/ResponsiveLabel/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"ttt_attributed_label"]) {
        // mit
        url = @"https://github.com/Krelborn/TTTAttributedLabel/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"regexer"]) {
        // mit
        url = @"https://github.com/fortinmike/Regexer/blob/master/LICENSE";
    }
    if ([rowId isEqualToString:@"pincache"]) {
        // apache 2.0
        url = @"https://github.com/pinterest/PINCache/blob/master/LICENSE.txt";
    }
    if ([rowId isEqualToString:@"google_toolbox"]) {
        url = @"https://github.com/google/google-toolbox-for-mac/blob/master/LICENSE";
    }
    
    [[Launcher sharedInstance] openURL:url];
}

@end
