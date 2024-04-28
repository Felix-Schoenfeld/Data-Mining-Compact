.libPaths( c( .libPaths(), "~/.R/x86_64-pc-linux-gnu-library/4.3") )
# Dieses Script teilt das Sprachen Column in eine eigene Tabelle

# Dieser Teil generiert eine Liste aller Sprachen
library("RSQLite")
con <- dbConnect(SQLite(), dbname = "../db/SteamGames.db")

# Entnehme Felder
results <- dbGetQuery(con, paste("SELECT Supportedlanguages FROM SteamGames"))

list_of_all_languages <- list()

# Transaktion
dbBegin(con)
for (i in 1:nrow(results)) {
  cat(paste(i, "/", nrow(results), "...finding all Languages\n"), sep = "\t")
  entry <- results[i,]

  # Entfernen von [ und ]
  entry <- substr(entry, 2, nchar(entry)-1)

  # Split to List
  list <- as.list(strsplit(entry, split = ","))

  # Interate over Languages in List
  for (lang in list) {
    # Adds Language to the Set of all Languages
    # Remove '
    lang <- gsub("'", '', lang)
    # Remove trailing + leading spaces
    lang <- trimws(lang, "b")
    list_of_all_languages <- c(list_of_all_languages, lang)
  }
}

# Unique Entries
list_of_all_languages <- unique(list_of_all_languages)

writeLines(unlist(list_of_all_languages), "../temp/languages-dirty.txt")

# Entfernen von kaputten Einträgen
# (\\r\\n)|(#)|(&)|(\(text)|(\])|(support\))|(^English.*Dutch.*English$)|(;)|(audio\))
list_of_all_languages <- scan("../temp/languages-dirty.txt", what = "character", sep = "\n")
pattern <- "(\\\\r\\\\n)|(#)|(&)|(\\(text)|(\\])|(support\\))|(^English.*Dutch.*English$)|(;)|(audio\\))"
indices_to_keep <- !grepl(pattern, list_of_all_languages, ignore.case = TRUE)
list_of_all_languages <- list_of_all_languages[indices_to_keep]

# Danach: Duplikate entfernen
list_of_all_languages <- unique(list_of_all_languages)
print(list_of_all_languages)
writeLines(unlist(list_of_all_languages), "../temp/languages-clean.txt")



# Schritt 2: Tabellen befüllen
results <- dbGetQuery(con, paste("SELECT Supportedlanguages, AppId FROM SteamGames"))
# results[,1] -> Language List
# results[,2] -> AppId List

all_languages <- list_of_all_languages

# Sprachtabelle
errors <- 0
id <- 0
for (lang in all_languages) {
  id <- id + 1
  tryCatch({
    # Attempt to execute the INSERT query
    dbSendQuery(con, 'INSERT INTO Languages (LanguageId, LanguageName) VALUES (?, ?);', list(id, lang))
  }, error = function(e) {
    errors <- errors + 1
    # If an error occurs, print the error message
    cat("Error occurred: ", e$message, "\n")
    print(list(id, lang))
  })
}
stopifnot(errors < 1)

# Verbindungstabelle
errors <- 0
for (result_index in seq_along(results[,1])) {

  current_game_lang_list <- results[result_index,1]

  # Über alle möglichen Sprachen iterieren
  for (lang_index in seq_along(all_languages)) {

    # Prüfen ob Sprache bei lang_index sich in Sprachliste bei result_index befindet
    # Wenn ja, in Verbindungstabelle aufnehmen
    current_lang <- all_languages[lang_index]

    if (grepl(current_lang, current_game_lang_list)) {

      # (Debug Output)
      # output <- paste(current_lang, " was found in ")
      # output <- paste(output, current_game_lang_list, "\n")
      # cat(output)

      game_id <- results[result_index,2]
      lang_id <- lang_index

      output <- paste("Inseriting GameId ", game_id)
      output <- paste(output, " LanguageId ")
      output <- paste(output, lang_id, "\n")
      cat(output)

      # Insert
      tryCatch({
        # Attempt to execute the INSERT query
        dbSendQuery(con, 'INSERT INTO UsesLanguage (GameId, LanguageId) VALUES (?, ?);', list(game_id, lang_id))
      }, error = function(e) {
        errors <- errors + 1
        # If an error occurs, print the error message
        cat("Error occurred: ", e$message, "\n")
        print(list(game_id, lang_id))
      })

    }
  }
}
stopifnot(errors < 1)

# Drop old column
sql_statement <- "ALTER TABLE SteamGames DROP COLUMN Supportedlanguages"

dbExecute(con, sql_statement)

# Transaktion durchführen falls keine Fehler aufgetreten sind.
if (errors > 0) {
  dbRollback(con)
} else {
  dbCommit(con)
}

dbDisconnect(con)

cat(paste("Completed with ", errors, " errors.\n"))