//
//  SearchResultsTableView.m
//  Pulse
//
//  Created by Austin Valleskey on 10/13/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RoomSearchTableView.h"
#import "SearchResultCell.h"
#import "Session.h"

@implementation RoomSearchTableView
    
static NSString * const reuseIdentifier = @"Result";
    
- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:UITableViewStyleGrouped];
    if (self) {
        [self setup];
    }
    
    return self;
}
- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    
    return self;
}
    
- (void)setup {
    self.delegate = self;
    self.dataSource = self;
    self.backgroundColor = [UIColor whiteColor];
    self.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.separatorInset = UIEdgeInsetsMake(0, self.frame.size.width, 0, 0);
    self.separatorColor = [UIColor colorWithWhite:0.85 alpha:1];
    [self registerClass:[SearchResultCell class] forCellReuseIdentifier:reuseIdentifier];
}
    
- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}
    
- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    _currentKeyboardHeight = keyboardFrameBeginRect.size.height;
    
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomPadding = window.safeAreaInsets.bottom;
    
    self.contentInset = UIEdgeInsetsMake(self.contentInset.top, 0, _currentKeyboardHeight - bottomPadding + 24, 0);
    self.scrollIndicatorInsets = UIEdgeInsetsMake(self.contentInset.top, 0, _currentKeyboardHeight - bottomPadding, 0);
}
    
- (void)keyboardWillDismiss:(NSNotification *)notification {
    _currentKeyboardHeight = 0;
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    [UIView animateWithDuration:[duration floatValue] delay:0 options:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue] << 16 animations:^{
        self.contentInset = UIEdgeInsetsMake(self.contentInset.top, 0, 0, 0);
        self.scrollIndicatorInsets = self.contentInset;
    } completion:nil];
}
    
- (void)emptySearchResults {
    self.searchResults = [[NSMutableDictionary alloc] initWithDictionary:@{@"rooms": @[], @"users": @[]}];
}
- (void)initRecentSearchResults {
    self.recentSearchResults = [[NSMutableArray alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults arrayForKey:@"recents_search"]) {
        NSArray *recents = [defaults arrayForKey:@"recents_search"];
        self.recentSearchResults = [[NSMutableArray alloc] initWithArray:recents];
    }
}
- (NSString *)convertToString:(id)object {
    return [NSString stringWithFormat:@"%@", object];
}
- (void)addToRecents:(NSDictionary *)json {
    // add object or push to front if in recents
    BOOL existingMatch = false;
    for (NSInteger i = 0; i < [self.recentSearchResults count]; i++) {
        NSDictionary *result = self.recentSearchResults[i];
        if (json[@"type"] && json[@"id"] &&
            result[@"type"] && result[@"id"]) {
            if ([json[@"type"] isEqualToString:result[@"type"]] && [[self convertToString:json[@"id"]] isEqualToString:[self convertToString:result[@"id"]]]) {
                NSLog(@"we found an existing match!!!!!!!!!!!!!!!!!!!");
                existingMatch = true;
                
                [self.recentSearchResults removeObjectAtIndex:i];
                [self.recentSearchResults insertObject:result atIndex:0];
                break;
            }
        }
    }
    if (!existingMatch) {
        [self.recentSearchResults insertObject:json atIndex:0];
        
        if (self.recentSearchResults.count > 8) {
            self.recentSearchResults = [[NSMutableArray alloc] initWithArray:[self.recentSearchResults subarrayWithRange:NSMakeRange(0, 8)]];
        }
    }
    
    // update NSUserDefaults
    [[NSUserDefaults standardUserDefaults] setObject:self.recentSearchResults forKey:@"recents_search"];
}
- (void)getSearchResults {
    /*
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success || !success) {
            NSString *url = [NSString stringWithFormat:@"%@/%@/search", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
            
            [self.manager GET:url parameters:@{@"q": self.textField.text} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"LauncherNavigationViewController / getSearchResults() success! ✅");
                
                NSDictionary *responseData = (NSDictionary *)responseObject[@"data"];
                
                self.searchResults = [[NSMutableDictionary alloc] initWithDictionary:responseData];
                
                [self reloadData];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"FeedViewController / getPosts() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                [self reloadData];
            }];
        }
    }];
     */
    [self reloadData];
}
    
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[SearchResultCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    }
    /*
    
    BOOL highlighted = false;
    if ([self showRecents] && indexPath.section == 0 && indexPath.row == 0) {
        highlighted = true;
    }
    else {
        BOOL roomsResults = self.searchResults && self.searchResults[@"results"] &&
        self.searchResults[@"results"][@"rooms"] && [self.searchResults[@"results"][@"rooms"] count] > 0;
        BOOL userResults = self.searchResults && self.searchResults[@"results"] &&
        self.searchResults[@"results"][@"users"] && [self.searchResults[@"results"][@"users"] count] > 0;
        
        if (roomsResults && indexPath.section == 1 && indexPath.row == 0) {
            // has at least one room
            highlighted = true;
        }
        else if (!roomsResults && userResults && indexPath.section == 2 && indexPath.row == 0) {
            highlighted = true;
        }
    }
    
    if (highlighted) {
        cell.selectionBackground.hidden = false;
        cell.lineSeparator.hidden = true;
    }
    else {
        cell.selectionBackground.hidden = true;
        cell.lineSeparator.hidden = false;
    }
    
    // -- Type --
    int type = 0;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            if ([self.topViewController isKindOfClass:[HomeViewController class]]) {
                type = 0;
            }
            else if ([self.topViewController isKindOfClass:[RoomViewController class]]) {
                type = 1;
            }
            else if ([self.topViewController isKindOfClass:[ProfileViewController class]]) {
                type = 2;
            }
            
            cell.textLabel.text = self.topViewController.title;
        }
        else {
            type = 0;
            cell.textLabel.text = @"Home";
        }
        
        
        if (type == 0) {
            // 0 = page inside Home (e.g. Timeline, My Rooms, Trending)
            cell.imageView.image = [UIImage imageNamed:@"searchHomeIcon"];
        }
        else if (type == 1) {
            // 1 = Room
            cell.imageView.backgroundColor = [UIColor blackColor];
            
            BOOL useLiveCount = false;
            if (useLiveCount) {
                cell.detailTextLabel.textColor = [UIColor colorWithDisplayP3Red:0.87 green:0.09 blue:0.09 alpha:1];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%i LIVE", 24];
            }
            else {
                cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%i MEMBERS", 402];
            }
        }
        else {
            // 2 = User
            [cell.imageView sd_setImageWithURL:[NSURL URLWithString:@"https://image.ibb.co/nGXaye/yeezy.png"] placeholderImage:[UIImage imageNamed:@"anonymous"] options:SDWebImageRefreshCached];
        }
    }
    else {
        NSDictionary *json;
        if (indexPath.section == 1) {
            type = 1;
            json = self.searchResults[@"results"][@"rooms"][indexPath.row];
        }
        else if (indexPath.section == 2) {
            type = 2;
            json = self.searchResults[@"results"][@"users"][indexPath.row];
        }
        else if (indexPath.section == 3) {
            // mix of types
            json = self.recentSearchResults[indexPath.row];
            if (json[@"type"]) {
                if ([json[@"type"] isEqualToString:@"room"]) {
                    type = 1;
                }
                else if ([json[@"type"] isEqualToString:@"user"]) {
                    type = 2;
                }
            }
        }
        
        if (type == 0) {
            // 0 = page inside Home (e.g. Timeline, My Rooms, Trending)
            cell.textLabel.text = @"Page";
            cell.imageView.image = [UIImage new];
            cell.imageView.backgroundColor = [UIColor blueColor];
        }
        else if (type == 1) {
            Room *room = [[Room alloc] initWithDictionary:json error:nil];
            // 1 = Room
            cell.textLabel.text = room.attributes.details.title;
            cell.imageView.backgroundColor = [self colorFromHexString:room.attributes.details.color];
            
            BOOL useLiveCount = false;
            if (useLiveCount) {
                cell.detailTextLabel.textColor = [UIColor colorWithDisplayP3Red:0.87 green:0.09 blue:0.09 alpha:1];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%li LIVE", (long)room.attributes.summaries.counts.live];
            }
            else {
                cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld %@", (long)room.attributes.summaries.counts.members, (room.attributes.summaries.counts.members == 1 ? @"MEMBER" : @"MEMBERS")];
            }
        }
        else {
            NSError *error;
            User *user = [[User alloc] initWithDictionary:json error:&error];
            
            // 2 = User
            cell.textLabel.text = user.attributes.details.displayName;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"@%@", [user.identifier uppercaseString]];
            if (user.attributes.details.media.profilePicture != nil && user.attributes.details.media.profilePicture.length > 0) {
                [cell.imageView sd_setImageWithURL:[NSURL URLWithString:user.attributes.details.media.profilePicture] placeholderImage:[UIImage imageNamed:@"anonymous"] options:SDWebImageRefreshCached];
            }
            else {
                cell.imageView.image = [UIImage imageNamed:@"anonymous"];
            }
        }
    }
    
    if (type == 0) {
        // 0 = page inside Home (e.g. Timeline, My Rooms, Trending)
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        cell.detailTextLabel.text = @"";
    }
    else if (type == 1) {
        // 1 = Room
    }
    else if (type == 2) {
        // 2 = Usercell.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
    }
    
    cell.type = type;
     */
    
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    /*
    [self.textField resignFirstResponder];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            self.textField.text = self.topViewController.title;
        }
        else if (![self.topViewController isKindOfClass:[HomeViewController class]]) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
    else if (indexPath.section == 1) {
        NSDictionary *roomJSON = self.searchResults[@"results"][@"rooms"][indexPath.row];
        Room *room = [[Room alloc] initWithDictionary:roomJSON error:nil];
        
        [self addToRecents:roomJSON];
        
        [self openRoom:room];
    }
    else if (indexPath.section == 2) {
        NSDictionary *userJSON = self.searchResults[@"results"][@"users"][indexPath.row];
        User *user = [[User alloc] initWithDictionary:userJSON error:nil];
        
        [self addToRecents:userJSON];
        
        [self openProfile:user];
    }
    else if (indexPath.section == 3) {
        NSDictionary *json = self.recentSearchResults[indexPath.row];
        if ([json objectForKey:@"type"]) {
            if ([json[@"type"] isEqualToString:@"user"]) {
                User *user = [[User alloc] initWithDictionary:json error:nil];
                
                [self addToRecents:json];
                
                [self openProfile:user];
            }
            else if ([json[@"type"] isEqualToString:@"room"]) {
                Room *room = [[Room alloc] initWithDictionary:json error:nil];
                
                [self addToRecents:json];
                
                [self openRoom:room];
            }
        }
    }
    
    [self emptySearchResults];
    [self reloadData];
     */
}
    
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    /*
    if (!self.isCreatingPost && section == 0 && (self.textField.text.length == 0 || [[self.topViewController.title lowercaseString] isEqualToString:[self.textField.text lowercaseString]])) {
        if ([self.topViewController isKindOfClass:[HomeViewController class]]) {
            return 1;
        }
        else {
            return 2;
        }
    }
    else {
        if ([self showRecents]) {
            if (self.recentSearchResults && section == 3) {
                return [self.recentSearchResults count];
            }
        }
        else {
            if (section == 1) {
                // rooms
                if (self.searchResults && self.searchResults[@"results"] && self.searchResults[@"results"][@"rooms"]) {
                    return [self.searchResults[@"results"][@"rooms"] count];
                }
            }
            else if (section == 2) {
                // users
                if (self.searchResults && self.searchResults[@"results"] && self.searchResults[@"results"][@"users"]) {
                    return [self.searchResults[@"results"][@"users"] count];
                }
            }
        }
    }*/
    
    return 0;
}
    
- (BOOL)showRecents  {
    return true; // (self.textField.text.length == 0 || ([self.topViewController isKindOfClass:[HomeViewController class]] && [[self.topViewController.title lowercaseString] isEqualToString:[self.textField.text lowercaseString]]));
}
    
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    CGFloat headerHeight = 50;
    if ([self showRecents]) {
        if (section == 0) {
            return 16;
        }
        else if (section == 3) {
            return headerHeight;
        }
    }
    else {
        if (section == 1 && self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"rooms"] && [self.searchResults[@"results"][@"rooms"] count] > 0) {
            return headerHeight;
        }
        else if (section == 2 && self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"users"] && [self.searchResults[@"results"][@"users"] count] > 0) {
            return headerHeight;
        }
    }
    
    return 0;
}
    
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    /*
    if (section == 0) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 16)];
        header.backgroundColor = [UIColor whiteColor];
        return header;
    }
    else if (((section == 1 || section == 2) && ![self showRecents]) || (section == 3 && [self showRecents])) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 24, self.view.frame.size.width - 32, 19)];
        if ([self showRecents]) {
            title.text = @"Recents";
        }
        else {
            if ((section == 1 && self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"rooms"] && [self.searchResults[@"results"][@"rooms"] count] > 0) ||
                (section == 2 && self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"users"] && [self.searchResults[@"results"][@"users"] count] > 0)) {
                if (section == 1) {
                    title.text = @"Rooms";
                }
                else if (section == 2) {
                    title.text = @"Users";
                }
            }
            else {
                return nil;
            }
        }
        
        title.textAlignment = NSTextAlignmentLeft;
        title.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
        title.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        
        [header addSubview:title];
        
        return header;
    }
    */
    
    return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}
- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}
    
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (self.alpha != 1 || self.isHidden) {
        self.hidden = false;
        self.transform = CGAffineTransformMakeScale(0.9, 0.9);
        self.alpha = 0;
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.transform = CGAffineTransformMakeScale(1, 1);
            self.alpha = 1;
        } completion:^(BOOL finished) {
        }];
    }
}
    
- (void)textFieldDidEndEditing:(UITextField *)textField {
    /*
    if ([self.topViewController isKindOfClass:[RoomViewController class]]) {
        RoomViewController *currentRoom = (RoomViewController *)self.topViewController;
        [self updateBarColor:currentRoom.theme withAnimation:1 statusBarUpdateDelay:NO];
    }
    if ([self.topViewController isKindOfClass:[HomeViewController class]]) {
        HomeViewController *currentRoom = (HomeViewController *)self.topViewController;
        if (currentRoom.page == 1) {
            [self setShadowVisibility:false withAnimation:true];
        }
    }
    [self updateNavigationBarItemsWithAnimation:YES];
    
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = true;
    }];*/
}
    
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    /*
    if (self.textField.text.length == 0 || [[self.topViewController.title lowercaseString] isEqualToString:[self.textField.text lowercaseString]]) {
        [self tableView:self didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
    else {
        if (self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"rooms"] && [self.searchResults[@"results"][@"rooms"] count] > 0) {
            // has at least one room
            [self tableView:self didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
        }
        else if (self.searchResults && [self.searchResults objectForKey:@"results"] && [[self.searchResults objectForKey:@"results"] objectForKey:@"users"] && [self.searchResults[@"results"][@"users"] count] > 0) {
            [self tableView:self didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
        }
    }
    */
    
    return FALSE;
}
    
    //Setter method
- (void)setDataType:(int)dataType {
    NSLog(@"Setting data type to: %i", dataType);
    
    if (_dataType != dataType) {
        _dataType = dataType;
        [self reloadData];
        
        //if (_dataType != tableCategoryPost) {
            // long press for actions
            //[self createContextSheet];
        //}
    }
}

@end
