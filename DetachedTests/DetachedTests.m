//
//  DetachedTests.m
//  DetachedTests
//
//  Created by Zack Hobson on 7/22/13.
//  Copyright (c) 2013 Zack Hobson. All rights reserved.
//

#import "DetachedTests.h"

@implementation DetachedTests

- (void)setUp
{
    [super setUp];
    manager = [[SessionManager alloc] init];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testNoSessions
{
    NSString* output = @"No Sockets found in /var/folders/whatever/.screen.\r\n";
    [manager readSessionsFromString:output failedWithError:nil];
    STAssertEquals((NSUInteger)0, [[manager sessionList] count], @"incorrect session count");
    STAssertEquals([[manager screenDir] compare:@"/var/folders/whatever/.screen"], NSOrderedSame, @"incorrect screen dir");
}

- (void)testAttachedAndDetached
{
    NSString* sessions = @"There are screens on:\r\n\
    15616.foo       (Attached)\r\n\
    3553.javascript (Detached)\r\n\
    84537.yeah      (Attached)\r\n\
    99145.foo       (Attached)\r\n\
    4 Sockets in /var/folders/dh/zr_tfqdx2cgdx9587ybwmnnm0000gn/T/.screen.\r\n";
    [manager readSessionsFromString:sessions failedWithError:nil];
    STAssertEquals([[manager sessionList] count], (NSUInteger)4, @"incorrect session count");
}

@end
