//
//  AppDelegate.swift
//  draft
//
//  Created in 2025
//

import Foundation
import SwiftUI
import AppKit

extension Bundle {
    var appName: String? {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
               object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var editorData = EditorData()
    
    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        setupMainMenu()
    }
    
    // MARK: - UI Setup
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "pencil.and.outline", accessibilityDescription: "Draft")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 350, height: 400)
        popover.behavior = .transient
        popover.animates = true
        
        let contentView = ContentView().environmentObject(editorData)
        popover.contentViewController = NSHostingController(rootView: contentView)
        popover.contentViewController?.view.window?.delegate = self
    }
    
    private func setupMainMenu() {
        let mainMenu = NSApp.mainMenu ?? NSMenu(title: "MainMenu")
        mainMenu.removeAllItems()
        
        // App Menu
        mainMenu.addItem(createAppMenu())
        
        // Edit Menu
        mainMenu.addItem(createEditMenu())
        
        // Format Menu
        mainMenu.addItem(createFormatMenu())
        
        NSApp.mainMenu = mainMenu
    }
    
    // MARK: - Menu Creation
    
    private func createAppMenu() -> NSMenuItem {
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "AppMenu")
        
        let appName = Bundle.main.appName ?? "Draft"
        let quitItem = NSMenuItem(
            title: "Quit \(appName)",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = .command
        appMenu.addItem(quitItem)
        
        appMenuItem.submenu = appMenu
        return appMenuItem
    }
    
    private func createEditMenu() -> NSMenuItem {
        let editMenuItem = NSMenuItem()
        editMenuItem.title = "Edit"
        let editMenu = NSMenu(title: "Edit")
        
        // Undo/Redo
        editMenu.addItem(withTitle: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        
        // Cut/Copy/Paste
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(NSMenuItem.separator())
        
        // Select All
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        
        editMenuItem.submenu = editMenu
        return editMenuItem
    }
    
    private func createFormatMenu() -> NSMenuItem {
        let formatMenuItem = NSMenuItem()
        formatMenuItem.title = "Format"
        let formatMenu = NSMenu(title: "Format")
        
        // Font Submenu
        let fontMenuItem = NSMenuItem()
        fontMenuItem.title = "Font"
        let fontMenu = NSMenu(title: "Font")
        
        // Bold
        let boldMenuItem = NSMenuItem(
            title: "Bold",
            action: #selector(applyBoldAction(_:)),
            keyEquivalent: "b"
        )
        boldMenuItem.keyEquivalentModifierMask = .command
        boldMenuItem.target = self
        fontMenu.addItem(boldMenuItem)
        
        // Italic
        let italicMenuItem = NSMenuItem(
            title: "Italic",
            action: #selector(applyItalicAction(_:)),
            keyEquivalent: "i"
        )
        italicMenuItem.keyEquivalentModifierMask = .command
        italicMenuItem.target = self
        fontMenu.addItem(italicMenuItem)
        
        // Add font submenu to format menu
        fontMenuItem.submenu = fontMenu
        formatMenu.addItem(fontMenuItem)
        
        // Inserimento Immagini
        formatMenu.addItem(NSMenuItem.separator())
        
        let insertImageItem = NSMenuItem(
            title: "Inserisci Immagine...",
            action: #selector(insertImageAction(_:)),
            keyEquivalent: "p"
        )
        insertImageItem.keyEquivalentModifierMask = [.command, .shift]
        insertImageItem.target = self
        formatMenu.addItem(insertImageItem)
        
        // Gestione Immagini Submenu
        let imageManagementItem = NSMenuItem()
        imageManagementItem.title = "Gestione Immagine"
        let imageManagementMenu = NSMenu(title: "Gestione Immagine")
        
        // Dimensioni
        let resizeImageSmallItem = NSMenuItem(
            title: "Dimensione Piccola",
            action: #selector(resizeImageSmallAction(_:)),
            keyEquivalent: "1"
        )
        resizeImageSmallItem.keyEquivalentModifierMask = [.command, .option]
        resizeImageSmallItem.target = self
        imageManagementMenu.addItem(resizeImageSmallItem)
        
        let resizeImageMediumItem = NSMenuItem(
            title: "Dimensione Media",
            action: #selector(resizeImageMediumAction(_:)),
            keyEquivalent: "2"
        )
        resizeImageMediumItem.keyEquivalentModifierMask = [.command, .option]
        resizeImageMediumItem.target = self
        imageManagementMenu.addItem(resizeImageMediumItem)
        
        let resizeImageLargeItem = NSMenuItem(
            title: "Dimensione Grande",
            action: #selector(resizeImageLargeAction(_:)),
            keyEquivalent: "3"
        )
        resizeImageLargeItem.keyEquivalentModifierMask = [.command, .option]
        resizeImageLargeItem.target = self
        imageManagementMenu.addItem(resizeImageLargeItem)
        
        imageManagementMenu.addItem(NSMenuItem.separator())
        
        // Allineamento
        let alignLeftItem = NSMenuItem(
            title: "Allinea a Sinistra",
            action: #selector(alignImageLeftAction(_:)),
            keyEquivalent: "["
        )
        alignLeftItem.keyEquivalentModifierMask = [.command, .option]
        alignLeftItem.target = self
        imageManagementMenu.addItem(alignLeftItem)
        
        let alignCenterItem = NSMenuItem(
            title: "Allinea al Centro",
            action: #selector(alignImageCenterAction(_:)),
            keyEquivalent: "\\"
        )
        alignCenterItem.keyEquivalentModifierMask = [.command, .option]
        alignCenterItem.target = self
        imageManagementMenu.addItem(alignCenterItem)
        
        let alignRightItem = NSMenuItem(
            title: "Allinea a Destra",
            action: #selector(alignImageRightAction(_:)),
            keyEquivalent: "]"
        )
        alignRightItem.keyEquivalentModifierMask = [.command, .option]
        alignRightItem.target = self
        imageManagementMenu.addItem(alignRightItem)
        
        // Aggiungi submenu alla voce principale
        imageManagementItem.submenu = imageManagementMenu
        formatMenu.addItem(imageManagementItem)
        
        formatMenuItem.submenu = formatMenu
        return formatMenuItem
    }
    
    // MARK: - Actions
    
    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if let textView = self.editorData.textView {
                    _ = textView.window?.makeFirstResponder(textView)
                }
            }
        }
    }
    
    @objc func applyBoldAction(_ sender: Any?) {
        editorData.applyBold()
    }
    
    @objc func applyItalicAction(_ sender: Any?) {
        editorData.applyItalic()
    }
    
    @objc func insertImageAction(_ sender: Any?) {
        editorData.insertImageFromPicker()
    }
    
    // MARK: - Azioni di Gestione Immagini
    
    @objc func resizeImageSmallAction(_ sender: Any?) {
        editorData.resizeSelectedImage(width: 200)
    }
    
    @objc func resizeImageMediumAction(_ sender: Any?) {
        editorData.resizeSelectedImage(width: 350)
    }
    
    @objc func resizeImageLargeAction(_ sender: Any?) {
        editorData.resizeSelectedImage(width: 500)
    }
    
    @objc func alignImageLeftAction(_ sender: Any?) {
        editorData.alignSelectedImage(.left)
    }
    
    @objc func alignImageCenterAction(_ sender: Any?) {
        editorData.alignSelectedImage(.center)
    }
    
    @objc func alignImageRightAction(_ sender: Any?) {
        editorData.alignSelectedImage(.right)
    }
}
