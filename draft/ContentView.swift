//
//  ContentView.swift
//  draft
//
//  Created by Rocco Geremia Ciccone on 16/04/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var editorData: EditorData
    
    // Definiamo queste enumerazioni qui perché saranno utilizzate nel menu contestuale
    enum ImageSize {
        case small, medium, large
        
        var width: CGFloat {
            switch self {
            case .small: return 200
            case .medium: return 350
            case .large: return 500
            }
        }
        
        var title: String {
            switch self {
            case .small: return "Piccola"
            case .medium: return "Media"
            case .large: return "Grande"
            }
        }
    }
    
    enum ImageAlignment {
        case left, center, right
        
        var nsAlignment: NSTextAlignment {
            switch self {
            case .left: return .left
            case .center: return .center
            case .right: return .right
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Editor senza toolbar
            EditorView()
                .environmentObject(editorData)
        }
    }
}
