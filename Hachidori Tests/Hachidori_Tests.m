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
#import "Recognition.h"
#import "AppDelegate.h"
#import "AutoExceptions.h"

@interface Hachidori_Tests : XCTestCase{
    Hachidori * haengine;
    NSArray * testdata;
}
@end

@implementation Hachidori_Tests
- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    haengine = [[Hachidori alloc] init];
    AppDelegate * delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    //Check for latest Auto Exceptions
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"] timeIntervalSinceNow] < -604800 ||[[NSUserDefaults standardUserDefaults] objectForKey:@"ExceptionsLastUpdated"] == nil ) {
        // Has been 1 Week, update Auto Exceptions
        [AutoExceptions updateAutoExceptions];
    }
    // Set Context
    [haengine setManagedObjectContext:[delegate getObjectContext]];
    // Load Test Data
    NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];
    NSData *dataset = [NSData dataWithContentsOfFile:[mainBundle pathForResource: @"testdata" ofType: @"json"]
                                                 options:0
                                                   error:NULL];
    NSError * error;
   testdata = [NSArray alloc];
    testdata= [NSJSONSerialization JSONObjectWithData:dataset options:kNilOptions error:&error];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRecognition {
    // This tests the title recognition
    // Test an array of file names (Retrieve a JSON file from local drive)
    int fail = 0;
    int incorrect = 0;
    NSUInteger icount = testdata.count;
    int count = (int)icount;
    Recognition * reg = [[Recognition alloc] init];
    NSLog(@"Testing a dataset with %i filenames", count);
    NSLog(@"Starting Test...\n\n");
    for (NSDictionary *d in testdata) {
        @autoreleasepool {
        NSString * filename = d[@"filename"];
        NSString * expectedtitle;
        if (d[@"expectedtitle"] != [NSNull null]) {
            expectedtitle = d[@"expectedtitle"];
        }
        NSLog(@"Testing: %@", filename);
        NSDictionary * parsedfile = [reg recognize:filename];
        NSNumber * season = parsedfile[@"season"];
        NSString * type;
        if (((NSArray *)parsedfile[@"types"]).count > 0) {
            type = (parsedfile[@"types"])[0];
        }
        else{
            type = @"";
        }
        NSDictionary * result = [haengine runUnitTest:parsedfile[@"title"] episode:parsedfile[@"episode"] season:season.intValue group:parsedfile[@"group"] type:type];
            NSDictionary * titles = result[@"titles"];
            NSString * title = titles[@"en_jp"];
        if (result.count > 0) {
            NSLog(@"Detected as %@. Slug: %@", title, result[@"slug"]);
            if (![expectedtitle isEqualToString:title] && expectedtitle.length > 0) {
                NSLog(@"Incorrect Match!");
                incorrect++;
            }
            else if (expectedtitle.length == 0){
                // Expected Title missing, subtract it from count.
                NSLog(@"Note: Title not included in the count. Please add this to the testdata.json file:");
                NSLog(@"\"expectedtitle\":\"%@\"",title);
                count--;
            }
        }
        else{
            NSLog(@"Not found");
            fail = fail+1;
        }
        NSLog(@"----");
        }
    }
    if (fail > 0) {
        // Test Failed, title couldn't be found
        NSLog(@"%i titles could not be found", fail);
        XCTAssert(NO, @"Test Failed: There were titles that couldn't be found");
    }
    else{
        // Calculate Results
        float acc = ((count - incorrect)/(float)count);
        NSLog(@"There are %i incorrect title(s) out of %i title(s). Accuracy: %f", incorrect, count, acc * 100);
        if (acc < 0.95) {
            XCTAssert(NO, @"Failed: Accuracy is bellow the 95 percent accuracy threshold");
        }
        else{
            XCTAssert(YES, @"No Errors");
        }
    }
}

@end
