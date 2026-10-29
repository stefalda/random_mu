---
type: Interview Ledger
parent: spec.md
---

## Records

### L1

Status: current

Question: Quale modalità di riproduzione (sequenziale o casuale) deve essere attiva all'avvio?

Recommended Answer: Sequenziale al primo avvio, poi sempre l'ultima modalità usata (persistita).

Answer: Ok — la modalità rispecchia l'ultima utilizzata.

Decision: La modalità di riproduzione è persistita e viene ripristinata all'avvio; al primo avvio, quando non esiste ancora una preferenza, vale `Sequenziale`.

Constraints:
- La preferenza sopravvive al riavvio dell'app e alla ricostruzione della sessione.
- Il default `Sequenziale` si applica solo quando la preferenza non esiste o è illeggibile.

### L2

Status: current

Question: Android Auto deve seguire la modalità scelta nell'app o mantenere il comportamento attuale (contenitori sempre mescolati)?

Answer: Segue la modalità selezionata in App e permette di cambiarla da interfaccia.

Decision: Il browse tree di Android Auto usa la modalità corrente dell'app e la modalità può essere cambiata dalla UI dell'auto; il cambio si riflette nell'app e in ogni altro consumatore della sessione.

Constraints:
- Cambiare modalità dall'auto equivale a cambiarla dall'app: una sola fonte di verità.
- Il cambio si propaga alla coda in riproduzione secondo L6.

### L3

Status: current

Question: La ricerca locale nelle liste già caricate resta?

Recommended Answer: Si mantiene il filtro istantaneo nelle liste e si aggiunge una ricerca globale (`search3`).

Answer: (confermato implicitamente nella proposta D3)

Decision: Le liste della libreria mantengono il filtro locale istantaneo; in più esiste una ricerca globale su Artisti, Album e Brani tramite `search3`.

Constraints:
- Ogni lista usa il proprio stato di ricerca: non è ammesso un controller di ricerca condiviso fra pagine diverse.

### L4

Status: current

Question: Cosa succede alla `MenuPage` con i sette pulsanti attuali?

Recommended Answer: Viene eliminata; le azioni casuali confluiscono in una voce "Casuale" della Libreria.

Answer: (confermato implicitamente nella proposta D4)

Decision: La `MenuPage` scompare come schermata principale; le azioni `All Random`, `Random by Playing` e `Random by Favorites` diventano le voci di un ingresso "Casuale" nella Libreria.

Constraints:
- Nessuna azione casuale viene rimossa: cambia solo il punto di accesso.
- La schermata iniziale è la Libreria.

### L5

Status: deferred

Question: Serve una selezione multipla per aggiungere più brani insieme a una playlist?

Answer: Fase successiva, non nel primo giro.

Decision: La selezione multipla è rimandata; nel primo giro si aggiunge un brano per volta.

### L6

Status: current

Question: Cambiando modalità mentre una coda sta suonando, cosa succede alla coda corrente?

Answer: Riordino immediato.

Decision: Il cambio di modalità riordina subito la coda in riproduzione: passando a casuale il brano corrente resta al suo posto e il resto viene mescolato; tornando a sequenziale la coda riprende l'ordine originale del contenitore, con il brano corrente mantenuto come traccia in riproduzione.

Constraints:
- Il riordino non deve interrompere l'audio né perdere la posizione di riproduzione.
- L'ordine originale della coda deve essere conservato in memoria per poterlo ripristinare.
- Per le code senza contenitore (risultati di "Play Similar", sessione ripristinata) l'ordine "originale" è quello con cui sono state accodate.

### L7

Status: current

Question: Come si espone il cambio modalità in Android Auto?

Recommended Answer: Azione shuffle standard di sistema (`ACTION_SET_SHUFFLE_MODE` + `shuffleMode` nello stato), senza azioni custom dedicate.

Answer: Azione standard shuffle.

Decision: Android Auto espone il cambio modalità tramite l'azione shuffle standard; lo stato `shuffleMode` della sessione riflette sempre la modalità corrente.

Constraints:
- Nessuna seconda azione custom nella barra dei controlli per la modalità.
- Se l'interfaccia auto invia `setShuffleMode`, l'app deve onorarlo come un cambio di modalità (L2) e riordinare la coda (L6).

### L8

Status: current

Question: I pulsanti "Random by …" (All Random, by Playlist/Artist/Album/Favorites, by Playing) cambiano la modalità persistita?

Answer: Non cambiano la modalità globale.

Decision: Le azioni casuali sono una-tantum: producono una coda mescolata senza modificare la modalità persistita.

Constraints:
- Dopo un'azione casuale, la modalità resta quella precedente e vale per il successivo avvio di un contenitore.
- Il comportamento della coda già accodata è definito solo dall'ordine della coda stessa.

### L9

Status: current

Question: Qual è l'organizzazione di navigazione e delle schermate della libreria?

Recommended Answer:
- Bottom navigation: Libreria | Playlist | Downloads | Cerca.
- Libreria con tab Artisti / Album / Preferiti / Generi.
- Dettagli Album, Artista e Playlist con tracklist ordinate.
- Un solo widget `TrackList` riusato in ogni contesto, con tap = riproduci e long-press = azioni brano.
- Le azioni di contenitore (Riproduci, Casuale, Accoda, Scarica, Aggiungi a playlist) stanno nell'header del dettaglio.

Answer: (confermato implicitamente nella proposta)

Decision: Adottare questa struttura di navigazione e questi dettagli; la tracklist è il mattone unico e riutilizzabile.

Constraints:
- Tap su un brano avvia la riproduzione del suo contenitore a partire da quel brano, nella modalità corrente.
- Le tracklist di album e playlist rispettano l'ordine del contenitore; la tab "Tutti i brani" di un artista usa l'ordine degli album.
- Il long-press su un brano offre almeno: Riproduci ora, Riproduci dopo, Accoda, Aggiungi a playlist, Scarica, Testo.

### L10

Status: current

Question: Si deve poter aggiungere un brano a una playlist mentre si sfoglia la libreria?

Answer: Sì, è uno degli scopi della riorganizzazione.

Decision: L'aggiunta a playlist è disponibile da ogni tracklist (album, artista, playlist, preferiti, genere, ricerca, coda, downloads), non solo dalla coda.

Constraints:
- La sheet di scelta playlist è la stessa in ogni contesto e permette anche di creare una playlist al volo con il brano.

### L11

Status: current

Question: La rimozione di brani da una playlist fa parte di questa Spec?

Answer: Sì, insieme al dettaglio playlist.

Decision: Il dettaglio playlist consente di rimuovere brani e di aggiungerne; la rimozione usa `updatePlaylist` con `songIndexToRemove` (indici della playlist corrente).

Constraints:
- La lista mostrata deve riflettere l'ordine reale della playlist, perché la rimozione è per indice.
- Non è previsto il riordino dei brani: l'API Subsonic non lo supporta.
