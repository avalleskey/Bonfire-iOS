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

@interface ManageIcebreakersViewController () <SetAnIcebreakerViewControllerDelegate>

@property (nonatomic) BOOL loading;

@property (nonatomic, strong) PostStream *stream;

@end

@implementation ManageIcebreakersViewController

static NSString * const blankCellIdentifier = @"BlankCell";
static NSString * const postCellReuseIdentifier = @"PostCell";
static NSString * const howToCellReuseIdentifier = @"HowToCell";
static NSString * const buttonCellReuseIdentifier = @"ButtonCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Icebreaker";
    
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
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerClass:[StreamPostCell class] forCellReuseIdentifier:postCellReuseIdentifier];
    [self.tableView registerClass:[ButtonCell class] forCellReuseIdentifier:buttonCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:howToCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:blankCellIdentifier];
}

- (void)getIcebreakers {
    self.loading = true;
    [self.tableView reloadData];
    
    NSString *url = [[NSString alloc] initWithFormat:@"camps/%@/posts/icebreakers", self.camp.identifier];
    
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.stream = [[PostStream alloc] init];
        PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:responseObject error:nil];
        [self.stream appendPage:page];
        
        self.loading = false;
        
        [self.tableView reloadData];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"ManageIcebreakresViewController / getIcebreakers() - error: %@", error);
        //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        
        self.loading = false;
        
        [self.tableView reloadData];
    }];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            if (self.stream.posts.count == 0) {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:howToCellReuseIdentifier forIndexPath:indexPath];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
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
                    titleLabel.textColor = [UIColor bonfireBlack];
                    [cell.contentView addSubview:titleLabel];
                }
                
                UILabel *descriptionLabel = [cell.contentView viewWithTag:12];
                if (!descriptionLabel) {
                    descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 165, self.view.frame.size.width - 48, 32)];
                    descriptionLabel.tag = 12;
                    descriptionLabel.text = @"Introduce new members to the Camp by prompting them to reply to a post when they join";
                    descriptionLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
                    descriptionLabel.textAlignment = NSTextAlignmentCenter;
                    descriptionLabel.textColor = [UIColor bonfireGray];
                    descriptionLabel.numberOfLines = 0;
                    descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
                    CGFloat descriptionHeight = ceilf([descriptionLabel.text boundingRectWithSize:CGSizeMake(descriptionLabel.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: descriptionLabel.font} context:nil].size.height);
                    SetHeight(descriptionLabel, descriptionHeight);
                    [cell.contentView addSubview:descriptionLabel];
                }
                
                UIActivityIndicatorView *spinner = [cell.contentView viewWithTag:13];
                if (!spinner) {
                    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    spinner.tag = 13;
                    spinner.frame = CGRectMake(0, 0, cell.frame.size.width, cell.frame.size.height);
                    [spinner startAnimating];
                    [cell addSubview:spinner];
                }
                
                if (self.loading) {
                    cell.contentView.transform = CGAffineTransformMakeScale(0.5, 0.5);
                    cell.contentView.alpha = 0;
                    cell.contentView.center = CGPointMake(cell.frame.size.width / 2, cell.frame.size.height / 2);
                    
                    if (spinner.alpha == 0) {
                        [spinner startAnimating];
                        [UIView animateWithDuration:0.8f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                            spinner.alpha = 1;
                            spinner.transform = CGAffineTransformMakeScale(1, 1);
                            
                            cell.contentView.transform = CGAffineTransformMakeScale(0.5, 0.5);
                            cell.contentView.alpha = 0;
                        } completion:^(BOOL finished) {
                            
                        }];
                    }
                }
                else {
                    if (spinner.alpha == 1) {
                        [UIView animateWithDuration:0.8f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                            spinner.alpha = 0;
                            spinner.transform = CGAffineTransformMakeScale(0.5, 0.5);
                            
                            cell.contentView.transform = CGAffineTransformMakeScale(1, 1);
                            cell.contentView.alpha = 1;
                        } completion:^(BOOL finished) {
                            [spinner stopAnimating];
                        }];
                    }
                }
                
                return cell;
            }
            else if (self.stream.posts.count > indexPath.row) {
                StreamPostCell *cell = [tableView dequeueReusableCellWithIdentifier:postCellReuseIdentifier forIndexPath:indexPath];
                
                if (cell == nil) {
                    cell = [[StreamPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:postCellReuseIdentifier];
                }
                
                Post *post = self.stream.posts[indexPath.row];
                
                cell.showContext = true;
                cell.showCamptag = true;
                cell.hideActions = false;
                cell.post = post;
                
                cell.lineSeparator.hidden = true;
                
                return cell;
            }
        }
        else if (indexPath.row == 1) {
            ButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:buttonCellReuseIdentifier forIndexPath:indexPath];
            
            if (cell == nil) {
                cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:buttonCellReuseIdentifier];
            }
            
            // Configure the cell...
            if (self.stream.posts.count == 0) {
                cell.buttonLabel.text = @"Choose a Post";
                cell.buttonLabel.textColor = self.view.tintColor;
                cell.buttonLabel.textAlignment = NSTextAlignmentCenter;
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            else {
                cell.buttonLabel.text = @"Choose a New Post";
                cell.buttonLabel.textColor = cell.kButtonColorDefault;
                cell.buttonLabel.textAlignment = NSTextAlignmentLeft;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            return cell;
        }
    }
    
    UITableViewCell *blankCell = [tableView dequeueReusableCellWithIdentifier:blankCellIdentifier forIndexPath:indexPath];
    return blankCell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!self.loading) {
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 12, 0, self.stream.posts.count == 0 ? 12 : 0);
    }
    else {
        self.tableView.separatorInset = UIEdgeInsetsZero;
    }
    
    if (section == 0) {
        if (self.stream.posts.count == 0) {
            return self.loading ? 1 : 2;
        }
        else {
            return 2; // post + "replace icebreaker"
        }
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            if (self.stream.posts.count == 0) {
                // how to set icebreaker dialog
                CGFloat descriptionHeight = ceilf([@"Introduce new members to the Camp by prompting them to reply to a post when they join" boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 48, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular]} context:nil].size.height);
                
                return 165 + descriptionHeight + 24 + (self.loading ? 52 : 0);
            }
            else {
                if (self.stream.posts.count > indexPath.row) {
                    Post *post = self.stream.posts[indexPath.row];
                    return [StreamPostCell heightForPost:post showContext:true showActions:true];
                }
            }
        }
        else if (indexPath.row == 1) {
            return 52;
        }
    }
    
    return 0;
}

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        BFHeaderView *headerView = [[BFHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [BFHeaderView height])];
        headerView.title = @"Active";
        return headerView;
    }
    else if (section == 1) {
        return nil;
        
//        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 110)];
//
//        UIView *upsell = [[UIView alloc] initWithFrame:CGRectMake(12, 16, header.frame.size.width - 24, 94)];
//        upsell.layer.cornerRadius = 10.f;
//        upsell.backgroundColor = [UIColor whiteColor];
//        upsell.layer.shadowOpacity = 1.f;
//        upsell.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
//        upsell.layer.shadowRadius = 2.f;
//        upsell.layer.shadowOffset = CGSizeMake(0, 1);
//        upsell.layer.masksToBounds = false;
//
//        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icebreakerSnowflake"]];
//        imageView.frame = CGRectMake(upsell.frame.size.width / 2 - imageView.frame.size.width / 2, 16, imageView.frame.size.width, imageView.frame.size.height);
//        [upsell addSubview:imageView];
//
//        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(8, imageView.frame.origin.y + imageView.frame.size.height + 10, upsell.frame.size.width - 16, 21)];
//        title.text = @"About Icebreakers";
//        title.textColor = [UIColor bonfireBlack];
//        title.textAlignment = NSTextAlignmentCenter;
//        title.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightSemibold];
//        [upsell addSubview:title];
//
//        // Easily invite new members to introduce themselves with an Icebreaker post after they join your Camp
//        UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(32, title.frame.origin.y + title.frame.size.height + 6, upsell.frame.size.width - 64, 19)];
//        description.text = @"Introduce new members to the Camp with an Icebreaker post when they join";
//        description.textColor = [UIColor bonfireGray];
//        description.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium];
//        description.textAlignment = NSTextAlignmentCenter;
//        description.numberOfLines = 0;
//        description.lineBreakMode = NSLineBreakByWordWrapping;
//        CGFloat height = ceilf([description.text boundingRectWithSize:CGSizeMake(description.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: description.font} context:nil].size.height);
//        SetHeight(description, height);
//        [upsell addSubview:description];
//
//        SetHeight(upsell, description.frame.origin.y + description.frame.size.height + 24);
//        SetHeight(header, upsell.frame.size.height + upsell.frame.origin.y);
//
//        [header addSubview:upsell];
//
//        return header;
    }
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return [BFHeaderView height];
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (self.stream.posts.count > 0 && indexPath.row == 0) {
            Post *post = self.stream.posts[indexPath.row];
            [Launcher openPost:post withKeyboard:NO];
        }
        else if (indexPath.row == 1) {
            SetAnIcebreakerViewController *mibvc = [[SetAnIcebreakerViewController alloc] initWithStyle:UITableViewStyleGrouped];
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
    }
}

- (void)setAnIcebreakerViewController:(SetAnIcebreakerViewController *)viewController didSelectPost:(Post *)post {
    PostStreamPage *page = [[PostStreamPage alloc] initWithDictionary:@{@"data": @[[post toDictionary]]} error:nil];
    
    self.stream = [[PostStream alloc] init];
    [self.stream appendPage:page];
    
    [self.tableView reloadData];
}

@end
