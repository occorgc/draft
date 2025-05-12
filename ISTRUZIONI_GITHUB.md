# Istruzioni per caricare su GitHub

Segui questi passaggi per caricare il progetto Draft su GitHub:

## 1. Crea un nuovo repository su GitHub

1. Vai su https://github.com/new
2. Inserisci "draft" come nome del repository
3. Aggiungi una descrizione: "Applicazione menu bar per macOS"
4. Scegli se renderlo pubblico o privato
5. NON inizializzare il repository con un README, .gitignore o licenza (li abbiamo già)
6. Clicca su "Create repository"

## 2. Carica il repository locale su GitHub

Dopo aver creato il repository, esegui questi comandi dal terminale (nella directory del progetto):

```bash
# Collega il repository locale a quello remoto (sostituisci USERNAME con il tuo nome utente GitHub)
git remote add origin https://github.com/USERNAME/draft.git

# Carica tutto il codice sul branch main
git push -u origin main
```

## 3. Verifica

1. Vai su https://github.com/USERNAME/draft per verificare che tutto sia stato caricato correttamente
2. Controlla che non ci siano informazioni personali o sensibili nei file caricati

## Note

- Se preferisci usare SSH invece di HTTPS, usa il formato: git@github.com:USERNAME/draft.git
- Per aggiornamenti futuri, usa semplicemente `git push` dopo aver fatto commit delle modifiche
