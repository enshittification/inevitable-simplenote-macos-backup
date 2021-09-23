import Cocoa

class PreferencesViewController: NSViewController {
    let simperium: Simperium
    let options = Options.shared

    var aboutWindowController: NSWindowController?

    required init?(coder: NSCoder) {
        self.simperium = SimplenoteAppDelegate.shared().simperium
        super.init(coder: coder)
    }

    // MARK: Account Section Properties

    /// Account Email Label
    ///
    @IBOutlet private var emailLabel: NSTextField!

    /// Log Out Button:
    ///
    @IBOutlet private var logOutButton: NSButton!

    /// Delete Account Button
    ///
    @IBOutlet private var deleteAccountButton: NSButton!

    // MARK: Note List Appearence Section Properties

    /// Note Sort Order Title
    ///
    @IBOutlet private var noteSortOrderLabel: NSTextField!

    /// Note Line Length Title
    ///
    @IBOutlet private var noteLineLengthLabel: NSTextField!

    /// Note Sort Order Pop Up Button
    ///
    @IBOutlet private var sortOrderPopUp: NSPopUpButton!

    /// Line Length Full Radio Button
    ///
    @IBOutlet private var lineLengthFullRadio: NSButton!

    /// Line Length Narrow Radio Button
    ///
    @IBOutlet private var lineLengthNarrowRadio: NSButton!

    /// Condensed Note List Checkbox
    ///
    @IBOutlet private var condensedNoteListCheckbox: NSButton!

    /// Sort Tags Alphabetically Checkbox
    ///
    @IBOutlet private var sortTagsAlphabeticallyCheckbox: NSButton!

    // MARK: Theme Section Properties

    /// Theme Title Label
    ///
    @IBOutlet private var themeLabel: NSTextField!

    /// Theme Pop Up Button
    ///
    @IBOutlet private var themePopUp: NSPopUpButton!

    // MARK: Text Size Section Properties

    /// Text Size Title Label
    ///
    @IBOutlet private var textSizeLabel: NSTextField!

    /// Text Size Slider
    ///
    @IBOutlet private var textSizeSlider: NSSlider!

    // MARK: Analytics Section Properties

    /// Share Analytics Checkbox
    ///
    @IBOutlet private var shareAnalyticsCheckbox: NSButton!

    /// Analytics Description Label
    ///
    @IBOutlet private var analyticsDescrpitionLabel: NSTextField!

    // MARK: About Simplenote Section Properties

    /// About Simplenote Button
    ///
    @IBOutlet private var aboutSimplenoteButton: NSButton!

    // MARK: View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSortModeFields()
        setupThemeFields()
        refreshFields()
        refreshStyle()
    }

    private func refreshFields() {
        emailLabel.stringValue = simperium.user?.email ?? ""

        updateSelectedSortMode()
        updateLineLength()
        condensedNoteListCheckbox.state = options.notesListCondensed ? .on : .off
        sortTagsAlphabeticallyCheckbox.state = options.alphabeticallySortTags ? .on : .off

        updateSelectedTheme()

        textSizeSlider.intValue = Int32(options.fontSize)

        shareAnalyticsCheckbox.state = options.analyticsEnabled ? .on: .off

    }

    private func refreshStyle() {
        deleteAccountButton.bezelStyle = .roundRect
        let shadow = NSShadow()
        shadow.shadowBlurRadius = 0.8
        shadow.shadowColor = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 0.15)
        deleteAccountButton.shadow = shadow

        let deleteButtonCell = deleteAccountButton.cell as? ButtonCell
        deleteButtonCell?.regularBackgroundColor = .simplenoteAlertControlBackgroundColor
        deleteButtonCell?.textColor = .simplenoteAlertControlTextColor
        deleteButtonCell?.isBordered = true
    }

    private func setupSortModeFields() {
        let menuItems: [NSMenuItem] = SortMode.allCases.map { mode in
            let item = NSMenuItem()
            item.title = mode.description
            item.identifier = mode.noteListInterfaceID
            return item
        }
        
        menuItems.forEach({ sortOrderPopUp.menu?.addItem($0) })
    }


    private func setupThemeFields() {
        let menuItems: [NSMenuItem] = ThemeOption.allCases.map { theme in
            let item = NSMenuItem()
            item.title = theme.description
            item.tag = theme.rawValue
            return item
        }

        menuItems.forEach({ themePopUp.menu?.addItem($0) })
    }

    private func updateSelectedSortMode() {
        let sortMode = options.notesListSortMode
        sortOrderPopUp.selectItem(withTitle: sortMode.description)
    }

    private func updateSelectedTheme() {
        let theme = SPUserInterface.activeThemeOption
        themePopUp.selectItem(withTag: theme.rawValue)
    }

    private func updateLineLength() {
        if options.editorFullWidth {
            lineLengthFullRadio.state = .on
        } else {
            lineLengthNarrowRadio.state = .on
        }
    }

    // MARK: Account Settings

    @IBAction private func logOutWasPressed(_ sender: Any) {
        let appDelegate = SimplenoteAppDelegate.shared()

        if !StatusChecker.hasUnsentChanges(simperium) {
            appDelegate.signOut()
            self.view.window?.close()
            return
        }

        let alert = NSAlert(messageText: Constants.unsyncedNotesAlertTitle, informativeText: Constants.unsyncedNotesMessage)
        alert.addButton(withTitle: Constants.deleteNotesButton)
        alert.addButton(withTitle: Constants.cancelButton)
        alert.addButton(withTitle: Constants.visitWebButton)
        alert.alertStyle = .critical

        alert.beginSheetModal(for: appDelegate.window) { result in
            switch result {
            case .alertFirstButtonReturn:
                appDelegate.signOut()
            case .alertThirdButtonReturn:
                let url = URL(string: SimplenoteConstants.currentEngineBaseURL as String)!
                NSWorkspace.shared.open(url)
            default:
                break
            }
            self.view.window?.close()
        }

    }

    @IBAction private func deleteAccountWasPressed(_ sender: Any) {
        guard let user = simperium.user else {
            return
        }

        let appDelegate = SimplenoteAppDelegate.shared()

        SPTracker.trackDeleteAccountButttonTapped()
        appDelegate.accountDeletionController?.requestAccountDeletion(for: user, with: appDelegate.window)

        self.view.window?.close()
    }

    // MARK: NoNote List Appearence Settings

    @IBAction private func noteSortOrderWasPressed(_ sender: Any) {
        guard let menu = sender as? NSPopUpButton, let identifier = menu.selectedItem?.identifier, let newMode = SortMode(noteListInterfaceID: identifier) else {
            return
        }

        Options.shared.notesListSortMode = newMode
        SPTracker.trackSettingsNoteListSortMode(newMode.description)
    }

    @IBAction private func noteLineLengthSwitched(_ sender: Any) {
        guard let item = sender as? NSButton else {
            return
        }

        let isFullOn = item.identifier == NSUserInterfaceItemIdentifier.lineFullButton
        Options.shared.editorFullWidth = isFullOn
    }

    @IBAction private func condensedNoteListPressed(_ sender: Any) {
        guard let item = sender as? NSButton,
              item.identifier == NSUserInterfaceItemIdentifier.noteDisplayCondensedButton else {
            return
        }

        let isCondensedOn = item.state == .on
        Options.shared.notesListCondensed = isCondensedOn
        SPTracker.trackSettingsListCondensedEnabled(isCondensedOn)
    }

    @IBAction private func sortTagsAlphabeticallyPressed(_ sender: Any) {
        options.alphabeticallySortTags = !options.alphabeticallySortTags
    }

    // MARK: Theme Settings

    @IBAction private func themeWasPressed(_ sender: Any) {
        guard let menu = sender as? NSPopUpButton,
              let item = menu.selectedItem else {
            return
        }

        guard let option = ThemeOption(rawValue: item.tag) else {
            return
        }

        Options.shared.themeName = option.themeName
    }

    // MARK: Text Settings

    @IBAction private func textSizeHasChanged(_ sender: Any) {
        guard let sender = sender as? NSSlider else {
            return
        }

        options.fontSize = Int(sender.intValue)
        SimplenoteAppDelegate.shared().noteEditorViewController.refreshStyle()
    }


    // MARK: Analytics Settings

    @IBAction private func shareAnalyticsWasPressed(_ sender: Any) {
        guard let sender = sender as? NSButton else {
            return
        }

        let isEnabled = sender.state == .on
        options.analyticsEnabled = isEnabled
    }

    // MARK: About Section

    @IBAction private func aboutWasPressed(_ sender: Any) {
        if let aboutWindow = aboutWindowController?.window {
            if aboutWindow.isVisible {
                aboutWindow.makeKeyAndOrderFront(self)
                return
            }
        }

        let aboutStoryboard = NSStoryboard(name: Constants.aboutStoryboardName, bundle: nil)
        aboutWindowController = aboutStoryboard.instantiateController(withIdentifier: Constants.aboutWindowController) as? NSWindowController
        aboutWindowController?.window?.center()
        aboutWindowController?.showWindow(self)
    }
    
}

private struct Constants {
    static let deleteNotesButton = NSLocalizedString("Delete Notes", comment: "Delete notes and sign out of the app")
    static let cancelButton = NSLocalizedString("Cancel", comment: "Cancel the action")
    static let visitWebButton = NSLocalizedString("Visit Web App", comment: "Visit app.simplenote.com in the browser")
    static let unsyncedNotesAlertTitle = NSLocalizedString("Unsynced Notes Detected", comment: "Alert title displayed in when an account has unsynced notes")
    static let unsyncedNotesMessage = NSLocalizedString("Signing out will delete any unsynced notes. Check your connection and verify your synced notes by signing in to the Web App.", comment: "Alert message displayed when an account has unsynced notes")
    static let aboutStoryboardName = "About"
    static let aboutWindowController = "AboutWindowController"
}
