#!/bin/bash

echo "Configuring macOS..."

# macOS configuration preferences (inspired by https://macos-defaults.com/)
# Dock
## Dock on the left side
defaults write com.apple.dock "orientation" -string "left" 
## Icon size
defaults write com.apple.dock "tilesize" -int "22" 
## Auto-hide the Dock
defaults write com.apple.dock "autohide" -bool "true"
## Do not show recent apps section
defaults write com.apple.dock "show-recents" -bool "false"

# Finder
## Show filename extensions by default
defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "false"
## Do not warn on extension change
defaults write com.apple.finder "FXEnableExtensionChangeWarning" -bool "false"
# Save to disk by default instead of iCloud
defaults write NSGlobalDomain "NSDocumentSaveNewDocumentsToCloud" -bool "false" 

## Menus
## Clock format
defaults write com.apple.menuextra.clock "DateFormat" -string "\"EEE d MMM HH:MM\"" 

## Feedback Assistant
defaults write com.apple.appleseed.FeedbackAssistant "Autogather" -bool "false" 

# TextEdit
## Open as plain text by default
defaults write com.apple.TextEdit "RichText" -bool "false"

## Time Machine
## Do not offer new disks for Time Machine backups
defaults write com.apple.TimeMachine "DoNotOfferNewDisksForBackup" -bool "true" 

### Trackpad
## Enable tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
## Disable "natural" scroll
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true