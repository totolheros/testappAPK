#import "AudioPlayer.h"

static AudioPlayer *_audioPlayer;

@implementation AudioPlayer

@synthesize delegate, player, audioPlayerData, state, tracks, albums, radio, repeatMode, shuffleMode, playlistShuffle, currentPurchaseUrl;
@synthesize nowPlayingInfo, trackOffset, albumOffset, currentTrackTitle, currentTrackArtist, currentTrackDuration, currentArtwork, currentTrackUrl, isMinimized, isNewPlaylist, commandCenter;

#pragma mark Singleton Methods

+ (id) audioPlayer {
    if (_audioPlayer == nil) {
        NSLog(@"Init new AudioPlayer");
        _audioPlayer = [[self alloc] init];
        _audioPlayer.nowPlayingInfo = [[NSMutableDictionary alloc] init];
        _audioPlayer.repeatMode = @"";
        _audioPlayer.shuffleMode = NO;
        _audioPlayer.playlistShuffle = [[NSMutableDictionary alloc] init];
        _audioPlayer.commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    }
    
    return _audioPlayer;
}

- (void) initData:(NSDictionary *)pAudioPlayerData {
    audioPlayerData = pAudioPlayerData;
    
    radio = NO;
    if([audioPlayerData objectForKey:@"isRadio"]) {
        radio = [[audioPlayerData objectForKey:@"isRadio"] boolValue];
    }

    tracks = [audioPlayerData objectForKey:@"tracks"];
    albums = [[NSMutableDictionary alloc] init];
    
    NSDictionary *albums_data = [audioPlayerData objectForKey:@"albums"];
    for(NSDictionary *album in albums_data) {
        [albums setObject:album forKey:[album objectForKey:@"id"]];
    }
    
    if(isNewPlaylist) {
        trackOffset = [[audioPlayerData objectForKey:@"trackIndex"] intValue];
    }

    [self initLockscreenRemoteController];
    [self playCurrentTrack];
}

- (BOOL) isPlaying {
    return [state isEqualToString:@"play"];
}

- (BOOL) isRadio {
    return radio;
}

- (BOOL) isShuffling {
    return shuffleMode;
}

- (BOOL) isFirstAudioItem {
    return trackOffset == 0 && ![repeatMode isEqualToString:@"all"];
}

- (BOOL) isLastAudioItem {
    return ((trackOffset == (tracks.count - 1) && !shuffleMode)
                || (shuffleMode && playlistShuffle.count == tracks.count))
                && ![repeatMode isEqualToString:@"all"];
}

- (void) playPause {
    if([state isEqualToString:@"play"]) {
        [self pause];
    } else {
        [self play];
    }
}

- (void) playRewind {
    int secondsElapsed = CMTimeGetSeconds(player.currentTime);
    [player seekToTime:CMTimeMakeWithSeconds(secondsElapsed - 5, 1)];
    [nowPlayingInfo setValue:[NSNumber numberWithFloat:CMTimeGetSeconds(player.currentTime)] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nowPlayingInfo];
}

- (void) playForward {
    int secondsElapsed = CMTimeGetSeconds(player.currentTime);
    [player seekToTime:CMTimeMakeWithSeconds(secondsElapsed + 5, 1)];
    [nowPlayingInfo setValue:[NSNumber numberWithFloat:CMTimeGetSeconds(player.currentTime)] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nowPlayingInfo];
}

- (void) playPreviousItem {
    [player pause];
    trackOffset--;
    [self playCurrentTrack];
}

- (void) playNextItem {
    [player pause];
    
    if (shuffleMode) {
        if(playlistShuffle.count == tracks.count) {
            if([repeatMode isEqualToString:@"all"]) {
                playlistShuffle = [[NSMutableDictionary alloc] init];
                [self random];
            } else {
                return;
            }
        } else {
            [self random];
        }
    } else if(trackOffset != (tracks.count - 1)) {
        trackOffset++;
    } else if([repeatMode isEqualToString:@"all"]) {
        trackOffset = 0;
    }
    
    [self playCurrentTrack];
}

- (void) setRepeatMode {
    if([repeatMode isEqualToString:@""]) {
        repeatMode = @"all";
    } else if([repeatMode isEqualToString:@"all"]) {
        repeatMode = @"one";
    } else if([repeatMode isEqualToString:@"one"]) {
        repeatMode = @"";
    }
    
    if([delegate respondsToSelector:@selector(audioPlayerDidChangeRepeatMode)] && !radio) {
        [delegate audioPlayerDidChangeRepeatMode];
    }
}

- (void) setShuffleMode {
    shuffleMode = !shuffleMode;
    
    if(shuffleMode) {
        [playlistShuffle setValue:@"track" forKey:[NSString stringWithFormat:@"%d", trackOffset]];
    } else {
        playlistShuffle = [[NSMutableDictionary alloc] init];
    }
    
    if([delegate respondsToSelector:@selector(audioPlayerDidChangeShuffleMode)] && !radio) {
        [delegate audioPlayerDidChangeShuffleMode];
    }
}

- (void) destroy {
    NSLog(@"Destroy audioplayer");
    [self reset];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:[NSDictionary dictionary]];
    repeatMode = @"";
    shuffleMode = NO;
    playlistShuffle = [[NSMutableDictionary alloc] init];
    player = nil;
    isMinimized = NO;
}

/**
 * PRIVATE FUNCTIONS *
 **/
- (void) initLockscreenRemoteController {
    NSLog(@"initLockscreenRemoteController");
    
    if(!radio) {
        MPRemoteCommand *previousTrackCommand = [commandCenter previousTrackCommand];
        if([self isFirstAudioItem]) {
            [previousTrackCommand setEnabled:NO];
        } else {
            [previousTrackCommand setEnabled:YES];
        }
        [previousTrackCommand addTarget:self action:@selector(playPreviousItem)];
        
        MPRemoteCommand *nextTrackCommand = [commandCenter nextTrackCommand];
        if([self isLastAudioItem]) {
            [nextTrackCommand setEnabled:NO];
        } else {
            [nextTrackCommand setEnabled:YES];
        }
        [nextTrackCommand addTarget:self action:@selector(playNextItem)];
    }
    
    MPRemoteCommand *playCommand = [commandCenter playCommand];
    [playCommand setEnabled:YES];
    [playCommand addTarget:self action:@selector(playPause)];
    
    MPRemoteCommand *pauseCommand = [commandCenter pauseCommand];
    [pauseCommand setEnabled:YES];
    [pauseCommand addTarget:self action:@selector(playPause)];
}

- (void) updateLockscreenRemoteController {
    MPRemoteCommand *previousTrackCommand = [commandCenter previousTrackCommand];
    if([self isFirstAudioItem]) {
        [previousTrackCommand setEnabled:NO];
    } else {
        [previousTrackCommand setEnabled:YES];
    }
    
    MPRemoteCommand *nextTrackCommand = [commandCenter nextTrackCommand];
    if([self isLastAudioItem]) {
        [nextTrackCommand setEnabled:NO];
    } else {
        [nextTrackCommand setEnabled:YES];
    }
}

- (void) settingNowPlayingInfo {
    UIImage *artwork = [UIImage imageNamed:@"LaunchImage"];
    if([currentArtwork isKindOfClass:[NSString class]] &&
       ![currentArtwork isEqualToString:@""] &&
       [currentArtwork rangeOfString:@"default_album"].length <= 0 &&
       !radio) {
        
        if([currentArtwork rangeOfString:@"http://"].length <= 0 && [currentArtwork rangeOfString:@"https://"].length <= 0) {
            currentArtwork = [[Url sharedInstance] getImage:currentArtwork];
            currentArtwork = [currentArtwork stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
        }
        
        artwork = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:currentArtwork]]];
    }
    
    MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage: artwork];
    NSNumber *playbackDuration = [NSNumber numberWithInt:currentTrackDuration];
    if(radio) {
        playbackDuration = 0;
    }

    [nowPlayingInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
    [nowPlayingInfo setObject:currentTrackTitle forKey:MPMediaItemPropertyTitle];
    if(!radio) {
        [nowPlayingInfo setObject:currentTrackArtist forKey:MPMediaItemPropertyArtist];
        [nowPlayingInfo setObject:playbackDuration forKey:MPMediaItemPropertyPlaybackDuration];
    }
    [nowPlayingInfo setObject:[NSNumber numberWithFloat:CMTimeGetSeconds(player.currentTime)] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];

    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nowPlayingInfo];
    
}

- (void) registerMediaPlayerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handle_PlayerItemDidReachEnd:)
                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:[player currentItem]];
    
    [player addObserver:self forKeyPath:@"status" options:0 context:nil];
    [player addObserver:self forKeyPath:@"rate" options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == player && [keyPath isEqualToString:@"status"]) {
        if (player.status == AVPlayerStatusFailed) {
            NSLog(@"AVPlayer Failed");
        } else if (player.status == AVPlayerStatusReadyToPlay) {
            [self settingNowPlayingInfo];
            
            [self play];
            
            if([delegate respondsToSelector:@selector(audioDidPlay)]) {
                [delegate audioDidPlay];
            }
        } else if (player.status == AVPlayerItemStatusUnknown) {
            NSLog(@"AVPlayer Unknown");
        }
    }
    
    if (object == player && [keyPath isEqualToString:@"rate"]) {
        if([delegate respondsToSelector:@selector(audioPlayerStateChanged)]) {
            [delegate audioPlayerStateChanged];
        }
    }
    
}

- (void)handle_PlayerItemDidReachEnd:(NSNotification *)notification {

    [self pause];
    
    if([repeatMode isEqualToString:@"one"]) {
        [player seekToTime:CMTimeMakeWithSeconds(0, 1)];
        [self play];
    } else {
        [self playNextItem];
    }
    
    if([delegate respondsToSelector:@selector(audioDidEnd)]) {
        [delegate audioDidEnd];
    }
    
}

- (void) playCurrentTrack {

    NSDictionary *currentTrack = [tracks objectAtIndex:trackOffset];
    NSString *urlString = [currentTrack objectForKey:@"streamUrl"];
    
    if(![currentTrackUrl isEqualToString:urlString]) {
    
        if(!player) {
            player = [AVPlayer alloc];
        } else {
            [self reset];
        }
        
        NSLog(@"play new current track");
        
        currentPurchaseUrl = @"";
        if([[currentTrack objectForKey:@"purchaseUrl"] isKindOfClass:[NSString class]] && ![[currentTrack objectForKey:@"purchaseUrl"] isEqualToString:@""]) {
            currentPurchaseUrl = [currentTrack objectForKey:@"purchaseUrl"];
        }
        
        currentTrackUrl = urlString;
        currentTrackDuration = [[currentTrack objectForKey:@"duration"] intValue] / 1000;
        currentTrackTitle = [currentTrack objectForKey:@"name"];
        currentTrackArtist = [currentTrack objectForKey:@"artistName"];
        currentArtwork = [[albums objectForKey:[currentTrack objectForKey:@"albumId"]] objectForKey:@"artworkUrl"];
        currentArtwork = [currentArtwork stringByReplacingOccurrencesOfString:@"100x100" withString:[[NSString alloc] initWithFormat:@"%dx%d", getScreenWidth(), getScreenWidth()]];
        
        if([delegate respondsToSelector:@selector(audioWillPlay)]) {
            [delegate audioWillPlay];
        }
        
        player = [player initWithURL:[NSURL URLWithString:currentTrackUrl]];
      
        [self registerMediaPlayerNotifications];
    }

}

- (void) play {
    [self updateLockscreenRemoteController];
    if([self isLastAudioItem] && !radio) {
        [player seekToTime:CMTimeMakeWithSeconds(0, 1)];
    }
    state = @"play";
    [player play];
}

- (void) pause {
    state = @"pause";
    [player pause];
}

- (void) random {
    trackOffset = arc4random() % tracks.count;
    
    while ([playlistShuffle objectForKey:[NSString stringWithFormat:@"%d", trackOffset]]) {
        if(trackOffset == (tracks.count - 1)) {
            trackOffset = 0;
        } else {
            trackOffset++;
        }
    }
    
    [playlistShuffle setValue:@"track" forKey:[NSString stringWithFormat:@"%d", trackOffset]];
}

- (void) reset {
    currentTrackUrl = nil;
    currentTrackDuration = 0;
    currentTrackTitle = nil;
    currentArtwork = nil;
    [player pause];
    [player removeObserver:self forKeyPath:@"status" context:nil];
    [player removeObserver:self forKeyPath:@"rate" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:player];
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

@end