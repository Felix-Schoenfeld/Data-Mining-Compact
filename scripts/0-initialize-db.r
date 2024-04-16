# Dieses Script estellt eine SQLite-DB aus der CSV-Datei

library("RSQLite")

db_path <- "../db/SteamGames.db"
csv_path <- "../sources/games.csv"

# Alte Dateien entfernen
if (file.exists(db_path)) {
  file.remove(db_path)
  cat("Alte DB entfernt.\n")
}
cat("Generiere DB...\n")

con <- dbConnect(SQLite(), db_path)
csv_data <- read.csv(csv_path)

dbBegin(con)
# Leerzeichen und Punkte aus Spalten-Namen entfernen
names(csv_data) <- gsub(" ", "", names(csv_data))
names(csv_data) <- gsub("\\.", "", names(csv_data))

dbWriteTable(con, "SteamGames", csv_data, overwrite = TRUE, check.names = FALSE)

# Verhindert, dass Skripte 11 Stunden dauern
dbSendQuery(con, "CREATE INDEX GameIndex on SteamGames(AppId)")
cat("Index added: GameIndex@SteamGames(AppId)\n")

# Tabellen erstellen
# Sprachen
sql_statement <- "CREATE TABLE IF NOT EXISTS Languages (
    LanguageId INTEGER PRIMARY KEY AUTOINCREMENT,
    LanguageName TEXT NOT NULL UNIQUE);"
dbExecute(con, sql_statement)
cat("Table added: Languages\n")
sql_statement <- "CREATE TABLE IF NOT EXISTS UsesLanguage (
    GameId INTEGER NOT NULL,
    LanguageId INTEGER NOT NULL,
    FOREIGN KEY(LanguageId) REFERENCES Languages(LanguageId),
    FOREIGN KEY(GameId) REFERENCES SteamGames(AppID),
    PRIMARY KEY(GameId, LanguageId));"
dbExecute(con, sql_statement)
cat("Table added: UsesLanguage\n")

# Genres
sql_statement <- "CREATE TABLE IF NOT EXISTS Genres (
    GenreId INTEGER PRIMARY KEY AUTOINCREMENT,
    GenreName TEXT NOT NULL UNIQUE);"
dbExecute(con, sql_statement)
cat("Table added: Genres\n")
sql_statement <- "CREATE TABLE IF NOT EXISTS IsGenre (
    GameId INTEGER NOT NULL,
    GenreId INTEGER NOT NULL,
    FOREIGN KEY(GenreId) REFERENCES Genres(GenreId),
    FOREIGN KEY(GameId) REFERENCES SteamGames(AppID),
    PRIMARY KEY(GameId, GenreId));"
dbExecute(con, sql_statement)
cat("Table added: IsGenre\n")

# Kategorien
sql_statement <- "CREATE TABLE IF NOT EXISTS Categories (
    CategoryId INTEGER PRIMARY KEY AUTOINCREMENT,
    CategoryName TEXT NOT NULL UNIQUE);"
dbExecute(con, sql_statement)
cat("Table added: Categories\n")
sql_statement <- "CREATE TABLE IF NOT EXISTS IsCategory (
    GameId INTEGER NOT NULL,
    CategoryId INTEGER NOT NULL,
    FOREIGN KEY(CategoryId) REFERENCES Categories(CategoryId),
    FOREIGN KEY(GameId) REFERENCES SteamGames(AppID),
    PRIMARY KEY(GameId, CategoryId));"
dbExecute(con, sql_statement)
cat("Table added: IsCategory\n")

# Tags
sql_statement <- "CREATE TABLE IF NOT EXISTS Tags (
    TagId INTEGER PRIMARY KEY AUTOINCREMENT,
    TagName TEXT NOT NULL UNIQUE);"
dbExecute(con, sql_statement)
cat("Table added: Tags\n")
sql_statement <- "CREATE TABLE IF NOT EXISTS HasTag (
    GameId INTEGER NOT NULL,
    TagId INTEGER NOT NULL,
    FOREIGN KEY(TagId) REFERENCES Tags(TagId),
    FOREIGN KEY(GameId) REFERENCES SteamGames(AppID),
    PRIMARY KEY(GameId, TagId));"
dbExecute(con, sql_statement)
cat("Table added: HasTag\n")

# Weitere Indexes
# Sprache
dbSendQuery(con, "CREATE INDEX LanguageIndex on Languages(LanguageId)")
cat("Index added: LanguageIndex@Languages(LanguageId)\n")
dbSendQuery(con, "CREATE INDEX UsesLanguageLangugeIndex on UsesLanguage(LanguageId)")
cat("Index added: UsesLanguageLangugeIndex@UsesLanguage(LanguageId)\n")
dbSendQuery(con, "CREATE INDEX UsesLanguageGameIndex on UsesLanguage(GameId)")
cat("Index added: UsesLanguageGameIndex@UsesLanguage(GameId)\n")

# Genre
dbSendQuery(con, "CREATE INDEX GenreIndex on Genres(GenreId)")
cat("Index added: GenreIndex@Genres(GenreId)\n")
dbSendQuery(con, "CREATE INDEX IsGenreGenreIndex on IsGenre(GenreId)")
cat("Index added: IsGenreGenreIndex@IsGenre(GenreId)\n")
dbSendQuery(con, "CREATE INDEX IsGenreGameIndex on IsGenre(GameId)")
cat("Index added: IsGenreGameIndex@IsGenre(GameId)\n")

# Kategorie
dbSendQuery(con, "CREATE INDEX CategoryIndex on Categories(CategoryId)")
cat("Index added: CategoryIndex@Categories(CategoryId)\n")
dbSendQuery(con, "CREATE INDEX IsCategoryCategoryIndex on IsCategory(CategoryId)")
cat("Index added: IsCategoryCategoryIndex@IsCategory(CategoryId)\n")
dbSendQuery(con, "CREATE INDEX IsCategoryGameIndex on IsCategory(GameId)")
cat("Index added: IsCategoryGameIndex@IsCategory(GameId)\n")

# Tags
dbSendQuery(con, "CREATE INDEX TagIndex on Tags(TagId)")
cat("Index added: TagIndex@Tags(TagId)\n")
dbSendQuery(con, "CREATE INDEX HasTagTagIndex on HasTag(TagId)")
cat("Index added: HasTagTagIndex@HasTag(TagId)\n")
dbSendQuery(con, "CREATE INDEX HasTagGameIndex on HasTag(GameId)")
cat("Index added: HasTagGameIndex@HasTag(GameId)\n")

dbCommit(con)
dbDisconnect(con)
cat("DB created.\n")