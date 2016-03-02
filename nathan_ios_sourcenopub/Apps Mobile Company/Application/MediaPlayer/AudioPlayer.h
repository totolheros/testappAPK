//
//  AudioPlayer.h
//  Apps Mobile Company
//
//  Created by Florent BEGUE on 07/10/15.
//  Copyright © 2015 Adrien Sala. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <AVFoundation/AVFoundation.h>
#import "Url.h"
#import "common.h"

@protocol audioPlayerDelegate

@optional

- (void) audioPlayerStateChanged;
- (void) audioPlayerDidChangeRepeatMode;
- (void) audioPlayerDidChangeShuffleMode;
- (void) audioWillPlay;
- (void) audioDidPlay;
- (void) audioDidEnd;

@end

@interface AudioPlayer : NSObject {
    id <NSObject, audioPlayerDelegate> delegate;
}

@property (retain) id <NSObject, audioPlayerDelegate> delegate;

@property (strong, retain) AVPlayer *player;
@property (nonatomic) NSString *state;
@property (strong, retain) NSDictionary *audioPlayerData;
@property (strong, retain) NSMutableDictionary *playlistShuffle;
@property (strong, retain) NSMutableArray *tracks;
@property (strong, retain) NSMutableDictionary *albums;
@property (nonatomic) BOOL radio;
@property (nonatomic) int trackOffset;
@property (nonatomic) int albumOffset;
@property (strong, retain) NSMutableDictionary *nowPlayingInfo;
@property (nonatomic) NSString *currentPurchaseUrl;
@property (nonatomic) NSString *currentTrackUrl;
@property (nonatomic) NSString *currentTrackTitle;
@property (nonatomic) NSString *currentTrackArtist;
@property (nonatomic) NSString *currentArtwork;
@property (nonatomic) int currentTrackDuration;
@property (nonatomic) NSString *repeatMode;
@property (nonatomic) BOOL shuffleMode;
@property (nonatomic) BOOL isMinimized;
@property (nonatomic) BOOL isNewPlaylist;
@property (nonatomic) MPRemoteCommandCenter *commandCenter;

+ (id) audioPlayer;
- (void) initData:(NSDictionary *)data;
- (void) playCurrentTrack;
- (BOOL) isRadio;
- (BOOL) isPlaying;
- (BOOL) isShuffling;
- (BOOL) isFirstAudioItem;
- (BOOL) isLastAudioItem;
- (void) playPause;
- (void) playRewind;
- (void) playForward;
- (void) playPreviousItem;
- (void) playNextItem;
- (void) setRepeatMode;
- (void) setShuffleMode;
- (void) destroy;

@end