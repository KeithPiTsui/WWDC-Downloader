## WWDC Downloader
Started out as quick class to learn Swift 2, Mac OSX Cocoa and download some WWDC assets, it spiralled a little out of control.

Note: **App uses entitlements for Mac App Store Folder Sandbox access so needs to be signed - Select Developer ID and a Team to build.**


### It's in Swift 2 / Xcode 7 and only for El Capitan
Disappointed? Look to the future - embrace it.

### Features
- 2015, 2014, 2013
- Download and view PDFs, HD video, SD video and Code (2015 only)
- Downloads can be stopped and resumed
- Full description of sessions
- Searchable (title, description and session transcripts)
- Show/Hide Descriptions
- Visual progress of downloads
- Once Downloaded, file can be clicked to launch in preview, quicktime or finder as appropriate, right click to show in finder
- Combine all downloaded PDFs into 1 enormous PDF
- Dock icon progress (+ Bounce icon on finish and ping if not front window)
- Full vibrancy UI including toolbar
- Downloaded data persisted between launches
- Preferences to change concurrent number of downloads and the Folder where downloads are saved (Mac app store compliant but obviously this app wouldn't be allowed in store as it scrapes Apple site for info/assets)
- Fullscreen compatible
- Right click or swipe along session row for options for watched, favourites and deletion of files
- Double Click session row to launch Session Viewer
- If session video not downloaded then URL for SD video is queued up to attempt streaming
- Transcript time clickable to jump video to timestamp
- Transcript can auto follow video
- When is fullscreen the thumbnail pdf view will collapse, hover by edge to redisplay
- Session video progress saved
- Download folder is monitored for changes

### Interesting Areas
- NSDockTile (specifically adding custom download progress indicator - DockProgressBar.swift)
- Folder Monitoring using GCD (FolderChangeNotifier.swift)
- Highlightable Text using NSTextStorage (HighlightableTextStorage.swift)
PDF Merging (PDFMerge.swift)
- Mac app store sandbox folder access (Preferences.swift)
- WKWebView and Javascripting (SessionViewerController.swift - TranscriptViewController)
- NSMenu (right click menu) and NSEvent keyboard monitoring, such as ⌘F. (MainViewController.swift)

### 3rd Party libraries
I purposely avoided using external libraries as much as possible to expose myself to as many parts of AppKit and Cocoa as possible. Even AFNetworking?! I wanted to understand how it could be done with only NSURLSession as Apple seem to stress its usefulness and importance. So, only one 3rd party library is included as a shortcut to parse the html - Hpple (https://github.com/topfunky/hpple)

### Where does the data come from?
- Apple for Inital WWDC Session Data, PDFs, Videos, Code
- NSHipster - ASCIIwwdc full-text transcripts api ([http://asciiwwdc.com](http://asciiwwdc.com))

### Where is the data stored?
- Downloads are in the folder chosen in preferences (default: Downloads)
- App data in Application Support in Containers i.e /Users/######/Library/Containers/com.macosx.wwdcdownloader/Data/Library/Application Support/

### Support or Contact
File bugs, request enhancements, issue pull requests
