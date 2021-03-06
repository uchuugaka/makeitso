//
//  MISGeneratorTests.m
//  MISGeneratorTests
//
//  Created by Todd Ditchendorf on 12/26/14.
//  Copyright (c) 2014 Todd Ditchendorf. All rights reserved.
//

#import "MISBaseTestCase.h"
#import "MISGenerator.h"

@interface MISGeneratorTests : MISBaseTestCase

@end

@implementation MISGeneratorTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    self.mock = nil;
    [super tearDown];
}

- (void)testExample {
    NSMutableDictionary *args = [NSMutableDictionary dictionary];
    
    args[KEY_DELETE_EXISTING] = @YES;
    args[KEY_DB_FILENAME] = @"testdb";
    args[KEY_DB_DIR_PATH] = NSTemporaryDirectory();
    args[KEY_OUTPUT_SRC_DIR_PATH] = NSTemporaryDirectory();
    args[KEY_HEADER_FILE_PATHS] = @[NSTemporaryDirectory()];
    
    self.mock = [OCMockObject mockForProtocol:@protocol(MISGeneratorDelegate)];
    
    MISGenerator *gen = [[[MISGenerator alloc] initWithDelegate:(id)self.mock] autorelease];
    [gen execute:args];
    
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
