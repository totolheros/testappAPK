//
//  musicViewController.h
//  Apps Mobile Company
//
//  Created by The Tiger App Creator Team on 06/10/15.
//

#import "webViewController.h"
#import "AudioPlayer.h"
#import "SocialSharing.h"
#import "loaderView.h"
#import "common.h"

@interface musicViewController : UIViewController <audioPlayerDelegate, socialSharingDelegate, UITableViewDelegate, UITableViewDataSource> {
    loaderView *loader;
    AudioPlayer *audioPlayer;
    UITableView *playlistView;
}

@property (strong, nonatomic) IBOutlet loaderView *loader;

@property (strong, nonatomic) NSDictionary *audioPlayerData;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *audioTitle;
@property (strong, nonatomic) IBOutlet UIImageView *coverImage;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnClose;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnPurchase;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnPlaylist;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnShare;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnPlayPause;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnRewind;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnPrevious;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnRepeat;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnForward;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnNext;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *btnShuffle;
@property (strong, nonatomic) IBOutlet UISlider *progressBar;
@property (strong, nonatomic) IBOutlet UILabel *audioDuration;

- (IBAction)purchaseIt:(id)sender;
- (IBAction)showPlaylist:(id)sender;
- (IBAction)openSharing:(id)sender;

- (IBAction)closeModal:(id)sender;
- (IBAction)minimizeModal:(id)sender;

- (IBAction)playOrPause:(id)sender;
- (IBAction)playForward:(id)sender;
- (IBAction)playNext:(id)sender;
- (IBAction)playRewind:(id)sender;
- (IBAction)playPrevious:(id)sender;
- (IBAction)playShuffle:(id)sender;
- (IBAction)playRepeat:(id)sender;
- (IBAction)progressBarChanged:(id)sender;

@end