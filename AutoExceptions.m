//
//  AutoExceptions.m
//  Hachidori
//
//  Created by Tail Red on 1/31/15.
//  Copyright 2015 MAL Updater OS X Group and James Moy All rights reserved. Code licensed under New BSD License
//

#import "AutoExceptions.h"
#import <AFNetworking/AFNetworking.h>
#import "AppDelegate.h"

@implementation AutoExceptions
#pragma mark Importing Exceptions and Auto Exceptions
+ (void)importToCoreData{
    AppDelegate * delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    NSManagedObjectContext *moc = delegate.managedObjectContext;
    // Check Exceptions
    NSArray *oexceptions = [[NSUserDefaults standardUserDefaults] objectForKey:@"exceptions"];
    if (oexceptions.count > 0) {
        NSLog(@"Importing Exception List");
        NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
        allExceptions.entity = [NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc];
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
        // Erase exceptions data from preferences
        [[NSUserDefaults standardUserDefaults] setObject:[[NSMutableArray alloc] init] forKey:@"exceptions"];
    }
}
+ (void)updateAutoExceptions {
    // This method retrieves the auto exceptions JSON and import new entries
    AFHTTPSessionManager *manager = [self manager];
    NSError *error;
    NSURLSessionDataTask *task;
    id responseObject = [manager syncGET:@"http://exceptions.malupdaterosx.moe/corrections/" parameters:nil task:&task error:&error];
    // Get Status Code
    switch (((NSHTTPURLResponse *)task.response).statusCode) {
        case 200:{
            NSLog(@"Updating Auto Exceptions!");
            if (![[NSUserDefaults standardUserDefaults] valueForKey:@"updatedaexceptions"]) {
                [self clearAutoExceptions];
                [[NSUserDefaults standardUserDefaults] setObject:@(true)forKey:@"updatedaexceptions"];
            }
            //Parse and Import
            AppDelegate *delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
            NSManagedObjectContext *moc = delegate.managedObjectContext;
            [moc performBlockAndWait:^{
                for (NSDictionary *d in responseObject) {
                    NSString * detectedtitle = d[@"detectedtitle"];
                    NSString * group = d[@"group"];
                    NSString * correcttitle = d[@"correcttitle"];
                    NSString * hcorrecttitle = (NSString *)d[@"hcorrecttitle"];
                    bool iszeroepisode = ((NSNumber *)d[@"iszeroepisode"]).boolValue;
                    int offset = ((NSNumber *)d[@"offset"]).intValue;
                    NSError *derror = nil;
                    NSManagedObject *obj = [self checkAutoExceptionsEntry:detectedtitle group:group correcttitle:correcttitle hcorrecttitle:hcorrecttitle zeroepisode:iszeroepisode];
                    if (obj) {
                        // Update Entry
                        [obj setValue:d[@"offset"] forKey:@"episodeOffset"];
                        [obj setValue:d[@"threshold"] forKey:@"episodethreshold"];
                    }
                    else {
                        // Add Entry to Auto Exceptions
                        obj = [NSEntityDescription
                               insertNewObjectForEntityForName:@"AutoCorrection"
                               inManagedObjectContext: moc];
                        // Set values in the new record
                        [obj setValue:detectedtitle forKey:@"detectedTitle"];
                        if (hcorrecttitle.length > 0) {
                            [obj setValue:hcorrecttitle forKey:@"correctTitle"]; // Use Correct Kitsu Title
                        }
                        else {
                            [obj setValue:correcttitle forKey:@"correctTitle"]; // Use Universal Correct Title
                        }
                        [obj setValue:@(offset) forKey:@"episodeOffset"];
                        [obj setValue:d[@"threshold"] forKey:@"episodethreshold"];
                        [obj setValue:group forKey:@"group"];
                        [obj setValue:@(iszeroepisode) forKey:@"iszeroepisode"];
                        [obj setValue:d[@"mappedepisode"] forKey:@"mappedepisode"];
                    }
                    //Save
                    [moc save:&derror];
                }
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                // Set the last updated date
                [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"ExceptionsLastUpdated"];
            });
            break;
        }
        default:
            NSLog(@"Auto Exceptions List Update Failed!");
            break;
    }
}
+ (void)clearAutoExceptions{
    // Remove All cache data from Auto Exceptions
    AppDelegate * delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    NSManagedObjectContext *moc = delegate.managedObjectContext;
    NSFetchRequest * allExceptions = [[NSFetchRequest alloc] init];
    allExceptions.entity = [NSEntityDescription entityForName:@"AutoCorrection" inManagedObjectContext:moc];
    
    NSError * error = nil;
    NSArray * exceptions = [moc executeFetchRequest:allExceptions error:&error];
    //error handling goes here
    for (NSManagedObject * exception in exceptions) {
        [moc deleteObject:exception];
    }
    error = nil;
    [moc save:&error];
}
+ (NSManagedObject *)checkAutoExceptionsEntry:(NSString *)ctitle
group:(NSString *)group
correcttitle:(NSString *)correcttitle
hcorrecttitle:(NSString *)hcorrecttitle
zeroepisode:(bool)zeroepisode {
    // Return existing offline queue item
    NSError * error;
    AppDelegate * delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    NSManagedObjectContext * moc = delegate.managedObjectContext;
    NSString * rctitle;
    if (hcorrecttitle.length > 0) {
        rctitle = hcorrecttitle;
    }
    else {
        rctitle = correcttitle;
    }
    NSPredicate * predicate = [NSPredicate predicateWithFormat: @"(detectedTitle ==[c] %@) AND (correctTitle == %@) AND (group ==[c] %@) AND (iszeroepisode == %i)", ctitle,rctitle, group, zeroepisode] ;
    NSFetchRequest * exfetch = [[NSFetchRequest alloc] init];
    exfetch.entity = [NSEntityDescription entityForName:@"AutoCorrection" inManagedObjectContext:moc];
    exfetch.predicate = predicate;
    NSArray * exceptions = [moc executeFetchRequest:exfetch error:&error];
    if (exceptions.count > 0) {
        return (NSManagedObject *)exceptions[0];
    }
    return nil;
}
+ (AFHTTPSessionManager*)manager {
    static dispatch_once_t onceToken;
    static AFHTTPSessionManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [AFHTTPSessionManager manager];
        manager.responseSerializer = [AFJSONResponseSerializer serializer];
        manager.completionQueue = dispatch_queue_create("AFNetworking+Synchronous", NULL);
    });
    
    return manager;
}
@end
