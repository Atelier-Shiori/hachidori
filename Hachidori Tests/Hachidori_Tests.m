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
    NSArray * filenames;
}
@end

@implementation Hachidori_Tests
- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    haengine = [[Hachidori alloc] init];
    // Load Test Data
    NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];
    NSData *dataset = [NSData dataWithContentsOfFile:[mainBundle pathForResource: @"testdata" ofType: @"json"]
                                                 options:0
                                                   error:NULL];
    NSError * error;
    filenames = [NSArray alloc];
    filenames = [NSJSONSerialization JSONObjectWithData:dataset options:kNilOptions error:&error];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRecognition {
    // This tests the title recognition
    // Test an array of file names (Retrieve a JSON file from local drive)
    int fail = 0;
    Recognition * reg = [[Recognition alloc] init];
    for (NSString * filename in filenames) {
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
