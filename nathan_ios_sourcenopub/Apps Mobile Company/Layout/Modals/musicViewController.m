//
//  musicViewController.m
//  Siberian
//
//  Created by The Tiger App Creator Team on 06/10/15.
//

#import "musicViewController.h"

NSString *currentArtwork;
UIColor *lightblueColor;
UITableViewController *playlistViewController;
UINavigationController *playlistNavigationController;

@implementation musicViewController

@synthesize loader, audioPlayerData;
@synthesize audioTitle, coverImage, audioDuration, progressBar;
@synthesize btnClose, btnPurchase, btnPlaylist, btnShare, btnPlayPause, btnRewind, btnPrevious, btnRepeat, btnForward, btnNext, btnShuffle;

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [loader hide];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"viewdidload");
    
    // Créé et affiche le loader
    CGRect frame;
    if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        NSLog(@"isportrait for loader");
        frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    } else {
        frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.height, self.view.frame.size.width);
    }
    loader = [[loaderView alloc] initWithFrame:frame];
    // Ajoute le loader à la vue en cours
    [self.view addSubview:loader];
    [self.view bringSubviewToFront:loader];

    lightblueColor = [progressBar thumbTintColor];
    currentArtwork = @"";
    
    audioPlayer = [AudioPlayer audioPlayer];
    audioPlayer.delegate = self;
    [audioPlayer initData:audioPlayerData];
    audioPlayer.isMinimized = NO;
    audioPlayer.isNewPlaylist = YES;
    
    [audioTitle setBackgroundVerticalPositionAdjustment:0 forBarMetrics:UIBarMetricsDefault];
    
    [btnPlaylist setBackgroundVerticalPositionAdjustment:1 forBarMetrics:UIBarMetricsDefault];
    [[btnPlaylist valueForKey:@"view"] setBackgroundColor:[UIColor blackColor]];
    [btnShare setBackgroundVerticalPositionAdjustment:1 forBarMetrics:UIBarMetricsDefault];
    [[btnShare valueForKey:@"view"] setBackgroundColor:[UIColor blackColor]];
    [btnClose setBackgroundVerticalPositionAdjustment:1 forBarMetrics:UIBarMetricsDefault];
    [[btnClose valueForKey:@"view"] setBackgroundColor:[UIColor blackColor]];
    
    [self updateView];
    
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(handle_UpdateProgress:) userInfo:nil repeats:YES];
    
    [self createPlaylistView];
}

-(void)handle_UpdateProgress:(NSTimer *)timer {
    int secondsElapsed = CMTimeGetSeconds(audioPlayer.player.currentTime);
    
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:secondsElapsed];
    NSDateFormatter *timeElapsed = [[NSDateFormatter alloc] init];
    [timeElapsed setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [timeElapsed setDateFormat:@"mm:ss"];
    
    audioDuration.text = [timeElapsed stringFromDate:date];
    progressBar.value = secondsElapsed;
}

-(void)updateView {
    progressBar.maximumValue = audioPlayer.currentTrackDuration;
    audioTitle.title = audioPlayer.currentTrackTitle;
    audioDuration.text = @"00:00";
    
    if (![currentArtwork isEqualToString:audioPlayer.currentArtwork]) {
        
        UIImage *artworkImage = [UIImage imageNamed:@"LaunchImage"];
        if([audioPlayer.currentArtwork isKindOfClass:[NSString class]] &&
           ![audioPlayer.currentArtwork isEqualToString:@""] &&
           [audioPlayer.currentArtwork rangeOfString:@"default_album"].length <= 0 &&
           ![audioPlayer isRadio]) {
            
            NSString *artworkUrl = audioPlayer.currentArtwork;
            if([artworkUrl rangeOfString:@"http://"].length <= 0 && [artworkUrl rangeOfString:@"https://"].length <= 0) {
                artworkUrl = [[Url sharedInstance] getImage:artworkUrl];
                artworkUrl = [artworkUrl stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
            }
            
            currentArtwork = artworkUrl;
            
            artworkImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:artworkUrl]]];
            NSLog(@"download artwork url: %@", artworkUrl);
        }
        
        [coverImage setImage:artworkImage];
    }

    [self updateButtons];
}

-(void)updatePlayButton {
    if([audioPlayer isPlaying]) {
        [btnPlayPause setImage:[UIImage imageNamed:@"Pause"]];
    } else {
        [btnPlayPause setImage:[UIImage imageNamed:@"Play"]];
    }
}

-(void)updatePreviousNextButton {
    if([audioPlayer isFirstAudioItem]) {
        [btnPrevious setEnabled:NO];
    } else {
        [btnPrevious setEnabled:YES];
    }
    
    if([audioPlayer isLastAudioItem]) {
        [btnNext setEnabled:NO];
    } else {
        [btnNext setEnabled:YES];
    }
}

-(void)updateRepeatButton {
    if([audioPlayer.repeatMode isEqualToString:@""]) {
        [btnRepeat setImage:[UIImage imageNamed:@"Repeat"]];
        [btnRepeat setTintColor:[UIColor whiteColor]];
    } else if([audioPlayer.repeatMode isEqualToString:@"all"]) {
        [btnRepeat setImage:[UIImage imageNamed:@"Repeat"]];
        [btnRepeat setTintColor:lightblueColor];
    } else if([audioPlayer.repeatMode isEqualToString:@"one"]) {
        [btnRepeat setImage:[UIImage imageNamed:@"RepeatOne"]];
        [btnRepeat setTintColor:lightblueColor];
    }
}

-(void)updateShuffleButton {
    if([audioPlayer isShuffling]) {
        [btnShuffle setTintColor:lightblueColor];
    } else {
        [btnShuffle setTintColor:[UIColor whiteColor]];
    }
}

//playlistView
-(void)createPlaylistView {
    playlistView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    playlistView.dataSource = self;
    playlistView.delegate = self;
    
    playlistViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    [playlistViewController setTableView:playlistView];
    
    UIBarButtonItem *playlistDoneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:nil action:@selector(closePlaylist)];
    UINavigationItem *playlistNavigationItem = [[UINavigationItem alloc] init];
    [playlistNavigationItem setLeftBarButtonItem:playlistDoneItem];
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGRect navigationBarFrame;
    if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        NSLog(@"isportrait");
        navigationBarFrame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, screenBounds.size.width, 64);
    } else {
        navigationBarFrame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, screenBounds.size.height, 64);
    }
    
    UINavigationBar *playlistNavigationBar = [[UINavigationBar alloc] initWithFrame:navigationBarFrame];
    [playlistNavigationBar setBarStyle:UIBarStyleBlack];
    [playlistNavigationBar setBackgroundColor:[UIColor blackColor]];
    [playlistNavigationBar setBarTintColor:[UIColor blackColor]];
    [playlistNavigationBar setTintColor:[UIColor whiteColor]];
    [playlistNavigationBar setItems:[NSArray arrayWithObject:playlistNavigationItem]];
    
    playlistNavigationController = [[UINavigationController alloc] initWithRootViewController:playlistViewController];
    [playlistNavigationController.view addSubview:playlistNavigationBar];
}

- (IBAction)purchaseIt:(id)sender {
    if(![audioPlayer.currentPurchaseUrl isEqualToString:@""]) {
        [self performSegueWithIdentifier:@"openWebview" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"openWebview"]) {
        [segue.destinationViewController setWebViewUrl:[[NSURL alloc] initWithString:audioPlayer.currentPurchaseUrl]];
    }
}

- (IBAction)showPlaylist:(id)sender {
    [playlistView reloadData];
    [self presentViewController:playlistNavigationController animated:YES completion:nil];
}

- (void)closePlaylist {
    [playlistNavigationController dismissViewControllerAnimated: YES completion:nil];
}
//playlistView End

/** socialSharing **/
- (IBAction)openSharing:(id)sender {
    NSString *customSharingText = [[NSString alloc] initWithFormat: NSLocalizedString(@"I'm listening to %@ from %@ on %@ app.", nil), audioPlayer.currentTrackTitle, audioPlayer.currentTrackArtist, getAppName()];
    if([audioPlayer isRadio]) {
        customSharingText = [[NSString alloc] initWithFormat: NSLocalizedString(@"I'm listening to %@ on %@ app.", nil), audioPlayer.currentTrackTitle, getAppName()];
    }
    customSharingText = [customSharingText stringByAppendingString:@" %@"];
    
    NSDictionary *sharingData = [NSDictionary dictionaryWithObjectsAndKeys:customSharingText, @"custom_sharing_text", nil];
    
    SocialSharing *socialSharing = [[SocialSharing alloc] init];
    socialSharing.delegate = self;
    [socialSharing open:self withSharingData:sharingData];
}
- (void)shareViewWillAppear {
    [loader show];
}
- (void)shareViewDidAppear {
    [loader hide];
}
/** /socialSharing **/

- (IBAction)closeModal:(id)sender {
    [audioPlayer destroy];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)minimizeModal:(id)sender {
    audioPlayer.isMinimized = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)playOrPause:(id)sender {
    [audioPlayer playPause];
}

- (IBAction)playForward:(id)sender {
    [audioPlayer playForward];
}

- (IBAction)playNext:(id)sender {
    [loader show];
    [audioPlayer playNextItem];
}

- (IBAction)playShuffle:(id)sender {
    [audioPlayer setShuffleMode];
}

- (IBAction)playRewind:(id)sender {
    [audioPlayer playRewind];
}

- (IBAction)playPrevious:(id)sender {
    [loader show];
    [audioPlayer playPreviousItem];
}

- (IBAction)playRepeat:(id)sender {
    [audioPlayer setRepeatMode];
}

- (IBAction)progressBarChanged:(id)sender {
    [audioPlayer.player seekToTime:CMTimeMakeWithSeconds((int)progressBar.value, 1)];
    [audioPlayer.nowPlayingInfo setValue:[NSNumber numberWithFloat:CMTimeGetSeconds(audioPlayer.player.currentTime)] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:audioPlayer.nowPlayingInfo];
}

- (void)viewDidUnload {
    NSLog(@"viewdidunload musicViewController");
}

-(void)updateButtons {
    [self updatePlayButton];

    if([audioPlayer isRadio]) {
        [progressBar setHidden:YES];
        [btnShuffle setEnabled:NO];
        [btnNext setEnabled:NO];
        [btnPrevious setEnabled:NO];
        [btnForward setEnabled:NO];
        [btnRewind setEnabled:NO];
        [btnRepeat setEnabled:NO];
        [btnPlaylist setEnabled:NO];
        [btnPurchase setEnabled:NO];
    } else {
        [progressBar setHidden:NO];
        [btnNext setEnabled:YES];
        [btnPrevious setEnabled:YES];
        [btnForward setEnabled:YES];
        [btnRewind setEnabled:YES];
        [btnRepeat setEnabled:YES];
        [btnShuffle setEnabled:YES];
        [btnPlaylist setEnabled:YES];
        
        if([audioPlayer.currentPurchaseUrl isEqualToString:@""]) {
            [btnPurchase setEnabled:NO];
        } else {
            [btnPurchase setEnabled:YES];
        }
        
        [self updatePreviousNextButton];
        [self updateRepeatButton];
        [self updateShuffleButton];
    }
}

/**
 * DELEGATE
 **/

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGRect loaderFrame;
    if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        loaderFrame = CGRectMake(loader.frame.origin.x, loader.frame.origin.y, screenBounds.size.height, screenBounds.size.width);
    } else {
        loaderFrame = CGRectMake(loader.frame.origin.x, loader.frame.origin.y, screenBounds.size.width, screenBounds.size.height);
    }
    
    loader.frame = loaderFrame;
    [loader replaceIndicator];
}

//audioPlayer  
-(void)audioPlayerStateChanged {
    [self updatePlayButton];
}

-(void)audioPlayerDidChangeRepeatMode {
    [self updateRepeatButton];
    [self updatePreviousNextButton];
}
-(void)audioPlayerDidChangeShuffleMode {
    [self updateShuffleButton];
}

-(void)audioWillPlay {
    [loader show];
    [self updateView];
}

- (void)audioDidPlay {
    [self updatePreviousNextButton];
    [loader hide];
}

- (void)audioDidEnd {
    [self updatePlayButton];
}

//playlistView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (audioPlayer.tracks.count - 1);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = lightblueColor;
    [cell setSelectedBackgroundView:bgColorView];
    
    if(audioPlayer.trackOffset == indexPath.row) {
        [cell setBackgroundColor:lightblueColor];
    } else {
        [cell setBackgroundColor:[UIColor whiteColor]];
    }
    
    NSString *audioLabelTitle = @"";
    if([[[audioPlayer.tracks objectAtIndex:indexPath.row] objectForKey:@"name"] isKindOfClass:[NSString class]]) {
        audioLabelTitle = [[audioPlayer.tracks objectAtIndex:indexPath.row] objectForKey:@"name"];
    }
    NSString *audioLabelArtist = @"";
    if([[[audioPlayer.tracks objectAtIndex:indexPath.row] objectForKey:@"artistName"] isKindOfClass:[NSString class]]) {
        audioLabelArtist = [[audioPlayer.tracks objectAtIndex:indexPath.row] objectForKey:@"artistName"];
    }
    NSString *audioLabelAlbum = @"";
    if([[[audioPlayer.tracks objectAtIndex:indexPath.row] objectForKey:@"albumName"] isKindOfClass:[NSString class]]) {
        audioLabelAlbum = [[audioPlayer.tracks objectAtIndex:indexPath.row] objectForKey:@"albumName"];
    }
    
    cell.textLabel.text = [[NSString alloc] initWithFormat:@"%@ - %@", audioLabelTitle, audioLabelArtist];
    cell.detailTextLabel.text = audioLabelAlbum;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self closePlaylist];
    [audioPlayer setTrackOffset:(int)indexPath.row];
    [audioPlayer playCurrentTrack];
}

@end