//
//  AutoExceptions.m
//  Hachidori
//
//  Created by Tail Red on 1/31/15.
//  Copyright 2015 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import "AutoExceptions.h"
#import "EasyNSURLConnection.h"
#import "AppDelegate.h"

@implementation AutoExceptions
#pragma mark Importing Exceptions and Auto Exceptions
+(void)importToCoreData{
    AppDelegate * delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    NSManagedObjectContext *moc = [delegate getObjectContext];
    // Check Exceptions
    NSArray *oexceptions = [[NSUserDefaults standardUserDefaults] objectForKey:@"exceptions"];
    if (oexceptions.count > 0) {
        NSLog(@"Importing Exception List");
        NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
        [allExceptions setEntity:[NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc]];
        NSError * error = nil;
        NSArray * exceptions = [moc executeFetchRequest:allExceptions error:&error];
        for (NSDictionary *d in oexceptions) {
            NSString * title = [d objectForKey:@"detectedtitle"];
            BOOL exists = false;
            for (NSManagedObject * entry in exceptions) {
                if ([title isEqualToString:(NSString *)[entry valueForKey:@"detectedTitle"]]) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                NSString * correcttitle = (NSString *)[d objectForKey:@"correcttitle"];
                NSString * showid = (NSString *)[d objectForKey:@"showid"];
                // Add Exceptions to Core Data
                NSManagedObject *obj = [NSEntityDescription
                                        insertNewObjectForEntityForName:@"Exceptions"
                                        inManagedObjectContext: moc];
                // Set values in the new record
                [obj setValue:title forKey:@"detectedTitle"];
                [obj setValue:correcttitle forKey:@"correctTitle"];
                [obj setValue:showid forKey:@"id"];
                [obj setValue:[NSNumber numberWithInt:0] forKey:@"episodeOffset"];
                [obj setValue:[NSNumber numberWithInt:0] forKey:@"episodethreshold"];
            }
        }
        //Save
        [moc save:&error];
        // Erase exceptions data from preferences
        [[NSUserDefaults standardUserDefaults] setObject:[[NSMutableArray alloc] init] forKey:@"exceptions"];
    }
}
+(void)updateAutoExceptions{
    // This method retrieves the auto exceptions JSON and import new entries
    NSURL *url = [NSURL URLWithString:@"https://gist.githubusercontent.com/chikorita157/c0bd93d061bb4c5fb081/raw/autoexceptions.json"];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Test API
    [request startRequest];
    // Get Status Code
    int statusCode = [request getStatusCode];
    switch (statusCode) {
        case 200:{
            NSLog(@"Updating Auto Exceptions!");
            //Parse and Import
            NSData *jsonData = [request getResponseData];
            NSError *error = nil;
            NSArray * a = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
            AppDelegate * delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
            NSManagedObjectContext *moc = [delegate getObjectContext];
            for (NSDictionary *d in a) {
                NSString * detectedtitlea = [d objectForKey:@"detectedtitle"];
                NSString * groupa = [d objectForKey:@"group"];
                NSString * correcttitlea = [d objectForKey:@"correcttitle"];
                BOOL exists = false;
                NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
                [allExceptions setEntity:[NSEntityDescription entityForName:@"AutoExceptions" inManagedObjectContext:moc]];
                NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(detectedTitle == %@) AND (group == %@) AND (correctTitle == %@)", detectedtitlea, groupa, correcttitlea];
                [allExceptions setPredicate:predicate];
                error= nil;
                NSArray * aExceptions = [moc executeFetchRequest:allExceptions error:&error];
                if (aExceptions.count > 0) {
                    for (NSManagedObject * entry in aExceptions) {
                        @autoreleasepool {
                            NSString * title = [entry valueForKey:@"detectedTitle"];
                            NSString * group = [entry valueForKey:@"group"];
                            NSString * correcttitle = [entry valueForKey:@"correctTitle"];
                            if ([title isEqualToString:detectedtitlea]&& [group isEqualToString:groupa] && [correcttitle isEqualToString:correcttitlea]) {
                                exists = true;
                            }
                        }
                    }
                }
                // Check to see if it exists on the list already
                if (exists) {
                    //Check next title
                    continue;
                }
                else{
                    NSError * error = nil;
                    // Add Entry to Auto Exceptions
                    NSManagedObject *obj = [NSEntityDescription
                                            insertNewObjectForEntityForName:@"AutoExceptions"
                                            inManagedObjectContext: moc];
                    // Set values in the new record
                    [obj setValue:[d objectForKey:@"detectedtitle"] forKey:@"detectedTitle"];
                    [obj setValue:[d objectForKey:@"correcttitle"] forKey:@"correctTitle"];
                    [obj setValue:[d objectForKey:@"offset"] forKey:@"episodeOffset"];
                    [obj setValue:[d objectForKey:@"threshold"] forKey:@"episodethreshold"];
                    [obj setValue:[d objectForKey:@"group"] forKey:@"group"];
                    //Save
                    [moc save:&error];
                }
            }
            // Set the last updated date
            [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"ExceptionsLastUpdated"];
            break;
        }
        default:
            NSLog(@"Auto Exceptions List Update Failed!");
            break;
    }
}

@end
