//
//  Tests.m
//  Tests
//
//  Created by Boisy Pitre on 10/18/17.
//

#import <XCTest/XCTest.h>
#import "NSString+DriveWire.h"

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBackspace {
    NSString *testString = @"\b\b\b";
    NSString *newString = [testString stringByProcessingBackspaces];
    XCTAssertEqual([newString length], 0);
    
    testString = @"hi\bo";
    newString = [testString stringByProcessingBackspaces];
    XCTAssertTrue([newString isEqualToString:@"ho"]);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
