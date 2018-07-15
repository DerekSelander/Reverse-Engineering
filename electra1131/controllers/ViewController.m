//
//  ViewController.m
//
//  Copyright © 2018 Electra Team. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize compatibilityLabel=_compatibilityLabel;
@synthesize enableTweaks=_enableTweaks;
@synthesize setNonce=_setNonce;
@synthesize jailbreak=_jailbreak;

static ViewController *currentViewController;

+ (instancetype)currentViewController {
    return currentViewController;
}

- (void)checkVersion {
    NSString *rawgitHistory = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"githistory" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    __block NSArray *gitHistory = [rawgitHistory componentsSeparatedByString:@"\n"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://coolstar.org/electra/gitlatest-1131.txt"]];
        // User isn't on a network, or the request failed
        if (data == nil) return;
        
        NSString *gitCommit = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if (![gitHistory containsObject:gitCommit]){
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Update Available!" message:@"An update for Electra is available! Please visit https://coolstar.org/electra/ on a computer to download the latest IPA!" preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            });
        }
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(updateProgressFromNotification:) name:@"JB" object:nil];
    
    [self checkVersion];
    
    BOOL enable3DTouch = YES;
    
    int ret = offsets_init();
    if (ret == -1) {
        [self.jailbreak setEnabled:NO];
        [self.jailbreak setAlpha:0.5];
        [self.enableTweaks setEnabled:NO];
        NSString *versionErrStr = [[NSBundle mainBundle] localizedStringForKey:@"Version Error" value:nil table:@"Localizable"];
        [self.jailbreak setTitle:versionErrStr forState:UIControlStateNormal];
        enable3DTouch = NO;
    }
    else if (ret) {
        [self.jailbreak setEnabled:NO];
        [self.jailbreak setAlpha:0.5];
        [self.enableTweaks setEnabled:NO];
        NSString *offsetsErrStr = [[NSBundle mainBundle] localizedStringForKey:@"Error: offsets" value:nil table:@"Localizable"];
        [self.jailbreak setTitle:offsetsErrStr forState:UIControlStateNormal];
        enable3DTouch = NO;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"enableTweaks"]) {
        [defaults setBool:YES forKey:@"enableTweaks"];
        [defaults synchronize];
    }
    
    BOOL enableTweaks = [defaults boolForKey:@"enableTweaks"];
    
    [self.enableTweaks setOn:enableTweaks];
    if (file_exists("/.bootstraped_electra")) {
        NSString *enableJailbreakStr = [[NSBundle mainBundle] localizedStringForKey:@"Enable Jailbreak" value:nil table:@"Localizable"];
        [self.jailbreak setTitle:enableJailbreakStr forState:UIControlStateNormal];
    }
    
    uint32_t flags;
    pid_t my_pid = getpid();
    csops(my_pid, 0, &flags, 0);
    
    if (flags & CS_PLATFORM_BINARY) {
        [self.enableTweaks setEnabled:NO];
        NSString *shareStr = [[NSBundle mainBundle] localizedStringForKey:@"Share Electra" value:nil table:@"Localizable"];
        [self.jailbreak setTitle:shareStr forState:UIControlStateNormal];
        enable3DTouch = NO;
    }
    if (enable3DTouch)
        [notificationCenter addObserver:self selector:@selector(doit:) name:@"Jailbreak" object:nil];
    
    NSString *compStr = [[NSBundle mainBundle] localizedStringForKey:@"Compatible with" value:nil table:@"Localizable"];
    NSString *fullStr = [NSString stringWithFormat:@"%@\niOS 11.2 — 11.3.1", compStr];
    
    //----'compatibleWith'----//
    NSMutableAttributedString *mutableStr = [[NSMutableAttributedString alloc] initWithString:fullStr];
    
    //font
    UIFont *font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    [mutableStr addAttribute:NSFontAttributeName value:font range:[fullStr rangeOfString:compStr]];
    //color
    UIColor *col = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.3];
    [mutableStr addAttribute:NSForegroundColorAttributeName value:col range:[fullStr rangeOfString:compStr]];
    
    //----'iOS 11.2'----//
    
    //font
    font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [mutableStr addAttribute:NSFontAttributeName value:font range:[fullStr rangeOfString:@"iOS 11.2"]];
    //color
    col = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    [mutableStr addAttribute:NSForegroundColorAttributeName value:col range:[fullStr rangeOfString:@"iOS 11.2"]];
    
    //----'—'----//
    
    //font
    font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    [mutableStr addAttribute:NSFontAttributeName value:font range:[fullStr rangeOfString:@"—"]];
    //color
    col = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    [mutableStr addAttribute:NSForegroundColorAttributeName value:col range:[fullStr rangeOfString:@"—"]];
    
    //----' 11.3.1'----//
    
    //font
    font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [mutableStr addAttribute:NSFontAttributeName value:font range:[fullStr rangeOfString:@" 11.3.1"]];
    //color
    col = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    [mutableStr addAttribute:NSForegroundColorAttributeName value:col range:[fullStr rangeOfString:@" 11.3.1"]];
    
    [self.compatibilityLabel setAttributedText:mutableStr];
}

- (void)enableTweaksChanged:(id)arg1 {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[self.enableTweaks isOn] forKey:@"enableTweaks"];
    [defaults synchronize];
}

- (long long)preferredStatusBarStyle {
    return 1;
}

- (void)restarting {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    NSString *restartStr = [[NSBundle mainBundle] localizedStringForKey:@"Restarting" value:nil table:@"Localizable"];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:restartStr forKeys:@"JBProgress" count:1];
    
    [defaultCenter postNotificationName:@"JB" object:nil userInfo:dict];
}

- (void)displaySnapshotWarning {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        
        NSString *snapshotStr = [[NSBundle mainBundle] localizedStringForKey:@"user prompt" value:nil table:@"Localizable"];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjects:snapshotStr forKeys:@"JBProgress" count:1];
        
        [defaultCenter postNotificationName:@"JB" object:nil userInfo:dict];
        
        NSString *notFoundStr = [[NSBundle mainBundle] localizedStringForKey:@"APFS Snapshot Not Found" value:nil table:@"Localizable"];
        NSString *warningStr = [[NSBundle mainBundle] localizedStringForKey:@"Warning: Your device was bootstrapped using a pre-release version of Electra and thus does not have an APFS Snapshot present. While Electra may work fine, you will not be able to use SemiRestore to restore to stock if you need to. Please clean your device and re-bootstrap with this version of Electra to create a snapshot." value:nil table:@"Localizable"];
        
        //----why were UIAlertControllers invented?! long live UIAlertViews!----//
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:notFoundStr message:warningStr preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Continue Jailbreak" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:action];
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)displaySnapshotNotice {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        
        NSString *snapshotStr = [[NSBundle mainBundle] localizedStringForKey:@"user prompt" value:nil table:@"Localizable"];
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjects:snapshotStr forKeys:@"JBProgress" count:1];
        
        [defaultCenter postNotificationName:@"JB" object:nil userInfo:dict];

        NSString *createdStr = [[NSBundle mainBundle] localizedStringForKey:@"APFS Snapshot Created" value:nil table:@"Localizable"];
        NSString *messageStr = [[NSBundle mainBundle] localizedStringForKey:@"An APFS Snapshot has been successfully created! You may be able to use SemiRestore to restore your phone to this snapshot in the future." value:nil table:@"Localizable"];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:createdStr message:messageStr preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Continue Jailbreak" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:action];
        [self presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)cydiaDone {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    NSString *waitStr = [[NSBundle mainBundle] localizedStringForKey:@"Please Wait (2/3)" value:nil table:@"Localizable"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:waitStr forKeys:@"JBProgress" count:1];
    
    [defaultCenter postNotificationName:@"JB" object:nil userInfo:dict];
}

- (void)installingCydia {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    NSString *waitStr = [[NSBundle mainBundle] localizedStringForKey:@"Installing Cydia" value:nil table:@"Localizable"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:waitStr forKeys:@"JBProgress" count:1];
    
    [defaultCenter postNotificationName:@"JB" object:nil userInfo:dict];
}

- (void)removingLiberiOS {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    NSString *waitStr = [[NSBundle mainBundle] localizedStringForKey:@"Removing liberiOS" value:nil table:@"Localizable"];
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:waitStr forKeys:@"JBProgress" count:1];
    
    [defaultCenter postNotificationName:@"JB" object:nil userInfo:dict];
}

- (void)tappedOnHyperlink:(id)arg {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:getURLForUsername(@"Electra_Team")] options:nil completionHandler:nil];
}

- (void)tappedOnSetNonce:(id)arg1 {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //...//
    //eta son
}
//eta son

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
