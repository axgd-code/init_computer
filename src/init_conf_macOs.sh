#!/usr/bin/env bash

echo "Configuration de OSX…"

#Installation des confs macOS que j'aime (https://macos-defaults.com/fr/)
#Dock
##Dock à gauche de l'écran
defaults write com.apple.dock "orientation" -string "left" 
##Taille des icônes
defaults write com.apple.dock "tilesize" -int "22" 
##Cacher le doc automatiquement
defaults write com.apple.dock "autohide" -bool "true"
##Ne pas afficher la section des applications utilisées récemment
defaults write com.apple.dock "show-recents" -bool "false"

#Finder
##Show filename extensions by default
defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "false"
##Ne pas mettre d'alerte au changement d'extension d'un fichier 
defaults write com.apple.finder "FXEnableExtensionChangeWarning" -bool "false"
#Enregistrer par défaut dans iCloud
defaults write NSGlobalDomain "NSDocumentSaveNewDocumentsToCloud" -bool "false" 

##Menus
##Format de l'horloge
defaults write com.apple.menuextra.clock "DateFormat" -string "\"EEE d MMM HH:MM\"" 

##Assistante d'évaluation
defaults write com.apple.appleseed.FeedbackAssistant "Autogather" -bool "false" 

#TextEdit
##Ouvrir par défaut en txt
defaults write com.apple.TextEdit "RichText" -bool "false"

##Timemachine
##Ne pas activer l'ajout de disque timeMachine
defaults write com.apple.TimeMachine "DoNotOfferNewDisksForBackup" -bool "true" 

###Trackpad
##Activer le tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
##Désactiver le "natural" scroll
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true