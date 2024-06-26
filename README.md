### Info

Datenbank kann jederzeit mithilfe der Scripte in `scripts/` aus der `sources/game.csv` erstellt werden.

Dazu Scripte in der richtigen Reihenfolge ausführen.
```bash
cd scripts
Rscript 0-initialize-db.r
Rscript 1-clean-languages.r
...
```

### Preperation: Auteilen der Datenbank-Columns in eigene Tabellen

Fertig:
- DB Generieren aus CSV
  - Script: `0-initialize-db.r`
- Column SteamGames.`SupportedLanguages` -> Table `Languages` +  Table `UsesLanguage`
  - Script: `1-clean-languages.r`
- Column SteamGames.`Genres` -> Table `Genres` + Table `IsGenre`
  - Script: `2-clean-genres.r`
- Column SteamGames.`Categories` -> Table `Categories` + Table `IsCategory`
  - Script: `3-clean-categories.r`
- Column SteamGames.`Tags` -> Table `Tags` + Table `HasTag`
  - Script: `4-clean-tags.r`
- Column SteamGames.`Releasedate` (format)
  - Script: `5-clean-releasedate.r`

ToDo:
- ...


Nice to have:
- Column SteamGames.`Estimatedowners`
- Column SteamGames.`Developers`
- Column SteamGames.`Publishers`
- Schnellere Scripts

Wahrscheinlich nicht benötigt:
- Column SteamGames.`Fullaudiolangauges`
- Column SteamGames.`Screenshots`
- Column SteamGames.`Movies`
