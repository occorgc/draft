//
//  EditorData.swift
//  draft
//
//  Created by Rocco Geremia Ciccone on 16/04/25.
//

import Foundation
import SwiftUI
import AppKit

class EditorData: ObservableObject {
    @Published var textView: NSTextView?
    @Published var content: NSAttributedString {
        didSet {
            // Salva solo se non stiamo caricando e non è in corso un'operazione di salvataggio
            if !isLoading {
                debouncedSave()
            }
        }
    }
    
    private var isLoading = true
    private var saveWorkItem: DispatchWorkItem?
    
    // Costanti di configurazione
    private enum Constants {
        static let debounceInterval: TimeInterval = 0.5
        static let defaultFontSize: CGFloat = 14
    }

    init() {
        let initialContent = Self.loadInitialContent() ?? NSAttributedString()
        self.content = initialContent
        self.textView = nil
        self.isLoading = false
    }
    
    // --- Metodi per Formattazione ---
    
    func applyBold() {
        applyFontTrait(.bold, mask: .boldFontMask)
    }
    
    func applyItalic() {
        applyFontTrait(.italic, mask: .italicFontMask)
    }
    
    private func applyFontTrait(_ trait: NSFontDescriptor.SymbolicTraits, mask: NSFontTraitMask) {
        guard let textView = self.textView else {
            print("EditorData: No TextView available.")
            return
        }
        
        let selectedRange = textView.selectedRange()
        let fontManager = NSFontManager.shared
        
        if selectedRange.length > 0 {
            // Modifica testo selezionato
            guard let currentAttributes = textView.textStorage?.attributes(at: selectedRange.location, effectiveRange: nil),
                  let currentFont = currentAttributes[.font] as? NSFont else {
                print("EditorData: Cannot get font for selection.")
                return
            }
            
            let currentTraits = currentFont.fontDescriptor.symbolicTraits
            let newFont: NSFont?
            
            if currentTraits.contains(trait) {
                newFont = fontManager.convert(currentFont, toNotHaveTrait: mask)
            } else {
                newFont = fontManager.convert(currentFont, toHaveTrait: mask)
            }
            
            if let fontToApply = newFont {
                textView.textStorage?.addAttribute(.font, value: fontToApply, range: selectedRange)
                textView.didChangeText()
            }
        } else {
            // Modifica attributi di digitazione quando non c'è selezione
            var currentTypingAttributes = textView.typingAttributes
            let currentFont = (currentTypingAttributes[.font] as? NSFont) ?? 
                              textView.font ?? 
                              NSFont.systemFont(ofSize: Constants.defaultFontSize)
            
            let currentTraits = currentFont.fontDescriptor.symbolicTraits
            let newFont: NSFont?
            
            if currentTraits.contains(trait) {
                newFont = fontManager.convert(currentFont, toNotHaveTrait: mask)
            } else {
                newFont = fontManager.convert(currentFont, toHaveTrait: mask)
            }
            
            if let fontToApply = newFont {
                currentTypingAttributes[.font] = fontToApply
                textView.typingAttributes = currentTypingAttributes
            }
        }
    }
    
    // --- Metodi di persistenza ---
    
    // MARK: - Gestione Immagini
    
    // Inserisce un'immagine dal file system
    func insertImageFromPicker() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.image, .jpeg, .png, .pdf, .gif]
        
        openPanel.begin { [weak self] response in
            guard let self = self,
                  response == .OK,
                  let url = openPanel.url,
                  let image = NSImage(contentsOf: url),
                  let textView = self.textView else { return }
            
            textView.insertImage(image)
            self.content = NSAttributedString(attributedString: textView.attributedString())
        }
    }
    
    // Incolla un'immagine dalla clipboard
    func pasteImageFromClipboard() {
        guard let textView = self.textView,
              let pasteboard = NSPasteboard.general.pasteboardItems?.first else { return }
        
        if let imgData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png),
           let image = NSImage(data: imgData) {
            textView.insertImage(image)
            self.content = NSAttributedString(attributedString: textView.attributedString())
        }
    }
    
    // Modifica le dimensioni dell'immagine selezionata
    func resizeSelectedImage(width: CGFloat? = nil, height: CGFloat? = nil) {
        guard let textView = self.textView else { return }
        let selectedRange = textView.selectedRange()
        
        // Verifica se c'è un allegato nell'intervallo selezionato
        guard selectedRange.length > 0,
              let attachment = getSelectedAttachment() else { return }
        
        // Ottieni l'immagine originale
        guard let originalImage = attachment.image else { return }
        
        // Calcola le nuove dimensioni mantenendo le proporzioni
        var newSize = originalImage.size
        
        if let width = width {
            let ratio = width / originalImage.size.width
            newSize = NSSize(width: width, height: originalImage.size.height * ratio)
        } else if let height = height {
            let ratio = height / originalImage.size.height
            newSize = NSSize(width: originalImage.size.width * ratio, height: height)
        }
        
        // Crea immagine ridimensionata
        if let resizedImage = textView.createScaledImage(from: originalImage, to: newSize) {
            // Sostituisci l'immagine nel testo
            attachment.image = resizedImage
            
            // Notifica modifiche
            textView.didChangeText()
            self.content = NSAttributedString(attributedString: textView.attributedString())
        }
    }
    
    // Modifica l'allineamento dell'immagine selezionata
    func alignSelectedImage(_ alignment: NSTextAlignment) {
        guard let textView = self.textView else { return }
        let selectedRange = textView.selectedRange()
        
        // Verifica se c'è un allegato nell'intervallo selezionato
        guard selectedRange.length > 0,
              getSelectedAttachment() != nil else { return }
        
        // Applica il nuovo allineamento
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        
        // Applica lo stile di paragrafo
        textView.textStorage?.addAttribute(.paragraphStyle, value: paragraphStyle, range: selectedRange)
        textView.didChangeText()
        self.content = NSAttributedString(attributedString: textView.attributedString())
    }
    
    // Helper per ottenere l'allegato dell'immagine selezionata, se presente
    private func getSelectedAttachment() -> NSTextAttachment? {
        guard let textView = self.textView else { return nil }
        let selectedRange = textView.selectedRange()
        
        // Verifica se c'è selezione
        guard selectedRange.length > 0 else { return nil }
        
        // Ottieni l'attributedString nella selezione
        if let attributedString = textView.attributedSubstring(forProposedRange: selectedRange, actualRange: nil) {
            // Cerca gli allegati in tutta la selezione
            var foundAttachment: NSTextAttachment? = nil
            
            attributedString.enumerateAttribute(.attachment, in: NSRange(location: 0, length: attributedString.length)) { value, range, stop in
                if let attachment = value as? NSTextAttachment {
                    foundAttachment = attachment
                    stop.pointee = true
                }
            }
            
            if let attachment = foundAttachment {
                return attachment
            }
        }
        
        // Fallback al metodo precedente
        if let attributes = textView.textStorage?.attributes(at: selectedRange.location, effectiveRange: nil),
           let attachment = attributes[.attachment] as? NSTextAttachment {
            return attachment
        }
        
        return nil
    }
    
    private func debouncedSave() {
        saveWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.saveContent()
        }
        
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.debounceInterval, execute: workItem)
    }
    
    private func saveContent() {
        guard textView != nil, content.length > 0 else { return }
        
        do {
            let fileURL = Self.getDocumentURL()
            let range = NSRange(location: 0, length: content.length)
            let fileWrapper = try content.fileWrapper(from: range, documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd])
            try fileWrapper.write(to: fileURL, options: .atomic, originalContentsURL: nil)
        } catch {
            print("Errore durante il salvataggio: \(error)")
        }
    }
    
    static private func loadInitialContent() -> NSAttributedString? {
        let fileURL = getDocumentURL()
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            return nil
        }
        
        do {
            let fileWrapper = try FileWrapper(url: fileURL, options: .immediate)
            return NSAttributedString(rtfdFileWrapper: fileWrapper, documentAttributes: nil)
        } catch {
            print("Errore durante il caricamento: \(error)")
            return nil
        }
    }
    
    static private func getDocumentURL() -> URL {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolderURL = appSupportURL.appendingPathComponent(Bundle.main.appName ?? "draft")
        try? FileManager.default.createDirectory(at: appFolderURL, withIntermediateDirectories: true)
        return appFolderURL.appendingPathComponent("content.rtfd")
    }
}
