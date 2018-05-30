//
//  AtarashiiDataObjects.m
//  Shukofukurou
//
//  Created by 桐間紗路 on 2017/12/19.
//  Copyright © 2017年 MAL Updater OS X Group. All rights reserved.
//

#import "AtarashiiDataObjects.h"

@implementation AtarashiiAnimeObject
- (id)init {
    self = [super init];
    if (self) {
        self.titleid = 0;
        self.title = @"";
        self.other_titles = @{};
        self.rank = 0;
        self.popularity_rank = 0;
        self.image_url = @"";
        self.type = @"";
        self.episodes = 0;
        self.status = @"";
        self.start_date = @"";
        self.end_date = @"";
        self.broadcast = @"";
        self.duration = 0;
        self.classification = @"";
        self.members_score = 0;
        self.members_count = 0;
        self.favorited_count = 0;
        self.synposis = @"";
        self.background = @"";
        self.producers = @[];
        self.genres = @[];
        self.manga_adaptations = @[];
        self.prequels = @[];
        self.sequels = @[];
        self.side_stories = @[];
        self.parent_story = @[];
        self.character_anime = @[];
        self.spin_offs = @[];
        self.opening_theme = @[];
        self.ending_theme = @[];
        self.recommendations = @[];
        self.mappings = @{};
    }
    return self;
}

- (NSDictionary *)NSDictionaryRepresentation {
    return @{ @"id" : @(_titleid), @"title" : _title.copy, @"other_titles" : _other_titles.copy, @"rank" : @(_rank), @"popularity_rank" : @(_popularity_rank), @"image_url" : _image_url.copy, @"type" : _type.copy, @"episodes" : @(_episodes), @"status" : _status.copy, @"start_date" : _start_date.copy, @"end_date" : _end_date.copy, @"broadcast" : _broadcast.copy, @"duration" : @(_duration), @"classification" : _classification.copy, @"members_score" : @(_members_score), @"members_count" : @(_members_count), @"favorited_count" : @(_favorited_count), @"synopsis" : _synposis.copy, @"background" : _background.copy, @"producers" : _producers.copy, @"genres" : _genres.copy, @"manga_adaptations" : _manga_adaptations.copy, @"prequels" : _prequels.copy, @"sequels" : _sequels.copy, @"side_stories" : _side_stories.copy, @"parent_story" : _parent_story.copy, @"character_anime" : _character_anime.copy, @"spin_offs" : _spin_offs.copy, @"opening_theme" : _opening_theme.copy, @"ending_theme" : _ending_theme.copy, @"recommendations" : _recommendations.copy, @"mappings" : _mappings.copy };
}
@end

@implementation AtarashiiAnimeListObject
- (id)init {
    self = [super init];
    if (self) {
        self.entryid = 0;
        self.watched_status = @"";
        self.watched_episodes = 0;
        self.score = 0;
        self.score_type = 0;
        self.watching_start = @"";
        self.watching_end = @"";
        self.rewatching = false;
        self.rewatch_count = 0;
        self.personal_comments = @"";
    }
    return self;
}

- (NSDictionary *)NSDictionaryRepresentation {
    return @{ @"entryid" : @(_entryid), @"watched_status" : _watched_status.copy, @"watched_episodes" : @(_watched_episodes), @"score" : @(_score), @"score_type" : @(_score_type), @"watching_start" : _watching_start.copy, @"watching_end" : _watching_end.copy, @"rewatching" : @(_rewatching), @"rewatch_count" : @(_rewatch_count), @"personal_comments" : _personal_comments.copy, @"private": @(_private_entry)};
}
@end
