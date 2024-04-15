# Dieses Script teilt das Genre Column in eine eigene Tabelle

# Dieser Teil generiert eine Liste aller Genres
library("RSQLite")
con <- dbConnect(SQLite(), dbname = "../db/SteamGames.db")

# Entnehme Felder
results <- dbGetQuery(con, paste("SELECT Genres FROM SteamGames"))

list_of_all_genres <- list()

for (i in 1:nrow(results)) {
  cat(paste(i, "/", nrow(results), "...finding all Genres\n"), sep = "\t")
  entry <- results[i,]

  # Split to List
  list <- as.list(strsplit(entry, split = ","))

  # Interate over Genres in List
  for (genre in list) {
    # Adds Genre to the Set of all Genre
    # Remove '
    genre <- gsub("'", '', genre)
    # Remove trailing + leading spaces
    genre <- trimws(genre, "b")
    list_of_all_genres <- c(list_of_all_genres, genre)
  }
}

# Unique Entries
list_of_all_genres <- unique(list_of_all_genres)

writeLines(unlist(list_of_all_genres), "../temp/genres-dirty.txt")

# Entfernen von kaputten Einträgen
# (NA)
list_of_all_genres <- scan("../temp/genres-dirty.txt", what = "character", sep = "\n")
pattern <- "(NA)"
indices_to_keep <- !grepl(pattern, list_of_all_genres, ignore.case = TRUE)
list_of_all_genres <- list_of_all_genres[indices_to_keep]

# Danach: Duplikate entfernen
list_of_all_genres <- unique(list_of_all_genres)
print(list_of_all_genres)
writeLines(unlist(list_of_all_genres), "../temp/genres-clean.txt")



# Schritt 2: Tabellen befüllen
results <- dbGetQuery(con, paste("SELECT Genres, AppId FROM SteamGames"))
# results[,1] -> Genre List
# results[,2] -> AppId List

all_genres <- list_of_all_genres

# Genretabelle
errors <- 0
id <- 0
for (genre in all_genres) {
  id <- id + 1
  tryCatch({
    # Attempt to execute the INSERT query
    dbSendQuery(con, 'INSERT INTO Genres (GenreId, GenreName) VALUES (?, ?);', list(id, genre))
  }, error = function(e) {
    errors <- errors + 1
    # If an error occurs, print the error message
    cat("Error occurred: ", e$message, "\n")
    print(list(id, genre))
  })
}
stopifnot(errors < 1)

# Verbindungstabelle
errors <- 0
for (result_index in seq_along(results[,1])) {

  current_game_genre_list <- results[result_index,1]

  # Über alle möglichen Genres iterieren
  for (genre_index in seq_along(all_genres)) {

    # Prüfen ob Genre bei genre_index sich in Genreliste bei result_index befindet
    # Wenn ja, in Verbindungstabelle aufnehmen
    current_genre <- all_genres[genre_index]

    if (grepl(current_genre, current_game_genre_list)) {

      # (Debug Output)
      # output <- paste(current_genre, " was found in ")
      # output <- paste(output, current_game_genre_list, "\n")
      # cat(output)

      game_id <- results[result_index,2]
      genre_id <- genre_index

      output <- paste("Inseriting GameId ", game_id)
      output <- paste(output, " GenreId ")
      output <- paste(output, genre_id, "\n")
      cat(output)

      # Insert
      tryCatch({
        # Attempt to execute the INSERT query
        dbSendQuery(con, 'INSERT INTO IsGenre (GameId, GenreId) VALUES (?, ?);', list(game_id, genre_id))
      }, error = function(e) {
        errors <- errors + 1
        # If an error occurs, print the error message
        cat("Error occurred: ", e$message, "\n")
        print(list(game_id, genre_id))
      })

    }
  }
}
stopifnot(errors < 1)

# Drop old column
sql_statement <- "ALTER TABLE SteamGames DROP COLUMN Genres"

dbExecute(con, sql_statement)

dbDisconnect(con)

cat("Completed.")