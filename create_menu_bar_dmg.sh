#!/bin/bash

# Script per creare un file .app eseguibile per un'applicazione menu bar e impacchettarlo in un DMG
# Questo script configura un'app macOS come applicazione per la barra dei menu (menu bar app)
# Licenza: MIT
# Data: 2025

# Impostazioni configurabili
APP_NAME="draft"                  # Nome dell'applicazione
APP_VERSION="1.0"                 # Versione dell'applicazione
DMG_NAME="${APP_NAME}_${APP_VERSION}_MenuBar"
VOLUME_NAME="${APP_NAME} Menu Bar"
SOURCE_APP="./draft.o1/draft.app" # Percorso all'app compilata (modificare se necessario)
DMG_TEMP_DIR="./dmg_tmp"          # Directory temporanea per il DMG
DMG_BACKGROUND_IMG=""             # Percorso all'immagine di sfondo (opzionale)
DMG_WINDOW_POS="400 100"          # Posizione della finestra del DMG
DMG_WINDOW_SIZE="800 500"         # Dimensione della finestra del DMG
DMG_ICON_SIZE="128"               # Dimensione dell'icona
DMG_ICON_POS_X="416"              # Posizione X dell'icona
DMG_ICON_POS_Y="192"              # Posizione Y dell'icona
APPLICATIONS_SYMLINK_POS_X="128"  # Posizione X del link alle Applicazioni
APPLICATIONS_SYMLINK_POS_Y="192"  # Posizione Y del link alle Applicazioni

# Verifica che l'app esista
if [ ! -d "$SOURCE_APP" ]; then
    echo "Errore: l'app sorgente '$SOURCE_APP' non esiste."
    echo "Assicurati di aver compilato il progetto Xcode prima di eseguire questo script."
    exit 1
fi

# Assicurati che l'app abbia i permessi di esecuzione
chmod +x "${SOURCE_APP}/Contents/MacOS/${APP_NAME}"

# Verifica che Info.plist contenga la proprietà LSUIElement per menu bar app
INFO_PLIST="${SOURCE_APP}/Contents/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    # Verifica se LSUIElement è già presente
    LSUIELEMENT_EXISTS=$(/usr/libexec/PlistBuddy -c "Print :LSUIElement" "$INFO_PLIST" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "Aggiungendo LSUIElement=1 a Info.plist per creare un'app menu bar..."
        /usr/libexec/PlistBuddy -c "Add :LSUIElement bool true" "$INFO_PLIST"
    elif [ "$LSUIELEMENT_EXISTS" != "true" ]; then
        echo "Impostando LSUIElement=1 in Info.plist..."
        /usr/libexec/PlistBuddy -c "Set :LSUIElement true" "$INFO_PLIST"
    else
        echo "LSUIElement è già impostato correttamente in Info.plist."
    fi
else
    echo "Attenzione: Info.plist non trovato in ${INFO_PLIST}"
    exit 1
fi

# Crea directory temporanea per il DMG
echo "Preparazione directory temporanea per il DMG..."
rm -rf "$DMG_TEMP_DIR"
mkdir -p "$DMG_TEMP_DIR"
cp -R "$SOURCE_APP" "$DMG_TEMP_DIR"

# Crea link alla cartella Applicazioni per facilitare l'installazione
echo "Creazione link alla cartella Applicazioni..."
mkdir -p "$DMG_TEMP_DIR/.background"
ln -s /Applications "$DMG_TEMP_DIR/Applications"

# Aggiungi immagine di sfondo se specificata
if [ ! -z "$DMG_BACKGROUND_IMG" ]; then
    cp "$DMG_BACKGROUND_IMG" "$DMG_TEMP_DIR/.background/background.png"
fi

# Crea il DMG
echo "Creazione del DMG..."
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$DMG_TEMP_DIR" -ov -format UDZO "${DMG_NAME}.dmg"

# Rimuovi la directory temporanea
echo "Pulizia..."
rm -rf "$DMG_TEMP_DIR"

echo "DMG creato correttamente: ${DMG_NAME}.dmg"

# Aggiungi metadati e styling al DMG (richiede create-dmg, installabile con 'brew install create-dmg')
if command -v create-dmg &> /dev/null; then
    echo "Miglioramento del DMG con create-dmg..."
    mv "${DMG_NAME}.dmg" "${DMG_NAME}_temp.dmg"
    
    create-dmg \
        --volname "$VOLUME_NAME" \
        --volicon "$SOURCE_APP/Contents/Resources/AppIcon.icns" \
        --window-pos $DMG_WINDOW_POS \
        --window-size $DMG_WINDOW_SIZE \
        --icon-size $DMG_ICON_SIZE \
        --icon "$APP_NAME.app" $DMG_ICON_POS_X $DMG_ICON_POS_Y \
        --app-drop-link $APPLICATIONS_SYMLINK_POS_X $APPLICATIONS_SYMLINK_POS_Y \
        "${DMG_NAME}.dmg" \
        "${DMG_TEMP_DIR}"
        
    # Rimuovi il DMG temporaneo
    rm "${DMG_NAME}_temp.dmg"
else
    echo "Nota: installa 'create-dmg' con 'brew install create-dmg' per un DMG con stile migliorato."
fi

echo "Processo completato. L'app menu bar è stata preparata e impacchettata in ${DMG_NAME}.dmg"
