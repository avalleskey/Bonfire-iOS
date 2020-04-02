//
//  NSStringValidationTests.m
//  PulseTests
//
//  Created by Austin Valleskey on 3/17/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+Validation.h"

@interface NSStringValidationTests : XCTestCase

@end

@implementation NSStringValidationTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testUsernameValidation {
    XCTAssertEqual([@"hugo" validateBonfireUsername], BFValidationErrorNone);
    XCTAssertEqual([@"hugo563" validateBonfireUsername], BFValidationErrorNone);
    XCTAssertEqual([@"8473023937" validateBonfireUsername], BFValidationErrorContainsInvalidCharacters);
    XCTAssertEqual([@"" validateBonfireUsername], BFValidationErrorTooShort);
    
    [self measureBlock:^{
        XCTAssertEqual([@"hugo563" validateBonfireUsername], BFValidationErrorNone);
    }];
}

- (void)testPhoneNumberValidation {
    XCTAssertEqual([@"hugo" validateBonfirePhoneNumber], BFValidationErrorInvalidPhoneNumber);
    XCTAssertEqual([@"1" validateBonfirePhoneNumber], BFValidationErrorInvalidPhoneNumber);
    XCTAssertEqual([@"847302393" validateBonfirePhoneNumber], BFValidationErrorInvalidPhoneNumber);
    
    XCTAssertEqual([@"8473023937" validateBonfirePhoneNumber], BFValidationErrorNone);
    XCTAssertEqual([@"18473023937" validateBonfirePhoneNumber], BFValidationErrorNone);
    XCTAssertEqual([@"+18473023937" validateBonfirePhoneNumber], BFValidationErrorNone);
    XCTAssertEqual([@"+1 (847) 302-3937" validateBonfirePhoneNumber], BFValidationErrorNone);
    XCTAssertEqual([@"1 (847) 302-3937" validateBonfirePhoneNumber], BFValidationErrorNone);
    
    XCTAssertEqual([@"+972 54-6529330‬" validateBonfirePhoneNumber], BFValidationErrorNone);
    XCTAssertEqual([@"+972546529330‬" validateBonfirePhoneNumber], BFValidationErrorNone);
    
    [self measureBlock:^{
        XCTAssertEqual([@"18473023937" validateBonfirePhoneNumber], BFValidationErrorNone);
    }];
}

@end
