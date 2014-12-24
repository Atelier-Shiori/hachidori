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
    NSArray * testdata;
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
    NSUInteger icount = [testdata count];
    int count = (int)icount;
    Recognition * reg = [[Recognition alloc] init];
    NSLog(@"Testing a dataset with %i filenames", count);
    NSLog(@"Starting Test...\n\n");
    for (NSDictionary *d in testdata) {
        NSString * filename = [d objectForKey:@"filename"];
        NSString * expectedtitle;
        if ([d objectForKey:@"expectedtitle"] != [NSNull null]) {
            expectedtitle = [d objectForKey:@"expectedtitle"];
        }
        NSLog(@"Testing: %@", filename);
        NSDictionary * parsedfile = [reg recognize:filename];
        NSNumber * season = [parsedfile objectForKey:@"season"];
        NSDictionary * result = [haengine runUnitTest:[parsedfile objectForKey:@"title"] episode:[parsedfile objectForKey:@"episode"] season:[season intValue]];
        if ([result count] > 0) {
            NSLog(@"Detected as %@. Slug: %@", [result objectForKey:@"title"], [result objectForKey:@"slug"]);
            if (![expectedtitle isEqualToString:[NSString stringWithFormat:@"%@", [result objectForKey:@"title"]]] && [expectedtitle length] > 0) {
                NSLog(@"Incorrect Match!");
                incorrect++;
            }
            else if ([expectedtitle length] == 0){
                // Expected Title missing, subtract it from count.
                NSLog(@"Note: Title not included in the count. Please add this to the testdata.json file:");
                NSLog(@"\"expectedtitle\":\"%@\"",[result objectForKey:@"title"]);
                count--;
            }
        }
        else{
            NSLog(@"Not found");
            fail = fail+1;
        }
        NSLog(@"----");
    }
    if (fail > 0) {
        // Test Failed, title couldn't be found
        NSLog(@"%i titles could not be found", fail);
        XCTAssert(NO, @"Test Failed: There are titles that couldn't be found");
    }
    else{
        // Calculate Results
        float acc = ((count - incorrect)/(float)count);
        NSLog(@"There are %i incorrect title(s) out of %i title(s). Accuracy: %f", incorrect, count, acc * 100);
        XCTAssert(YES, @"No Errors");
    }
}

@end
