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
    STAssertEqualObjects(manager.screenDir, @"/var/folders/whatever/.screen", @"incorrect screen dir");
    STAssertEquals((NSUInteger)0, [[manager sessionList] count], @"incorrect session count");
}

- (void)testSingleSession
{
    NSString* sessions = @"There are screens on:\r\n\
	95972.foobaz	(Detached)\r\n\
1 Socket in /var/folders/funtimes/.screen.\r\n";
    [manager readSessionsFromString:sessions failedWithError:nil];
    STAssertEqualObjects(manager.screenDir, @"/var/folders/funtimes/.screen", @"incorrect screen dir");
    STAssertEquals([[manager sessionList] count], (NSUInteger)1, @"incorrect session count");
}

- (void)testAttachedAndDetached
{
    NSString* sessions = @"There are screens on:\r\n\
    15616.foo       (Attached)\r\n\
    3553.javascript (Detached)\r\n\
    84537.yeah      (Attached)\r\n\
    99145.foo       (Attached)\r\n\
4 Sockets in /var/folders/however/.screen.\r\n";
    [manager readSessionsFromString:sessions failedWithError:nil];
    STAssertEqualObjects([manager screenDir], @"/var/folders/however/.screen", @"incorrect screen dir");
    STAssertEquals([[manager sessionList] count], (NSUInteger)4, @"incorrect session count");
}

@end
