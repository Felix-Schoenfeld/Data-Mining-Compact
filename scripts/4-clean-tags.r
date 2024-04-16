# Dieses Script teilt das Tag Column in eine eigene Tabelle

# Dieser Teil generiert eine Liste aller Tags
library("RSQLite")
con <- dbConnect(SQLite(), dbname = "../db/SteamGames.db")

# Entnehme Felder
results <- dbGetQuery(con, paste("SELECT Tags FROM SteamGames"))

list_of_all_tags <- list()

for (i in 1:nrow(results)) {
  cat(paste(i, "/", nrow(results), "...finding all Tags\n"), sep = "\t")
  entry <- results[i,]

  # Split to List
  list <- as.list(strsplit(entry, split = ","))

  # Interate over Tags in List
  for (tag in list) {
    # Adds Tag to the Set of all Tag
    # Remove '
    tag <- gsub("'", '', tag)
    # Remove trailing + leading spaces
    tag <- trimws(tag, "b")
    list_of_all_tags <- c(list_of_all_tags, tag)
  }
}

# Unique Entries
list_of_all_tags <- unique(list_of_all_tags)

writeLines(unlist(list_of_all_tags), "../temp/tags-dirty.txt")

# Entfernen von kaputten Einträgen
# (Keine kaputten Einträge in Tags)

# Danach: Duplikate entfernen
list_of_all_tags <- unique(list_of_all_tags)
print(list_of_all_tags)
writeLines(unlist(list_of_all_tags), "../temp/tags-clean.txt")



# Schritt 2: Tabellen befüllen
results <- dbGetQuery(con, paste("SELECT Tags, AppId FROM SteamGames"))
# results[,1] -> Tag List
# results[,2] -> AppId List

all_tags <- list_of_all_tags

# Tagtabelle
errors <- 0
id <- 0
for (tag in all_tags) {
  id <- id + 1
  tryCatch({
    # Attempt to execute the INSERT query
    dbSendQuery(con, 'INSERT INTO Tags (TagId, TagName) VALUES (?, ?);', list(id, tag))
  }, error = function(e) {
    errors <- errors + 1
    # If an error occurs, print the error message
    cat("Error occurred: ", e$message, "\n")
    print(list(id, tag))
  })
}
stopifnot(errors < 1)

# Verbindungstabelle
errors <- 0
for (result_index in seq_along(results[,1])) {

  current_game_tag_list <- results[result_index,1]

  # Über alle möglichen Tags iterieren
  for (tag_index in seq_along(all_tags)) {

    # Prüfen ob Tag bei tag_index sich in Tagliste bei result_index befindet
    # Wenn ja, in Verbindungstabelle aufnehmen
    current_tag <- all_tags[tag_index]

    if (grepl(current_tag, current_game_tag_list)) {

      # (Debug Output)
      # output <- paste(current_tag, " was found in ")
      # output <- paste(output, current_game_tag_list, "\n")
      # cat(output)

      game_id <- results[result_index,2]
      tag_id <- tag_index

      output <- paste("Inseriting GameId ", game_id)
      output <- paste(output, " TagId ")
      output <- paste(output, tag_id, "\n")
      cat(output)

      # Insert
      tryCatch({
        # Attempt to execute the INSERT query
        dbSendQuery(con, 'INSERT INTO HasTag (GameId, TagId) VALUES (?, ?);', list(game_id, tag_id))
      }, error = function(e) {
        errors <- errors + 1
        # If an error occurs, print the error message
        cat("Error occurred: ", e$message, "\n")
        print(list(game_id, tag_id))
      })

    }
  }
}
stopifnot(errors < 1)

# Drop old column
sql_statement <- "ALTER TABLE SteamGames DROP COLUMN Tags"

dbExecute(con, sql_statement)

dbDisconnect(con)

cat(paste("Completed with ", errors, " errors.\n"))