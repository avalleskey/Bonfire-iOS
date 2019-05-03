//
//  ErrorCodes.m
//  Pulse
//
//  Created by Austin Valleskey on 10/11/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ErrorCodes.h"

@implementation ErrorCodes

/**
 * Errors 400-499: Authentication/Client error
 */
const NSInteger BAD_AUTHENTICATION    = 400;
const NSInteger MISSING_ACCESS_TOKEN  = 401;
const NSInteger OUT_OF_DATE_CLIENT    = 410;
const NSInteger IDENTITY_REQUIRED     = 420;
const NSInteger BAD_ORIGIN            = 440;
const NSInteger BAD_ACCESS_TOKEN      = 450;
const NSInteger BAD_REFRESH_TOKEN     = 451;
const NSInteger MISMATCH_TOKEN        = 452;
const NSInteger BAD_REFRESH_LOGIN_REQ = 460;

/**
 * Errors 600-699: Action failure
 */
const NSInteger OPERATION_NOT_PERMITTED    = 600;
const NSInteger USER_MISSING_PERMISSION    = 601;
const NSInteger RESOURCE_ACTION_FAILURE    = 610;
const NSInteger MISSING_PARAMETER          = 620;
const NSInteger INVALID_PARAMETER          = 621;
const NSInteger INVALID_MEDIA              = 630;
const NSInteger ROOM_MIN_MEMBERS_VIOLATION = 640;
const NSInteger IDENTIFIER_TAKEN           = 650;
const NSInteger NO_CHANGE_OCCURRED         = 660;
const NSInteger BAD_MEDIA_COMBINATION      = 670;

/**
 * Errors 700-799: Resource failure
 */
const NSInteger RESOURCE_VALIDITY_FAILURE     = 700;
const NSInteger ROOM_NOT_EXISTS               = 701;
const NSInteger USER_NOT_EXISTS               = 702;
const NSInteger POST_NOT_EXISTS               = 703;
const NSInteger ROOM_INACCESSIBLE_BLOCKED     = 711;
const NSInteger USER_INACCESSIBLE_BLOCKED     = 712;
const NSInteger POST_INACCESSIBLE             = 713;
const NSInteger SEARCH_TOO_COMPLEX            = 720;
const NSInteger RESOURCE_OWNERSHIP_FAILURE    = 730;
const NSInteger ROOM_INACCESSIBLE_BLOCKS_THEM = 740;

/**
 * Errors 800-899: User information failure
 */
const NSInteger USER_PASSWORD_REQ_RESET = 800;
const NSInteger USER_PROFILE_SUSPENDED  = 810;
const NSInteger USER_EMAIL_TAKEN        = 820;
const NSInteger USER_USERNAME_TAKEN     = 830;

/**
 * Errors 900-999: Generic errors
 */
const NSInteger INVALID_HTTP_METHOD = 900;
const NSInteger BAD_API_VERSION     = 910;
// ...
const NSInteger DATABASE_QUERY_CONFLICT  = 970;
const NSInteger DATABASE_QUERY_ERROR     = 980;
const NSInteger DEFAULT_UNKNOWN_ERROR    = 990;

@end
