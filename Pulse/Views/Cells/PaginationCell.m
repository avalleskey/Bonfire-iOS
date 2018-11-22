//
//  PaginationCell.m
//  Hallway App
//
//  Created by Austin Valleskey on 6/18/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "PaginationCell.h"

@implementation PaginationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        self.loading = false;
        
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.spinner.frame = CGRectMake(0, 0, 40, 40);
        [self.contentView addSubview:self.spinner];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.separatorInset = UIEdgeInsetsMake(0, screenWidth, 0, 0);
    }
    else {
        
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.spinner.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

@end
