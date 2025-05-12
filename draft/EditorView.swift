//
//  EditorView.swift
//  draft
//
//  Created by Rocco Geremia Ciccone on 16/04/25.
//

import SwiftUI
import AppKit

struct EditorView: NSViewRepresentable {
    @EnvironmentObject var editorData: EditorData
    
    // Costanti di configurazione
    private enum Constants {
        static let defaultFontSize: CGFloat = 14
        static let defaultFont = NSFont.systemFont(ofSize: defaultFontSize)
        static let defaultTextColor = NSColor.labelColor
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, editorData: editorData)
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        // Configura ScrollView
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        
        // Configura TextView
        let textView = createConfiguredTextView()
        
        // Carica contenuto esistente se presente
        if editorData.content.length > 0 {
            textView.textStorage?.setAttributedString(editorData.content)
        }
        
        // Imposta delegate e abilita drag & drop
        textView.delegate = context.coordinator
        textView.registerForDraggedTypes([.fileURL, .URL, .tiff, .png])
        
        // Salva riferimento nella classe EditorData
        editorData.textView = textView
        
        // Imposta textView come documento della scrollView
        scrollView.documentView = textView
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        // Non sono necessarie azioni qui, poiché lo stato è gestito tramite EditorData
    }
    
    // MARK: - Helper Methods
    
    private func createConfiguredTextView() -> NSTextView {
        let textView = NSTextView()
        
        // Proprietà base
        configureBaseProperties(for: textView)
        
        // Stile
        configureStyle(for: textView)
        
        // Layout
        configureLayout(for: textView)
        
        return textView
    }
    
    private func configureBaseProperties(for textView: NSTextView) {
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = true
        textView.importsGraphics = true
    }
    
    private func configureStyle(for textView: NSTextView) {
        textView.backgroundColor = NSColor.white
        textView.insertionPointColor = NSColor.black
        textView.typingAttributes = [
            .font: Constants.defaultFont,
            .foregroundColor: NSColor.black
        ]
        textView.font = Constants.defaultFont
    }
    
    private func configureLayout(for textView: NSTextView) {
        // Configurazione contenitore
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        
        // Dimensioni
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        
        // Comportamento resize
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditorView
        var editorData: EditorData
        
        init(_ parent: EditorView, editorData: EditorData) {
            self.parent = parent
            self.editorData = editorData
        }
        
        // Menu contestuale (tasto destro del mouse)
        func textView(_ textView: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
            // Crea un nuovo menu contestuale
            let contextMenu = NSMenu()
            
            // Aggiungiamo prima le voci standard di copia/incolla
            contextMenu.addItem(NSMenuItem(title: "Taglia", action: #selector(NSText.cut(_:)), keyEquivalent: ""))
            contextMenu.addItem(NSMenuItem(title: "Copia", action: #selector(NSText.copy(_:)), keyEquivalent: ""))
            contextMenu.addItem(NSMenuItem(title: "Incolla", action: #selector(NSText.paste(_:)), keyEquivalent: ""))
            contextMenu.addItem(NSMenuItem.separator())
            
            // Opzioni di formattazione testo
            let textFormatMenu = NSMenu()
            
            let boldItem = NSMenuItem(title: "Grassetto", action: #selector(AppDelegate.applyBoldAction(_:)), keyEquivalent: "")
            boldItem.target = NSApp.delegate
            textFormatMenu.addItem(boldItem)
            
            let italicItem = NSMenuItem(title: "Corsivo", action: #selector(AppDelegate.applyItalicAction(_:)), keyEquivalent: "")
            italicItem.target = NSApp.delegate
            textFormatMenu.addItem(italicItem)
            
            let formatMenuItem = NSMenuItem(title: "Formattazione testo", action: nil, keyEquivalent: "")
            formatMenuItem.submenu = textFormatMenu
            contextMenu.addItem(formatMenuItem)
            
            // Verifica se c'è un allegato (immagine) selezionato
            let selectedRange = textView.selectedRange()
            
            // Controlliamo se c'è un'immagine nella selezione
            let hasSelectedImage = selectedRange.length > 0 && textView.attributedSubstring(forProposedRange: selectedRange, actualRange: nil)?.containsAttachments == true
            
            // Menu per l'inserimento e gestione immagini
            let insertImageItem = NSMenuItem(title: "Inserisci immagine", action: #selector(AppDelegate.insertImageAction(_:)), keyEquivalent: "")
            insertImageItem.target = NSApp.delegate
            contextMenu.addItem(insertImageItem)
            
            if hasSelectedImage {
                contextMenu.addItem(NSMenuItem.separator())
                
                // Dimensioni immagine
                let imageSizeMenu = NSMenu()
                
                let smallSizeItem = NSMenuItem(title: "Dimensione piccola", action: #selector(AppDelegate.resizeImageSmallAction(_:)), keyEquivalent: "")
                smallSizeItem.target = NSApp.delegate
                imageSizeMenu.addItem(smallSizeItem)
                
                let mediumSizeItem = NSMenuItem(title: "Dimensione media", action: #selector(AppDelegate.resizeImageMediumAction(_:)), keyEquivalent: "")
                mediumSizeItem.target = NSApp.delegate
                imageSizeMenu.addItem(mediumSizeItem)
                
                let largeSizeItem = NSMenuItem(title: "Dimensione grande", action: #selector(AppDelegate.resizeImageLargeAction(_:)), keyEquivalent: "")
                largeSizeItem.target = NSApp.delegate
                imageSizeMenu.addItem(largeSizeItem)
                
                let imageSizeMenuItem = NSMenuItem(title: "Dimensione immagine", action: nil, keyEquivalent: "")
                imageSizeMenuItem.submenu = imageSizeMenu
                contextMenu.addItem(imageSizeMenuItem)
                
                // Allineamento immagine
                let imageAlignMenu = NSMenu()
                
                let leftAlignItem = NSMenuItem(title: "Allinea a sinistra", action: #selector(AppDelegate.alignImageLeftAction(_:)), keyEquivalent: "")
                leftAlignItem.target = NSApp.delegate
                imageAlignMenu.addItem(leftAlignItem)
                
                let centerAlignItem = NSMenuItem(title: "Allinea al centro", action: #selector(AppDelegate.alignImageCenterAction(_:)), keyEquivalent: "")
                centerAlignItem.target = NSApp.delegate
                imageAlignMenu.addItem(centerAlignItem)
                
                let rightAlignItem = NSMenuItem(title: "Allinea a destra", action: #selector(AppDelegate.alignImageRightAction(_:)), keyEquivalent: "")
                rightAlignItem.target = NSApp.delegate
                imageAlignMenu.addItem(rightAlignItem)
                
                let imageAlignMenuItem = NSMenuItem(title: "Allineamento immagine", action: nil, keyEquivalent: "")
                imageAlignMenuItem.submenu = imageAlignMenu
                contextMenu.addItem(imageAlignMenuItem)
            }
            
            return contextMenu
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            self.editorData.content = NSAttributedString(attributedString: textView.attributedString())
        }
        
        func textView(_ textView: NSTextView, validateDrop draggingInfo: NSDraggingInfo) -> NSDragOperation {
            return .copy
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextInRanges affectedRanges: [NSValue], replacementStrings: [String]?) -> Bool {
            // Gestisci l'incolla per immagini dalla clipboard
            if NSApp.currentEvent?.type == .keyDown,
               NSApp.currentEvent?.modifierFlags.contains(.command) == true,
               NSApp.currentEvent?.charactersIgnoringModifiers == "v" {
                // Se ci sono immagini nella clipboard, lascia che la pasteImageFromClipboard gestisca
                // l'inserimento dell'immagine
                let pasteboard = NSPasteboard.general
                if pasteboard.canReadObject(forClasses: [NSImage.self], options: nil) ||
                   pasteboard.data(forType: .tiff) != nil ||
                   pasteboard.data(forType: .png) != nil {
                    DispatchQueue.main.async {
                        self.editorData.pasteImageFromClipboard()
                    }
                    return false
                }
            }
            return true
        }
        
        func textView(_ textView: NSTextView, acceptDrop draggingInfo: NSDraggingInfo) -> Bool {
            let pasteboard = draggingInfo.draggingPasteboard
            
            // Supporto per file immagine via drag & drop
            if let fileUrls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
                for fileUrl in fileUrls {
                    if let image = NSImage(contentsOf: fileUrl) {
                        textView.insertImage(image)
                        self.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))
                        return true
                    }
                }
            }
            
            // Supporto per immagini direttamente trascinate
            if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], 
               let image = images.first {
                textView.insertImage(image)
                self.textDidChange(Notification(name: NSText.didChangeNotification, object: textView))
                return true
            }
            
            return false
        }
    }
}

// MARK: - NSTextView Extension

extension NSTextView {
    func insertImage(_ image: NSImage) {
        guard let textStorage = self.textStorage else { return }
        
        let attachment = NSTextAttachment()
        
        // Ottimizza e ridimensiona l'immagine
        let processedImage = processImageForInsertion(image)
        attachment.image = processedImage
        
        // Crea attributedString con l'allegato e centratura
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        attachmentString.addAttribute(.paragraphStyle, value: paragraphStyle, 
                                     range: NSRange(location: 0, length: attachmentString.length))
        
        // Aggiungi uno spazio prima e dopo per facilitare la selezione
        let finalString = NSMutableAttributedString(string: "\n")
        finalString.append(attachmentString)
        finalString.append(NSAttributedString(string: "\n"))
        
        // Inserisci nel testo
        let insertionRange = self.selectedRange()
        if self.shouldChangeText(in: insertionRange, replacementString: finalString.string) {
            textStorage.replaceCharacters(in: insertionRange, with: finalString)
            self.setSelectedRange(NSRange(location: insertionRange.location + 1, length: 1))
            self.didChangeText()
        }
    }
    
    // Processa e ottimizza l'immagine prima dell'inserimento
    func processImageForInsertion(_ image: NSImage) -> NSImage {
        // Ottieni larghezza disponibile
        let maxWidth = self.textContainer?.containerSize.width ?? self.bounds.width - 40
        
        // Calcola dimensioni appropriate
        let imageSize = calculateOptimalImageSize(image: image, maxWidth: maxWidth)
        
        // Ridimensiona se necessario
        if imageSize.width < image.size.width || imageSize.height < image.size.height {
            return createScaledImage(from: image, to: imageSize) ?? image
        }
        
        return optimizeImageQuality(image)
    }
    
    // Calcola dimensioni ottimali per l'immagine
    func calculateOptimalImageSize(image: NSImage, maxWidth: CGFloat) -> NSSize {
        // Limita la larghezza massima (considerando anche i margini)
        let effectiveMaxWidth = max(100, min(maxWidth, 600))
        
        // Se l'immagine è già più piccola, mantieni le dimensioni originali
        if image.size.width <= effectiveMaxWidth {
            return image.size
        }
        
        // Altrimenti ridimensiona proporzionalmente
        let scale = effectiveMaxWidth / image.size.width
        return NSSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
    }
    
    // Ridimensiona l'immagine preservando la qualità
    func createScaledImage(from image: NSImage, to size: NSSize) -> NSImage? {
        // Crea una nuova immagine con le dimensioni desiderate
        let newImage = NSImage(size: size)
        
        newImage.lockFocus()
        // Imposta interpolazione di alta qualità per un migliore downsampling
        NSGraphicsContext.current?.imageInterpolation = .high
        
        // Disegna l'immagine originale sulla nuova, applicando il ridimensionamento
        image.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: image.size),
            operation: .sourceOver,
            fraction: 1.0
        )
        newImage.unlockFocus()
        
        return optimizeImageQuality(newImage)
    }
    
    // Ottimizza la qualità dell'immagine, in particolare per le immagini ad alta risoluzione
    private func optimizeImageQuality(_ image: NSImage) -> NSImage {
        // Per immagini ad alta risoluzione (Retina), manteniamo il doppio della risoluzione necessaria
        // Questo garantisce che le immagini appariranno nitide anche su display ad alta densità
        
        // Conserva la rappresentazione originale per preservare la qualità
        if let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData) {
            bitmap.size = image.size
            
            // Imposta le proprietà per la qualità ottimale
            let optimizedImage = NSImage(size: image.size)
            optimizedImage.addRepresentation(bitmap)
            
            return optimizedImage
        }
        
        return image
    }
}

// MARK: - NSAttributedString Extension

extension NSAttributedString {
    var containsAttachments: Bool {
        var hasAttachment = false
        self.enumerateAttribute(.attachment, in: NSRange(location: 0, length: self.length)) { value, range, stop in
            if value != nil {
                hasAttachment = true
                stop.pointee = true
            }
        }
        return hasAttachment
    }
}
