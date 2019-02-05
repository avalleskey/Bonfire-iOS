//
//  TappableButton.m
//  Pulse
//
//  Created by Austin Valleskey on 12/13/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "TappableButton.h"

@implementation TappableButton

-(BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect newArea = CGRectMake(self.bounds.origin.x - 5, self.bounds.origin.y - 5, self.bounds.size.width + 10, self.bounds.size.height + 10);
    
    return CGRectContainsPoint(newArea, point);
}

@end
