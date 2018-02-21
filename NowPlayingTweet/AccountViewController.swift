/**
 *  AccountViewController.swift
 *  NowPlayingTweet
 *
 *  © 2018 kPherox.
**/

import Cocoa
import SwifterMac

class AccountViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    @IBOutlet weak var avater: NSImageView!
    @IBOutlet weak var name: NSTextField!
    @IBOutlet weak var screenName: NSTextField!
    @IBOutlet weak var currentButton: NSButton!
    @IBOutlet weak var currentLabel: NSTextField!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var removeButton: NSButton!
    @IBOutlet weak var accountList: AccountsListView!

    let appDelegate = NSApplication.shared.delegate as! AppDelegate

    let userDefaults: UserDefaults = UserDefaults.standard

    static let shared: AccountViewController = {
        let storyboard = NSStoryboard(name: .main, bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: .accountViewController)
        return windowController as! AccountViewController
    }()

    let twitterClient: TwitterClient = TwitterClient.shared

    var selected: TwitterClient.Account?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do view setup here.
        if !self.twitterClient.existAccount {
            return
        }

        self.selected = self.twitterClient.current
        self.removeButton.enable()

        let userID = self.selected?.userID
        let numberOfAccounts = self.twitterClient.accountIDs.index(of: userID!)!
        let index = IndexSet(integer: numberOfAccounts)
        self.accountList.selectRowIndexes(index, byExtendingSelection: false)

        let isCurrent = self.twitterClient.currentID == userID
        self.currentLabel.isHidden = !isCurrent
        self.currentButton.isHidden = isCurrent

        self.set(name: self.selected?.name)
        self.set(screenName: self.selected?.screenName)
        self.set(avaterUrl: self.selected?.avaterUrl)
    }

    @IBAction func setToCurrent(_ sender: NSButton) {
        let userID = self.selected?.userID
        self.twitterClient.changeCurrent(userID: userID!)
        self.appDelegate.updateTwitterAccount()
        self.currentLabel.isHidden = false
        self.currentButton.isHidden = true
    }

    @IBAction func addAccount(_ sender: NSButton) {
        self.twitterClient.login()

        let notificationCenter: NotificationCenter = NotificationCenter.default
        var observer: NSObjectProtocol!
        observer = notificationCenter.addObserver(forName: .login, object: nil, queue: nil, using: { notification in
            self.removeButton.enable()
            self.selected = notification.userInfo!["account"] as? TwitterClient.Account

            self.accountList.reloadData()

            let userID = self.selected?.userID
            let name = self.selected?.name

            let numberOfAccounts = self.twitterClient.accountIDs.index(of: userID!)!
            let index = IndexSet(integer: numberOfAccounts)
            self.accountList.selectRowIndexes(index, byExtendingSelection: false)

            let menuItem = NSMenuItem()
            menuItem.title = name!
            menuItem.action = #selector(self.appDelegate.tweetBySelectingAccount(_:))

            if self.twitterClient.accountIDs.count == 1 {
                let menu = NSMenu()
                menu.addItem(menuItem)
                self.appDelegate.tweetMenu?.submenu = menu
                self.appDelegate.updateTwitterAccount()
                self.currentLabel.isHidden = false
                self.currentButton.isHidden = true

            } else {
                self.appDelegate.tweetMenu?.submenu?.insertItem(menuItem, at: numberOfAccounts)
                self.currentLabel.isHidden = true
                self.currentButton.isHidden = false
            }

            self.set(name: name)
            self.set(screenName: self.selected?.screenName)
            self.set(avaterUrl: self.selected?.avaterUrl)

            notificationCenter.removeObserver(observer)
        })
    }

    @IBAction func removeAccount(_ sender: NSButton) {
        self.twitterClient.logout(account: self.selected!)

        self.accountList.reloadData()

        if self.twitterClient.existAccount {
            let removedName = self.selected?.name
            let menuItem = self.appDelegate.tweetMenu?.submenu?.item(withTitle: removedName!)
            self.appDelegate.tweetMenu?.submenu?.removeItem(menuItem!)

            self.selected = self.twitterClient.current

            let userID = self.selected?.userID
            let numberOfAccounts = self.twitterClient.accountIDs.index(of: userID!)!
            let index = IndexSet(integer: numberOfAccounts)
            self.accountList.selectRowIndexes(index, byExtendingSelection: false)

            let isCurrent = self.twitterClient.currentID == userID
            self.currentLabel.isHidden = !isCurrent
            self.currentButton.isHidden = isCurrent

            self.set(name: self.selected?.name)
            self.set(screenName: self.selected?.screenName)
            self.set(avaterUrl: self.selected?.avaterUrl)

            self.appDelegate.updateTwitterAccount()
        } else {
            self.appDelegate.tweetMenu?.submenu = nil

            self.removeButton.disable()
            self.selected = nil
            self.set(name: nil)
            self.set(avaterUrl: nil)
            self.set(screenName: nil)

            self.currentLabel.isHidden = true
            self.currentButton.isHidden = true

            self.appDelegate.updateTwitterAccount()
        }
    }

    @IBAction func selectAccount(_ sender: AccountsListView) {
        let row = sender.selectedRow
        let userID = self.twitterClient.accountIDs[row]
        let twitterAccount: TwitterClient.Account = self.twitterClient.accounts[userID]!
        self.selected = twitterAccount

        let isCurrent = self.twitterClient.currentID == userID
        self.currentLabel.isHidden = !isCurrent
        self.currentButton.isHidden = isCurrent
        self.set(name: twitterAccount.name)
        self.set(screenName: twitterAccount.screenName)
        self.set(avaterUrl: twitterAccount.avaterUrl)
    }

    func set(name string: String?) {
        self.name.stringValue = string != nil ? string! : "Account Name"
        self.name.textColor = string != nil ? .labelColor : .disabledControlTextColor
    }

    func set(screenName string: String?) {
        self.screenName.stringValue = "@\(string != nil ? string! : "null")"
        self.screenName.textColor = string != nil ? .secondaryLabelColor : .disabledControlTextColor
    }

    func set(avaterUrl url: URL?) {
        if url != nil {
            self.avater.fetchImage(url: url!, rounded: true)
            self.avater.enable()
        } else {
            self.avater.image = NSImage(named: .user)
            self.avater.disable()
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        if !self.twitterClient.existAccount {
            return 0
        }
        let accountCount = self.twitterClient.accounts.count
        return accountCount
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as! AccountCellView

        let userID = self.twitterClient.accountIDs[row]
        let twitterAccount: TwitterClient.Account = self.twitterClient.accounts[userID]!

        cellView.textField?.stringValue = twitterAccount.name
        cellView.screenName.stringValue = "@\(twitterAccount.screenName)"
        cellView.imageView?.fetchImage(url: twitterAccount.avaterUrl, rounded: true)

        return cellView
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat(50)
    }

}