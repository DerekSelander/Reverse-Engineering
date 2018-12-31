#include <dlfcn.h>
#include "FTSettings.h"

BKSTerminateApplicationForReasonAndReportWithDescription thething;

@implementation FTSettings : NSObject

+ (id)sharedInstance {
    static FTSettings *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FTSettings alloc] init];
    });
    return sharedInstance;
}

-(id)init {
    if (self = [super init]) {
        [FTSettings loadPlist];
    }
    return self;
}

- (void)loadPlist {
    static NSDictionary *preferences;
    
    CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("it.dreamcode.ftp2"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (keyList) {
        preferences = (NSDictionary *)CFPreferencesCopyMultiple(keyList, CFSTR("it.dreamcode.ftp2"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        CFRelease(keyList);
        if (preferences) {
            if ([keyList objectForKey:@"enabled"]) {
                [FTSettings setEnabled:[[keyList objectForKey:@"enabled"] boolValue]];
            }
            else {
                [FTSettings setEnabled:YES];
            }
            
            if ([keyList objectForKey:@"vienabled"]) {
                [FTSettings setVibrate:[[keyList objectForKey:@"vienabled"] boolValue]];
            }
            else {
                [FTSettings setVibrate:YES];
            }
            
            if ([keyList objectForKey:@"vienabledup"]) {
                [FTSettings setVibrateUp:[[keyList objectForKey:@"vienabledup"] boolValue]];
            }
            else {
                [FTSettings setVibrateUp:NO];
            }
            
            if ([keyList objectForKey:@"vibintensity"]) {
                [FTSettings setVibintensity:([[keyList objectForKey:@"vibintensity"] doubleValue]/10)];
            }
            else {
                [FTSettings setVibintensity:3.0];
            }
            
            if ([keyList objectForKey:@"gesturespeed"]) {
                [FTSettings setDispatchTime: 100000000 * [[keyList objectForKey:@"gesturespeed"] intValue]];
            }
            
            if ([keyList objectForKey:@"ontouch"]) {
                [FTSettings setOntouch:[[keyList objectForKey:@"ontouch"] intValue]];
            }
            else {
                [FTSettings setOntouch:1];
            }
            if ([keyList objectForKey:@"onhold"]) {
                [FTSettings setOntouch:[[keyList objectForKey:@"onhold"] intValue]];
            }
            else {
                [FTSettings setOnhold:0];
            }
            
            if ([keyList objectForKey:@"ondoubletouch"]) {
                [FTSettings setOntouch:[[keyList objectForKey:@"ondoubletouch"] intValue]];
            }
            else {
                [FTSettings setOndoubletouch:2];
            }
            
            if ([keyList objectForKey:@"ontripletouch"]) {
                [FTSettings setOntripletouch:[[keyList objectForKey:@"ontripletouch"] intValue]];
            }
            else {
                [FTSettings setOntripletouch:4];
            }
            
            if ([keyList objectForKey:@"ontouchandhold"]) {
                [FTSettings setOntouchandhold:[[keyList objectForKey:@"ontouchandhold"] intValue]];
            }
            else {
                [FTSettings setOntouchandhold:6];
            }
            
            if ([keyList objectForKey:@"ontouchlocked"]) {
                [FTSettings setOntouchlocked:[[keyList objectForKey:@"ontouchlocked"] intValue]];
            }
            else {
                [FTSettings setOntouchlocked:1];
            }
            
            if ([keyList objectForKey:@"onholdlocked"]) {
                [FTSettings setOnholdlocked:[[keyList objectForKey:@"onholdlocked"] intValue]];
            }
            else {
                [FTSettings setOnholdlocked:0xFFFFFFFF];
            }
            
            if ([keyList objectForKey:@"ondoubletouchlocked"]) {
                [FTSettings setOndoubletouchlocked:[[keyList objectForKey:@"ondoubletouchlocked"] intValue]];
            }
            else {
                [FTSettings setOndoubletouchlocked:0xFFFFFFFF];
            }
            
            if ([keyList objectForKey:@"ontripletouchlocked"]) {
                [FTSettings setOntripletouchlocked:[[keyList objectForKey:@"ontripletouchlocked"] intValue]];
            }
            else {
                [FTSettings setOntripletouchlocked:0xFFFFFFFF];
            }
            
            if ([keyList objectForKey:@"ontouchandholdlocked"]) {
                [FTSettings setOntouchandholdlocked:[[keyList objectForKey:@"ontouchandholdlocked"] intValue]];
            }
            else {
                [FTSettings setOntouchandholdlocked:0xFFFFFFFF];
            }
            if ([FTSettings ontripletouch] != -1) {
                [FTSettings setMaxUPs:3];
            }
            if ([FTSettings ondoubletouch] == -1 && [FTSettings ontouchandhold] == -1) {
                [FTSettings setMaxUPs:1];
            }
            else {
                [FTSettings setMaxUPs:2];
            }
        }
        else {
            [FTSettings setEnabled:true];
            [FTSettings setVibrate:true];
            [FTSettings setVibrateUp:false];
            [FTSettings setDispatchTime:300000000]
            [FTSettings setVibintensity:0.3];
            [FTSettings setOntouch:1];
            [FTSettings setOnhold:0];
            [FTSettings setOndoubletouch:2];
            [FTSettings setOntripletouch:4];
            [FTSettings setOntouchandhold:6];
            [FTSettings setOntouchlocked:1];
            [FTSettings setOnholdlocked:0xFFFFFFFF]; //not sure what IDA meant with 0xFFFFFFFF
             [FTSettings setOndoubletouchlocked:0xFFFFFFFF];
            [FTSettings setOntripletouchlocked:0xFFFFFFFF];
            [FTSettings setOntouchandholdlocked:0xFFFFFFFF];
        }
    }
    else {
        [FTSettings setEnabled:true];
        [FTSettings setVibrate:true];
        [FTSettings setVibrateUp:true];
        [FTSettings setDispatchTime:300000000]
        [FTSettings setVibintensity:0.3];
        [FTSettings setOntouch:1];
        [FTSettings setOnhold:0];
        [FTSettings setOndoubletouch:2];
        [FTSettings setOntripletouch:4];
        [FTSettings setOntouchandhold:6];
        [FTSettings setOntouchlocked:1];
        [FTSettings setOnholdlocked:0xFFFFFFFF];
         [FTSettings setOndoubletouchlocked:0xFFFFFFFF];
        [FTSettings setOntripletouchlocked:0xFFFFFFFF];
        [FTSettings setOntouchandholdlocked:0xFFFFFFFF];
    }
}

- (void)hapticFeedbackIfNeeded:(_Bool)arg1 {
    //didn't quite understand this part
    if (!arg1) {
        if ([FTSettings vibrateUp]) {
            NSNumber *intensity = [NSNumber numberWithDouble:[FTSettings vibintensity]];
            NSNumber *abool = [NSNumber numberWithBool:true];
            NSNumber *anothernumber = [NSNumber numberWithInt:10];
            NSArray *somearray = [NSArray arrayWithObjects:abool count:2];
            NSDictionary *dict = [NSDictionary dictionaryWithObjects:intensity forKeys:@"Intensity" count:2];
            AudioServicesPlaySystemSoundWithVibration(/*gotta pass some arguments here*/);
        }
    }
    else {
        if ([FTSettings vibrate]) {
            NSNumber *intensity = [NSNumber numberWithDouble:[FTSettings vibintensity]];
            NSNumber *abool = [NSNumber numberWithBool:true];
            NSNumber *anothernumber = [NSNumber numberWithInt:10];
            NSArray *somearray = [NSArray arrayWithObjects:abool count:2];
            NSDictionary *dict = [NSDictionary dictionaryWithObjects:intensity forKeys:@"Intensity" count:2];
            AudioServicesPlaySystemSoundWithVibration(/*gotta pass some arguments here*/);

        }
    }
}
+ (void)executeActionForCode:(int)arg1 {
    switch(arg1) {
        case 0:
            [FTSettings simulateLockButton];
        case 1:
            [FTSettings simulateHomeButton];
        case 2:
            [FTSettings toggleSwitcher];
        case 3:
            [FTSettings toggleFlashlight];
        case 4:
            [FTSettings makeScreenshot];
        case 5:
            [FTSettings toggleReachability];
        case 6:
            [FTSettings switchToLastApp];
        case 7:
            [FTSettings toggleVirtualAssistant];
        case 8:
            [FTSettings toggleRotationLock];
        case 9:
            [FTSettings bringUpControlCenter];
        case 10:
            [FTSettings toggleNotificationCenter];
        case 11:
            [FTSettings terminateCurrentApplication];
        default:
            return;
    }
}
+ (void)toggleReachability {
    SBReachabilityManager *manager = %c(SBReachabilityManager);
    [[manager sharedInstance] toggleReachability];
}
+ (void)makeScreenshot {
    if (kCFCoreFoundationVersionNumber >= 1443.0) {
        [[UIApplication sharedApplication] takeScreenshot];
    }
    else {
        [[[UIApplication sharedApplication] screenshotManager] saveScreenshotWithCompletion:nil];
    }
}
+ (void)toggleSwitcher {
    if (kCFCoreFoundationVersionNumber >= 1349.56) {
        [[%c(SBMainSwitcherViewController) sharedInstance] toggleSwitcherNoninteractivelyWithSource:nil];
    }
    else {
        [[%c(SBMainSwitcherViewController) sharedInstance] toggleSwitcherNoninteractively];
    }
}
+ (void)simulateHomeButton {
    [[UIApplication sharedApplication] _simulateHomeButtonPress];
}
+ (void)simulateLockButton {
    [[UIApplication sharedApplication] _simulateLockButtonPress];
}
+ (void)switchToLastApp {
    //this one was kinda complex, I hope I got it right
    
    if (kCFCoreFoundationVersionNumber < 1443.0) {
        int someint = [[UIApplication sharedApplication] _accessibilityFrontMostAppplication] != 0; //if it's anything other than 0 make it be 1, true => 1
        
        NSMutableArray *items = [[NSClassFromString(@"SBAppSwitcherModel") sharedInstance] valueForKey:@"_recentDisplayItems"];
        
        if ([items count] <= someint) return;
        
        SBApplication *app = [items objectAtIndexedSubscript:someint]; //i'd suppose this is a SBApplication
        
        NSString *displayid = [app displayIdentifier];
        
        SBApplicationController *sbac = [%c(SBApplicationController) sharedInstanceIfExists];

        [[%c(SBUIController) sharedInstanceIfExists] activateApplication:[sbac applicationWithBundleIdentifier:[app displayIdentifier]];
        
        NSMutableArray *applayouts = [[%c(SBRecentAppLayouts) sharedInstance] recents];
        if ([applayouts count] > someint) {
            [[[applayouts objectAtIndexedSubscript:someint] allItems] objectAtIndexedSubscript:0];
        }
         [[%c(SBUIController) sharedInstanceIfExists] _activateApplicationFromAccessibility:[sbac applicationWithBundleIdentifier:[app displayIdentifier]];
    }
}

+ (void)toggleFlashLight {
    if ([%c(AVFlashlight) hasFlashlight]) {
        AVFlashlight *av = [%c(AVFlashlight) new];
        [av setFlashlightLevel:1.0 withError:nil];
        return;
    }
    [av turnPowerOff];
    [av dealloc];
}
+ (void)toggleVirtualAssistant {
    AXSpringBoardServer *serv = [%c(AXSpringBoardServer) server]
    if ([serv isSiriVisible]) {
        [serv dismissSiri];
    }
    else {
        [serv openSiri];
    }
}
+ (void)toggleRotationLock {
    SBOrientationLockManager *sbm = [%c(SBOrientationLockManager) sharedInstance];
    if ([sbm isUserLocked]) {
        [sbm unlock];
    }
    else {
        [sbm lock];
    }
}
+ (void)bringUpControlCenter {
    SBControlCenterController *sccc = [%c(SBControlCenterController) sharedInstanceIfExists];
    if ([sccc isVisible]) {
        [sccc dismissAnimated:YES];
    }
    else {
        [sccc presentAnimated:YES];
    }
}
+ (void)toggleNotificationCenter {
    if (kCFCoreFoundationVersionNumber >= 1443.0) {
        SBCoverSheetPresentationManager *sncc = [%c(SBCoverSheetPresentationManager) sharedInstance];
        if ([sncc isVisible]) {
            [sncc setCoverSheetPresented:NO animated:YES withCompletion:nil];
        }
        else {
            [sncc setCoverSheetPresented:YES animated:YES withCompletion:nil];
        }
    }
    else {
        SBNotificationCenterController *sbnc = [%c(SBNotificationCenterController) sharedInstanceIfExists];
        if ([sbnc isVisible]) {
            [sbnc dismissAnimated:YES];
        }
        else {
            [sbnc presentAnimated:YES];
        }
    }
}
+ (void)terminateCurrentApplication {
    BOOL somebool;
    
    if([[UIApplication sharedApplication] _accessibilityFrontMostAppplication]) {
        somebool = thething == NULL;
    }
    else {
        somebool = true;
    }
    if (!somebool) {
        thething([[[UIApplication sharedApplication] _accessibilityFrontMostAppplication] bundleIdentifier], 1, 0, 0);
    }
}
@end

%group HOOKS
%hook SBDashBoardViewController
-(void)handleBiometricEvent:(unsigned long long)arg1 {
    %orig(arg1);
    
    FTSettings *settings = [%c(FTSettings) sharedInstance];
    BOOL enabled = [settings enabled];
    
    if (!enabled) {
        return;
    }
    else {
        if (/*some random variable I can't figure out*/) {
            //so some stuff, eta son
        }
        else {
            //do some other stuff, eta son
        }
    }
}
%end
//the hooks will be completed later, eta son
%end

%ctor {
    void *handle = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", 1);
    if (handle) {
        typedef int (*BKSTerminateApplicationForReasonAndReportWithDescription)(NSString *bundleid, int reason, int something, int somethingelse);
        thething = (BKSTerminateApplicationForReasonAndReportWithDescription)dlsym(handle, "BKSTerminateApplicationForReasonAndReportWithDescription");
        
        %init(HOOKS)
    }
}
