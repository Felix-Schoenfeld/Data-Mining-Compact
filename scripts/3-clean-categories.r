.libPaths( c( .libPaths(), "~/.R/x86_64-pc-linux-gnu-library/4.3") )
# Dieses Script teilt das Categories Column in eine eigene Tabelle

# Dieser Teil generiert eine Liste aller Categories
library("RSQLite")
con <- dbConnect(SQLite(), dbname = "../db/SteamGames.db")

# Entnehme Felder
results <- dbGetQuery(con, paste("SELECT Categories FROM SteamGames"))

list_of_all_categories <- list()

# Transaktion
dbBegin(con)
for (i in 1:nrow(results)) {
  cat(paste(i, "/", nrow(results), "...finding all Categories\n"), sep = "\t")
  entry <- results[i,]

  # Split to List
  list <- as.list(strsplit(entry, split = ","))

  # Interate over Categories in List
  for (category in list) {
    # Adds Category to the Set of all Category
    # Remove '
    category <- gsub("'", '', category)
    # Remove trailing + leading spaces
    category <- trimws(category, "b")
    list_of_all_categories <- c(list_of_all_categories, category)
  }
}

# Unique Entries
list_of_all_categories <- unique(list_of_all_categories)

writeLines(unlist(list_of_all_categories), "../temp/categories-dirty.txt")

# Entfernen von kaputten Einträgen
# (Keine kaputten Einträge in Categories)
list_of_all_categories <- scan("../temp/categories-dirty.txt", what = "character", sep = "\n")

# Danach: Duplikate entfernen
list_of_all_categories <- unique(list_of_all_categories)
print(list_of_all_categories)
writeLines(unlist(list_of_all_categories), "../temp/categories-clean.txt")



# Schritt 2: Tabellen befüllen
results <- dbGetQuery(con, paste("SELECT Categories, AppId FROM SteamGames"))
# results[,1] -> Category List
# results[,2] -> AppId List

all_categories <- list_of_all_categories

# Categorytabelle
errors <- 0
id <- 0
for (category in all_categories) {
  id <- id + 1
  tryCatch({
    # Attempt to execute the INSERT query
    dbSendQuery(con, 'INSERT INTO Categories (CategoryId, CategoryName) VALUES (?, ?);', list(id, category))
  }, error = function(e) {
    errors <- errors + 1
    # If an error occurs, print the error message
    cat("Error occurred: ", e$message, "\n")
    print(list(id, category))
  })
}
stopifnot(errors < 1)

# Verbindungstabelle
errors <- 0
for (result_index in seq_along(results[,1])) {

  current_game_category_list <- results[result_index,1]

  # Über alle möglichen Categories iterieren
  for (category_index in seq_along(all_categories)) {

    # Prüfen ob Category bei category_index sich in Categoryliste bei result_index befindet
    # Wenn ja, in Verbindungstabelle aufnehmen
    current_category <- all_categories[category_index]

    if (grepl(current_category, current_game_category_list)) {

      # (Debug Output)
      # output <- paste(current_category, " was found in ")
      # output <- paste(output, current_game_category_list, "\n")
      # cat(output)

      game_id <- results[result_index,2]
      category_id <- category_index

      output <- paste("Inseriting GameId ", game_id)
      output <- paste(output, " CategoryId ")
      output <- paste(output, category_id, "\n")
      cat(output)

      # Insert
      tryCatch({
        # Attempt to execute the INSERT query
        dbSendQuery(con, 'INSERT INTO IsCategory (GameId, CategoryId) VALUES (?, ?);', list(game_id, category_id))
      }, error = function(e) {
        errors <- errors + 1
        # If an error occurs, print the error message
        cat("Error occurred: ", e$message, "\n")
        print(list(game_id, category_id))
      })

    }
  }
}
stopifnot(errors < 1)

# Drop old column
sql_statement <- "ALTER TABLE SteamGames DROP COLUMN Categories"

dbExecute(con, sql_statement)

# Transaktion durchführen falls keine Fehler aufgetreten sind.
if (errors > 0) {
  dbRollback(con)
} else {
  dbCommit(con)
}

dbDisconnect(con)

cat(paste("Completed with ", errors, " errors.\n"))