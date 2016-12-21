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
            NSString * title = d[@"detectedtitle"];
            BOOL exists = false;
            for (NSManagedObject * entry in exceptions) {
                if ([title isEqualToString:(NSString *)[entry valueForKey:@"detectedTitle"]]) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                NSString * correcttitle = (NSString *)d[@"correcttitle"];
                NSString * showid = (NSString *)d[@"showid"];
                // Add Exceptions to Core Data
                NSManagedObject *obj = [NSEntityDescription
                                        insertNewObjectForEntityForName:@"Exceptions"
                                        inManagedObjectContext: moc];
                // Set values in the new record
                [obj setValue:title forKey:@"detectedTitle"];
                [obj setValue:correcttitle forKey:@"correctTitle"];
                [obj setValue:showid forKey:@"id"];
                [obj setValue:@0 forKey:@"episodeOffset"];
                [obj setValue:@0 forKey:@"episodethreshold"];
            }
        }
        //Save
        [moc save:&error];
        // Clear Core Data Objects from Memory
        [moc reset];
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
    long statusCode = [request getStatusCode];
    switch (statusCode) {
        case 200:{
            //Clear Auto Exceptions
            [AutoExceptions clearAutoExceptions];
            NSLog(@"Updating Auto Exceptions!");
            //Parse and Import
            NSData *jsonData = [request getResponseData];
            NSError *error = nil;
            NSArray * a = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
            AppDelegate * delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
            NSManagedObjectContext *moc = [delegate getObjectContext];
            for (NSDictionary *d in a) {
                NSError * error = nil;
                // Add Entry to Auto Exceptions
                NSManagedObject *obj = [NSEntityDescription
                                            insertNewObjectForEntityForName:@"AutoExceptions"
                                            inManagedObjectContext: moc];
                // Set values in the new record
                [obj setValue:d[@"detectedtitle"] forKey:@"detectedTitle"];
                if (d[@"hcorrecttitle"] !=nil) {
                    [obj setValue:d[@"hcorrecttitle"] forKey:@"correctTitle"]; // Use Correct Kitsu Title
                }
                else{
                    [obj setValue:d[@"correcttitle"] forKey:@"correctTitle"]; // Use Universal Correct Title
                }
                [obj setValue:d[@"offset"] forKey:@"episodeOffset"];
                [obj setValue:d[@"threshold"] forKey:@"episodethreshold"];
                [obj setValue:d[@"group"] forKey:@"group"];
                //Save
                [moc save:&error];
            }
            // Set the last updated date
            [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"ExceptionsLastUpdated"];
            // Clear Core Data Objects from Memory
            [moc reset];
            break;
        }
        default:
            NSLog(@"Auto Exceptions List Update Failed!");
            break;
    }
}
+(void)clearAutoExceptions{
    // Remove All cache data from Auto Exceptions
    AppDelegate * delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    NSManagedObjectContext *moc = [delegate getObjectContext];
    NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
    [allExceptions setEntity:[NSEntityDescription entityForName:@"AutoExceptions" inManagedObjectContext:moc]];
    
    NSError * error = nil;
    NSArray * exceptions = [moc executeFetchRequest:allExceptions error:&error];
    //error handling goes here
    for (NSManagedObject * exception in exceptions) {
        [moc deleteObject:exception];
    }
    error = nil;
    [moc save:&error];
    // Clear Core Data Objects from Memory
    [moc reset];
}

@end
