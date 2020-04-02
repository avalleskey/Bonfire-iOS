//
//  SelectAPostViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 7/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "SetAnIcebreakerViewController.h"
#import "UIColor+Palette.h"
#import "StreamPostCell.h"
#import "HAWebService.h"
#import "PostStream.h"
#import <JGProgressHUD/JGProgressHUD.h>
#import "BFMiniNotificationManager.h"
#import "Launcher.h"

#define HELP_INFO_DESCRIPTION @"Tap a post below to set it as your Camp icebreaker"

@interface SetAnIcebreakerViewController ()

@property (nonatomic, strong) BFVisualErrorView *errorView;

@end

@implementation SetAnIcebreakerViewController

static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const postCellReuseIdentifier = @"PostCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    
    self.loading = true;
    [self setupTableView];
    [self setupErrorView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCompleted:) name:@"NewPostCompleted" object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)newPostCompleted:(NSNotification *)notification {
    NSDictionary *info = notification.object;
    NSString *tempId = info[@"tempId"];
    Post *post = info[@"post"];
    
    NSLog(@"temp id: %@", tempId);
    NSLog(@"new post:: %@", post.identifier);
    
    if (self.bfTableView.stream.components.count == 0 && [post.attributes.postedIn.identifier isEqualToString:self.camp.identifier]) {
        // TODO: Check for image as well
        self.errorView.hidden = true;
        
        [self getPosts];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        // Perform an action that will only be done once
        [self getPosts];
    }
}

- (void)setupTableView {
    self.bfTableView = [[BFComponentTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.bfTableView.stream.detailLevel = BFComponentDetailLevelMinimum;
    self.bfTableView.extendedDelegate = self;
}

- (void)getPosts {
    NSString *url = [[NSString alloc] initWithFormat:@"camps/%@/stream?filter_types=top,!icebreaker", self.camp.identifier];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (self.bfTableView.stream.components.count > 0 && self.bfTableView.stream.nextCursor.length > 0) {
        [params setObject:self.bfTableView.stream.nextCursor forKey:@"next_cursor"];
    }
    
    if ([params objectForKey:@"next_cursor"]) {
        if ([self.bfTableView.stream hasLoadedCursor:params[@"next_cursor"]]) {
            return;
        }
        
        [self.bfTableView.stream addLoadedCursor:params[@"next_cursor"]];
    }
    
    self.bfTableView.loading = true;
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
        if (page.data.count > 0 && ![self.bfTableView.stream.nextCursor isEqualToString:page.meta.paging.nextCursor]) {
            [self.bfTableView.stream appendPage:page];
        }
        
        if (self.bfTableView.stream.components.count == 0) {
            self.errorView.hidden = false;
            
            BFVisualError *visualError = [BFVisualError visualErrorOfType:ErrorViewTypeNoPosts title:@"No Posts Yet" description:@"In order to set an Icebreaker, your Camp must have at least 1 post" actionTitle:@"Create Post" actionBlock:^{
                [Launcher openComposePost:self.camp inReplyTo:nil withMessage:nil media:nil quotedObject:nil];
            }];
            self.errorView.visualError = visualError;
            
            [self positionErrorView];
        }
        else {
            self.errorView.hidden = true;
        }
        
        self.loading = false;
        self.bfTableView.loading = false;
        
        [self.bfTableView hardRefresh:false];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ManageIcebreakresViewController / getIcebreakers() - error: %@", error);
        //        kNSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.loading = false;
        self.bfTableView.loading = false;
        
        [self.bfTableView hardRefresh:false];
    }];
}

- (void)setupErrorView {
    self.errorView = [[BFVisualErrorView alloc] initWithFrame:CGRectMake(16, 0, self.view.frame.size.width - 32, 100)];
    self.errorView.center = self.bfTableView.center;
    self.errorView.hidden = true;
    [self.bfTableView addSubview:self.errorView];
}
- (void)positionErrorView {
    self.errorView.center = CGPointMake(self.view.frame.size.width / 2, self.bfTableView.frame.size.height / 2 - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y);
}

#pragma mark - Table view data source
- (void)didSelectComponent:(BFStreamComponent *)component atIndexPath:(NSIndexPath *)indexPath {
    if (component) {
        Post *post = component.post;
        
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
        HUD.textLabel.text = @"Saving...";
        HUD.vibrancyEnabled = false;
        HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
        [HUD showInView:[Launcher topMostViewController].view animated:YES];
                
        [[HAWebService authenticatedManager] POST:[NSString stringWithFormat:@"camps/%@/posts/%@/icebreakers", post.attributes.postedIn.identifier, post.identifier] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            BFMiniNotificationObject *notificationObject = [BFMiniNotificationObject notificationWithText:@"Saved!" action:nil];
            [[BFMiniNotificationManager manager] presentNotification:notificationObject completion:nil];
            
            if ([self.delegate respondsToSelector:@selector(setAnIcebreakerViewController:didSelectPost:)]) {
                [self.delegate setAnIcebreakerViewController:self didSelectPost:post];
            }
            
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"error setting as icebreaker");
            NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
            NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            NSLog(@"%@",ErrorResponse);
            
            HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
            HUD.textLabel.text = @"Error Saving";
            
            [HUD dismissAfterDelay:1.f];
        }];
    }
}

- (CGFloat)heightForFirstSectionHeader {
    if (self.bfTableView.stream.components.count > 0) {
        CGSize labelSize = [HELP_INFO_DESCRIPTION boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 48, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.f weight:UIFontWeightSemibold]} context:nil].size;
        
        return labelSize.height + (12 * 2); // 24 padding on top and bottom
    }
    
    return CGFLOAT_MIN;
}
- (UIView *)viewForFirstSectionHeader {
    if (self.bfTableView.stream.components.count > 0) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 90)];
        
        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 12, header.frame.size.width - 48, 42)];
        descriptionLabel.text = HELP_INFO_DESCRIPTION;
        descriptionLabel.textColor = [UIColor bonfireSecondaryColor];
        descriptionLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightSemibold];
        descriptionLabel.textAlignment = NSTextAlignmentCenter;
        descriptionLabel.numberOfLines = 0;
        descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        CGSize labelSize = [descriptionLabel.text boundingRectWithSize:CGSizeMake(descriptionLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:descriptionLabel.font} context:nil].size;
        descriptionLabel.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y, descriptionLabel.frame.size.width, labelSize.height);
        [header addSubview:descriptionLabel];
        
        header.frame = CGRectMake(0, 0, header.frame.size.width, descriptionLabel.frame.size.height + (descriptionLabel.frame.origin.y*2));
        
        return header;
    }
    
    return nil;
}

- (void)tableView:(id)tableView didRequestNextPageWithMaxId:(NSInteger)maxId {
    if (self.bfTableView.stream.nextCursor.length > 0 && ![self.bfTableView.stream hasLoadedCursor:self.bfTableView.stream.nextCursor]) {
        [self getPosts];
    }
}

@end
