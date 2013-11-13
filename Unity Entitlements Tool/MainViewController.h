/********************************************************************************
 Copyright (c) 2011-2013, jemast software
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the <organization> nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
********************************************************************************/


#import <Cocoa/Cocoa.h>

@interface MainViewController : NSViewController <NSOpenSavePanelDelegate> {
    NSArray *macAppStoreCategories;
    NSArray *macAppStoreCategoriesFullNames;
    
    NSURL *projectURL;
    NSURL *postProcessScriptURL;
    NSURL *entitlementsURL;
    //NSURL *resourceRulesURL;
    
    NSString *bundleIdentifier;
    NSString *applicationCategory;
    NSString *versionNumber;
    NSString *bundleGetInfo;
    NSString *customIconPath;
    NSString *customSplashScreenPath;
    NSString *provisioningCertificate;
    NSString *provisioningProfilePath;
    NSString *packagingCertificate;
    NSMutableDictionary *entitlements;
    BOOL postProcessScriptHasCodesign;
    BOOL postProcessScriptHasEntitlements;
    BOOL postProcessScriptHasPackaging;
    
    NSMutableArray *provisioningProfilePaths;
    NSMutableArray *provisioningProfileNames;
    NSMutableArray *provisioningProfileAppIds;
    NSMutableArray *provisioningProfileCertificates;
    NSMutableArray *packagingCertificates;
}

///////////////////
// PROJECT ITEMS //
///////////////////

// Image Views
@property (weak) IBOutlet NSImageView *codeSignIconImageView;
@property (weak) IBOutlet NSImageView *entitlementsIconImageView;
@property (weak) IBOutlet NSImageView *sandboxingIconImageView;
@property (weak) IBOutlet NSImageView *packagingIconImageView;

// Buttons
@property (weak) IBOutlet NSButton *updateBuildPipelineButton;
@property (weak) IBOutlet NSButton *clearBuildPipelineButton;

// Actions
- (IBAction)updateBuildPipelinePressed:(id)sender;
- (IBAction)clearBuildPipelinePressed:(id)sender;


////////////////////
// CODESIGN ITEMS //
////////////////////

@property (weak) IBOutlet NSBox *codeSignBox;

// Labels
@property (weak) IBOutlet NSTextField *provisioningProfileAppIdLabel;

// Buttons
@property (weak) IBOutlet NSPopUpButton *provisioningProfilePopUpButton;
@property (weak) IBOutlet NSPopUpButton *provisioningProfileCertificatePopUpButton;
@property (weak) IBOutlet NSPopUpButton *macAppStoreCategoryPopUpButton;
@property (weak) IBOutlet NSButton *setCustomIconButton;
@property (weak) IBOutlet NSButton *unsetCustomIconButton;
@property (weak) IBOutlet NSButton *setCustomSplashScreenButton;
@property (weak) IBOutlet NSButton *unsetCustomSplashScreenButton;

// Checkboxes
@property (weak) IBOutlet NSButton *codeSignCheckbox;

// Text fields
@property (weak) IBOutlet NSTextField *bundleIdentifierTextField;
@property (weak) IBOutlet NSTextField *versionNumberTextField;
@property (weak) IBOutlet NSTextField *bundleGetInfoTextField;

// Image wells
@property (weak) IBOutlet NSImageView *customIconImageWell;
@property (weak) IBOutlet NSImageView *customSplashScreenImageWell;


// Actions
- (IBAction)codeSignCheckboxPressed:(id)sender;
- (IBAction)provisioningProfilePicked:(id)sender;
- (IBAction)provisioningProfileCertificatePicked:(id)sender;
- (IBAction)bundleIdentifierTextFieldEdited:(id)sender;
- (IBAction)appStoreCategoryPicked:(id)sender;
- (IBAction)versionNumberTextFieldEdited:(id)sender;
- (IBAction)bundleGetInfoTextFieldEdited:(id)sender;
- (IBAction)setCustomIconButtonPressed:(id)sender;
- (IBAction)unsetCustomIconButtonPressed:(id)sender;
- (IBAction)customIconWellAction:(id)sender;
- (IBAction)customSplashScreenWellAction:(id)sender;
- (IBAction)setCustomSplashScreenButtonPressed:(id)sender;
- (IBAction)unsetCustomSplashScreenButtonPressed:(id)sender;


////////////////////////
// ENTITLEMENTS ITEMS //
////////////////////////

@property (weak) IBOutlet NSBox *entitlementsBox;

// Checkboxes
@property (weak) IBOutlet NSButton *entitlementsCheckbox;
@property (weak) IBOutlet NSButton *entitlementsGameCenterCheckbox;

// Text fields
@property (weak) IBOutlet NSTextField *entitlementsApplicationIdentifierTextField;
@property (weak) IBOutlet NSTextField *iCloudKeyValueStoreTextField;
@property (weak) IBOutlet NSTextField *iCloudContainerTextField;

// Buttons
@property (weak) IBOutlet NSPopUpButton *entitlementApsPopUpButton;

// Actions
- (IBAction)entitlementsCheckboxPressed:(id)sender;
- (IBAction)entitlementsApplicationIdentifierTextFieldEdited:(id)sender;
- (IBAction)iCloudKeyValueStoreTextFieldEdited:(id)sender;
- (IBAction)iCloudContainerTextFieldEdited:(id)sender;
- (IBAction)entitlementsOptionCheckboxPressed:(id)sender;
- (IBAction)entitlementsApsEnvironmentPicked:(id)sender;


//////////////////////
// SANDBOXING ITEMS //
//////////////////////

@property (weak) IBOutlet NSBox *sandboxingBox;

// Checkboxes
@property (weak) IBOutlet NSButton *sandboxingCheckbox;

@property (weak) IBOutlet NSButton *sbAllowIncomingNetworkConnectionsCheckbox;
@property (weak) IBOutlet NSButton *sbAllowOutgoingNetworkConnectionsCheckbox;
@property (weak) IBOutlet NSButton *sbAllowCameraAccessCheckbox;
@property (weak) IBOutlet NSButton *sbAllowMicrophoneAccessCheckbox;
@property (weak) IBOutlet NSButton *sbAllowUSBAccessCheckbox;
@property (weak) IBOutlet NSButton *sbAllowPrintingCheckbox;
@property (weak) IBOutlet NSButton *sbAllowAddressBookDataAccessCheckbox;
@property (weak) IBOutlet NSButton *sbAllowLocationServicesAccessCheckbox;
@property (weak) IBOutlet NSButton *sbAllowCalendarDataAccessCheckbox;

// Buttons
@property (weak) IBOutlet NSPopUpButton *sbFileSystemAccessPopUpButton;
@property (weak) IBOutlet NSPopUpButton *sbMusicFolderAccessPopUpButton;
@property (weak) IBOutlet NSPopUpButton *sbMoviesFolderAccessPopUpButton;
@property (weak) IBOutlet NSPopUpButton *sbPicturesFolderAccesPopUpButton;
@property (weak) IBOutlet NSPopUpButton *sbDownloadsFolderAccessPopUpButton;

// Actions
- (IBAction)sandboxingCheckboxPressed:(id)sender;
- (IBAction)sandboxingPopUpButtonPicked:(id)sender;
- (IBAction)sandboxingOptionCheckboxPressed:(id)sender;


/////////////////////
// PACKAGING ITEMS //
/////////////////////

@property (weak) IBOutlet NSBox *packagingBox;

// Checkboxes
@property (weak) IBOutlet NSButton *packagingCheckbox;

// Buttons
@property (weak) IBOutlet NSPopUpButton *installerCertificatePopUpButton;

// Actions
- (IBAction)packagingCheckboxPressed:(id)sender;
- (IBAction)installerCertificatePicked:(id)sender;


///////////////////////////
// CONTROLLER PROPERTIES //
///////////////////////////

@property NSURL *projectURL;


@end


//////////////////////////////////
// INTERNAL METHODS DELCARATION //
//////////////////////////////////
// We're not attempting to hide them, we're just separating them in another .m file for clarity's sake
@interface MainViewController (Internal)

- (BOOL)importProjectBuildPipeline:(NSError *__autoreleasing *)error;
- (BOOL)updateProvisioningProfileList:(NSError *__autoreleasing *)error;
- (BOOL)updateInstallerProfileList:(NSError *__autoreleasing *)error;

- (void)updateProjectStatus;
- (void)syncUIWithEntitlements;
- (void)reset;

- (void)setCodeSignBoxActive;
- (void)setCodeSignBoxInactive;
- (void)setEntitlementsBoxActive;
- (void)setEntitlementsBoxInactive;
- (void)setSandboxingBoxActive;
- (void)setSandboxingBoxInactive;
- (void)setPackagingBoxActive;
- (void)setPackagingBoxInactive;

- (void)updatePostProcessScript:(NSMutableString *)script codesign:(BOOL)withCodesign entitlements:(BOOL)withEntitlements packaging:(BOOL)withPackaging;


@end


