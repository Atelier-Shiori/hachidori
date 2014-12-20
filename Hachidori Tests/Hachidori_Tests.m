//
//  Hachidori_Tests.m
//  Hachidori Tests
//
//  Created by Nanoha Takamachi on 2014/12/19.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "Hachidori.h"
#import "EasyNSURLConnection.h"
#import "Recognition.h"

@interface Hachidori_Tests : XCTestCase{
    Hachidori * haengine;
}
@end

@implementation Hachidori_Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    haengine = [[Hachidori alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRecognition {
    // This tests the title recognition
    // Test an array of file names (Retrieve a JSON file from local drive)
    int fail = 0;
    NSArray * a = [[NSArray alloc] initWithObjects:@"[Cthuko] Shirobako - 09 [720p H264 AAC][286FB843].mkv", @"[FFF] Love Live! S2 - 01 [954C4CE1].mkv", @"[Underwater-FFF] No Game No Life - 10 (720p) [5F3B4A4B].mkv", nil];
    Recognition * reg = [[Recognition alloc] init];
    for (NSString * filename in a) {
        NSLog(@"Testing: %@", filename);
        NSDictionary * parsedfile = [reg recognize:filename];
        NSNumber * season = [parsedfile objectForKey:@"season"];
        NSDictionary * result = [haengine runUnitTest:[parsedfile objectForKey:@"title"] episode:[parsedfile objectForKey:@"episode"] season:[season intValue]];
        if ([result count] > 0) {
            NSLog(@"%@", result);
        }
        else{
            fail = fail+1;
        }
    }
    if (fail > 0) {
        XCTAssert(NO, @"Title not found");
    }
    else{
    XCTAssert(YES, @"Complete");
    }
}

@end
