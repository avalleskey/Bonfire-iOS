//
//  ManageIcebreakersViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 7/1/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "ManageIcebreakersViewController.h"
#import "BFHeaderView.h"
#import "UIColor+Palette.h"
#import "StreamPostCell.h"
#import "HAWebService.h"
#import "ButtonCell.h"
#import "SetAnIcebreakerViewController.h"
#import "Launcher.h"
#import "ComplexNavigationController.h"
#import "BFAlertController.h"

@interface ManageIcebreakersViewController () <SetAnIcebreakerViewControllerDelegate>

@end

@implementation ManageIcebreakersViewController

static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const postCellReuseIdentifier = @"PostCell";
static NSString * const howToCellReuseIdentifier = @"HowToCell";
static NSString * const buttonCellReuseIdentifier = @"ButtonCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Icebreaker";
    self.loading = false;
    
    [self setupTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        // Perform an action that will only be done once
        [self getIcebreakers];
    }
}

- (void)setupTableView {
    self.bfTableView = [[BFComponentTableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.navigationController.navigationBar.frame.size.height) style:UITableViewStyleGrouped];
    self.bfTableView.stream.detailLevel = BFComponentDetailLevelSome;
    self.bfTableView.extendedDelegate = self;
}

- (void)getIcebreakers {
    NSString *url = [[NSString alloc] initWithFormat:@"camps/%@/posts/icebreakers", self.camp.identifier];
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
        if (page.data.count > 0) {
            [self updatePostStreamWithPost:[page.data firstObject]];
        }
        else {
            [self.bfTableView.stream flush];
        }
                
        self.bfTableView.loading = false;
        [self.bfTableView hardRefresh:false];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ManageIcebreakresViewController / getIcebreakers() - error: %@", error);
        
        self.bfTableView.loading = false;
        
        [self.bfTableView hardRefresh:false];
    }];
}

#pragma mark - Table view data source
- (CGFloat)numberOfRowsInFirstSection {
    return (!self.bfTableView.loading && self.bfTableView.stream.components.count == 0 ? 2 : 0);
}
- (UITableViewCell *)cellForRowInFirstSection:(NSInteger)row {
    if (row == 0) {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:howToCellReuseIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor contentBackgroundColor];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:howToCellReuseIdentifier];
        }
        
        UIImageView *imagePreviewView = [cell.contentView viewWithTag:10];
        if (!imagePreviewView) {
            imagePreviewView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"howToSetIceBreaker_HelpGraphic"]];
            imagePreviewView.tag = 10;
            imagePreviewView.frame = CGRectMake(self.view.frame.size.width / 2 - (181 / 2), 22, 181, 102);
            [cell.contentView addSubview:imagePreviewView];
        }
        
        UILabel *titleLabel = [cell.contentView viewWithTag:11];
        if (!titleLabel) {
            titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 138, self.view.frame.size.width - 24, 21)];
            titleLabel.tag = 11;
            titleLabel.text = @"About Icebreakers";
            titleLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.textColor = [UIColor bonfirePrimaryColor];
            [cell.contentView addSubview:titleLabel];
        }
        
        UILabel *descriptionLabel = [cell.contentView viewWithTag:12];
        if (!descriptionLabel) {
            descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 165, self.view.frame.size.width - 48, 32)];
            descriptionLabel.tag = 12;
            descriptionLabel.text = @"Introduce new members to the Camp by prompting them to reply to a post when they join";
            descriptionLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
            descriptionLabel.textAlignment = NSTextAlignmentCenter;
            descriptionLabel.textColor = [UIColor bonfireSecondaryColor];
            descriptionLabel.numberOfLines = 0;
            descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
            CGFloat descriptionHeight = ceilf([descriptionLabel.text boundingRectWithSize:CGSizeMake(descriptionLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: descriptionLabel.font} context:nil].size.height);
            SetHeight(descriptionLabel, descriptionHeight);
            [cell.contentView addSubview:descriptionLabel];
        }
        
        return cell;
    }
    else if (row == 1) {
        ButtonCell *cell = [self.tableView dequeueReusableCellWithIdentifier:buttonCellReuseIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        
        if (cell == nil) {
            cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:buttonCellReuseIdentifier];
        }
        
        // Configure the cell...
        cell.buttonLabel.text = @"Choose a Post";
        cell.buttonLabel.textColor = [UIColor fromHex:[UIColor toHex:self.view.tintColor] adjustForOptimalContrast:true];
        cell.buttonLabel.textAlignment = NSTextAlignmentCenter;
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        cell.topSeparator.hidden = false;
        cell.bottomSeparator.hidden = false;
        
        return cell;
    }
    
    UITableViewCell *blankCell = [self.tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    return blankCell;
}
- (CGFloat)heightForRowInFirstSection:(NSInteger)row {
    if (row == 0) {
        // how to set icebreaker dialog
        CGFloat descriptionHeight = ceilf([@"Introduce new members to the Camp by prompting them to reply to a post when they join" boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 48, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular]} context:nil].size.height);
        
        return 165 + descriptionHeight + 24 + (self.loading ? 52 : 0);
    }
    else if (row == 1) {
        return [ButtonCell height];
    }
    
    return 0;
}

- (UIView *)viewForFirstSectionHeader {
    BFHeaderView *headerView = [[BFHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [BFHeaderView height])];
    headerView.title = @"Active";
    headerView.bottomLineSeparator.hidden = false;
    return headerView;
}

- (CGFloat)heightForFirstSectionHeader {
    return [BFHeaderView height];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (void)didSelectRowInFirstSection:(NSInteger)row {
    if (row == 1) {
        [self selectNewIcebreaker];
    }
}

- (void)didSelectComponent:(BFStreamComponent *)component atIndexPath:(NSIndexPath *)indexPath {
    if ([component.className isEqual:[StreamPostCell class]]) {
        Post *post = component.post;
        if (!post) { return; }
        
        BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:nil message:nil preferredStyle:BFAlertControllerStyleActionSheet];
        
        BFAlertAction *openPost = [BFAlertAction actionWithTitle:@"Open Post" style:BFAlertActionStyleDefault handler:^{
            [Launcher openPost:post withKeyboard:NO];
        }];
        [actionSheet addAction:openPost];
        
        BFAlertAction *setNewIcebreaker = [BFAlertAction actionWithTitle:@"Set New Icebreaker" style:BFAlertActionStyleDefault handler:^{
            [self selectNewIcebreaker];
        }];
        [actionSheet addAction:setNewIcebreaker];
        
        BFAlertAction *cancelActionSheet = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
        [actionSheet addAction:cancelActionSheet];
        
        [[Launcher topMostViewController] presentViewController:actionSheet animated:YES completion:nil];
    }
}
- (void)selectNewIcebreaker  {
    SetAnIcebreakerViewController *mibvc = [[SetAnIcebreakerViewController alloc] init];
    mibvc.view.tintColor = self.view.tintColor;
    mibvc.camp = self.camp;
    mibvc.delegate = self;
    
    ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:mibvc];
    newLauncher.searchView.textField.text = @"Icebreaker Post";
    [newLauncher.searchView hideSearchIcon:false];
    newLauncher.transitioningDelegate = [Launcher sharedInstance];
    
    [newLauncher updateBarColor:self.view.tintColor animated:false];
    
    [Launcher push:newLauncher animated:YES];
    
    [newLauncher updateNavigationBarItemsWithAnimation:NO];
}

- (void)setAnIcebreakerViewController:(SetAnIcebreakerViewController *)viewController didSelectPost:(Post *)post {
    [self updatePostStreamWithPost:post];
        
    [self.bfTableView hardRefresh:true];
}

- (void)updatePostStreamWithPost:(Post *)post {
    [self.bfTableView.stream flush];
    
    PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:@{@"data": @[[post toDictionary]]} error:nil];
    [self.bfTableView.stream appendPage:page];
    
    BFStreamComponent *selectNewComponent = [[BFStreamComponent alloc] initWithSettings:nil className:@"ButtonCell" detailLevel:BFComponentDetailLevelAll];
    selectNewComponent.dictionary = @{ButtonCellTitleAttributeName: @"Choose a New Post", ButtonCellTitleColorAttributeName: [UIColor fromHex:self.camp.attributes.color adjustForOptimalContrast:true]};
    selectNewComponent.action = ^{
        [self selectNewIcebreaker];
    };
    selectNewComponent.showLineSeparator = true;
    
    NSMutableArray<BFStreamComponent *><BFStreamComponent> *mutable = [[NSMutableArray<BFStreamComponent *><BFStreamComponent> alloc] initWithArray:self.bfTableView.stream.components];
    [mutable addObject:selectNewComponent];
    self.bfTableView.stream.components = mutable;
}

@end
