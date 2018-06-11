//
//  ExceptionsCache.m
//  Hachidori
//
//  Created by Tail Red on 2/1/15.
//
//
//  Used to add and remove entries from Anime Exceptions and Cache
//

#import "ExceptionsCache.h"
#import "AppDelegate.h"

@implementation ExceptionsCache
+ (void)addtoExceptions:(NSString *)detectedtitle correcttitle:(NSString *)title aniid:(NSNumber *)showid threshold:(int)threshold offset:(int)offset detectedSeason:(int)season {
    AppDelegate *delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    NSManagedObjectContext *moc = delegate.managedObjectContext;
    NSError *error = nil;
    // Add to Cache in Core Data
    NSManagedObject *obj = [NSEntityDescription
                            insertNewObjectForEntityForName:@"Exceptions"
                            inManagedObjectContext: moc];
    // Set values in the new record
    [obj setValue:detectedtitle forKey:@"detectedTitle"];
    [obj setValue:title forKey:@"correctTitle"];
    [obj setValue:showid forKey:@"id"];
    [obj setValue:@(threshold) forKey:@"episodethreshold"];
    [obj setValue:@(offset) forKey:@"episodeOffset"];
    [obj setValue:@(season) forKey:@"detectedSeason"];
    //Save
    [moc save:&error];
}
+ (void)checkandRemovefromCache:(NSString *)detectedtitle detectedSeason:(int)season withService:(int)service {
    // Checks for cache entry. If exists, it will remove that entry.
    AppDelegate *delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    NSManagedObjectContext *moc = delegate.managedObjectContext;
    // Load present cache data
    NSFetchRequest *allCache = [[NSFetchRequest alloc] init];
    allCache.entity = [NSEntityDescription entityForName:@"Cache" inManagedObjectContext:moc];
    NSError *error = nil;
    NSArray *caches = [moc executeFetchRequest:allCache error:&error];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(detectedTitle == %@) AND (detectedSeason == %i) AND (service == %i)", detectedtitle, season, service];
    allCache.predicate = predicate;
    if (caches.count > 0) {
        //Check Cache to remove conflicts
        for (NSManagedObject *cacheentry in caches) {
            [moc deleteObject:cacheentry];
            break;
        }
        //Save
        [moc save:&error];
    }
}
+ (void)addtoCache:(NSString *)title showid:(NSString *)showid actualtitle:(NSString *) atitle totalepisodes:(int)totalepisodes detectedSeason:(int)season withService:(int)service {
    //Adds ID to cache
    AppDelegate *delegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
    NSManagedObjectContext *moc = delegate.managedObjectContext;
    // Add to Cache in Core Data
    NSManagedObject *obj = [NSEntityDescription
                            insertNewObjectForEntityForName :@"Cache"
                            inManagedObjectContext: moc];
    // Set values in the new record
    [obj setValue:title forKey:@"detectedTitle"];
    [obj setValue:showid forKey:@"id"];
    [obj setValue:atitle forKey:@"actualTitle"];
    [obj setValue:@(totalepisodes) forKey:@"totalEpisodes"];
    [obj setValue:@(season) forKey:@"detectedSeason"];
    [obj setValue:@(service) forKey:@"service"];
    NSError *error = nil;
    // Save
    [moc save:&error];
    
}
@end
