/**
 *  AdvancedViewController.swift
 *  NowPlayingTweet
 *
 *  © 2018 kPherox.
**/

import Cocoa

class AdvancedViewController: NSViewController {

    @IBOutlet weak var tweetWithImage: NSButton!
    @IBOutlet weak var autoTweet: NSButton!

    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    var userDefaults: UserDefaults?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        self.userDefaults = self.appDelegate.userDefaults

        self.tweetWithImage.set(state: (self.userDefaults?.bool(forKey: "TweetWithImage"))!)
        self.autoTweet.set(state: (self.userDefaults?.bool(forKey: "AutoTweet"))!)
    }

    @IBAction func switchSetting(_ sender: NSButton) {
        let identifier: String = (sender.identifier?.rawValue)!
        if identifier == "AutoTweet" {
            self.notificationObserver(state: sender.state.toBool())
        }
        self.userDefaults?.set(sender.state.toBool(), forKey: identifier)
        self.userDefaults?.synchronize()
    }

    private func notificationObserver(state: Bool) {
        let notificationObserver: NotificationObserver = NotificationObserver()
        if state {
            notificationObserver.addObserver(true, self.appDelegate, name: .iTunesPlayerInfo, selector: #selector(self.appDelegate.handleNowPlaying(_:)))
        } else {
            notificationObserver.removeObserver(true, self.appDelegate, name: .iTunesPlayerInfo)
        }
    }

}