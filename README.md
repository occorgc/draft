# Draft

Draft è un'applicazione menu bar per macOS che offre un'interfaccia elegante direttamente accessibile dalla barra dei menu.

## Caratteristiche

- Interfaccia minimale accessibile dalla barra dei menu
- Funzionalità completa senza finestre separate
- Esperienza utente ottimizzata per produttività

## Requisiti

- macOS 11.0 o successivo
- Xcode 13.0 o successivo (per compilare)

## Installazione

1. Scarica l'ultima versione dal [repository delle release](https://github.com/USERNAME/draft/releases)
2. Monta il file DMG e trascina l'app nella cartella Applicazioni
3. Apri l'app dalla cartella Applicazioni

## Sviluppo

### Prerequisiti

- Xcode 13.0 o successivo
- Command Line Tools per Xcode

### Compilazione

1. Clona questo repository
2. Apri il progetto `draft.xcodeproj` in Xcode
3. Seleziona il target "draft" e compila
4. Per creare un DMG, esegui `./create_menu_bar_dmg.sh` dal terminale

### Creazione del DMG

Lo script `create_menu_bar_dmg.sh` automatizza il processo di creazione di un file DMG per la distribuzione, impostando l'applicazione come app per la barra dei menu (Menu Bar App).

```bash
chmod +x create_menu_bar_dmg.sh
./create_menu_bar_dmg.sh
```

## Licenza

Questo progetto è distribuito sotto licenza MIT. Vedi il file `LICENSE` per ulteriori dettagli.
