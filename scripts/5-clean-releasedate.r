# Dieses Script säubert weitere Spalten der Tabelle.

# ReleaseDate format
library("RSQLite")
library(stringr)
con <- dbConnect(SQLite(), dbname = "../db/SteamGames.db")
results <- dbGetQuery(con, paste("SELECT Releasedate, AppId FROM SteamGames"))

months <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

errors <- 0
count <- 0
total <- length(results[,2])

dbBegin(con)
for (i in seq_len(total)) {
  count <- count + 1
  current_date_str <- results[i,1]
  current_id <- results[i,2]

  month <- str_pad(which(months == substring(current_date_str, 1, 3)), 2, pad = "0")
  if (substring(current_date_str, 6, 6) == ',') {
    day <- paste("0", substring(current_date_str, 5, 5), sep = "")
    year <- substring(current_date_str, 8, 11)
  } else {
    day <- substring(current_date_str, 5, 6)
    year <- substring(current_date_str, 9, 12)
  }

  new_date <- paste(year, "-", month, "-", day, sep = "")

  status_progress <- paste("(", count, "/", total, ")", sep = "")
  status <- paste(current_date_str, "->", new_date, status_progress, "\n", sep = "\t")
  cat(status)

  # Replace entry with new entry
  query <- "UPDATE SteamGames
  SET Releasedate = (?)
  WHERE AppId = (?);"
  tryCatch({
    dbSendStatement(con, query, list(new_date, current_id))
  }, error = function(e) {
    errors <- errors + 1
    # If an error occurs, print the error message
    cat("Error occurred: ", e$message, "\n")
    print(list(new_date, current_id))
  })

}

# Transaktion durchführen falls keine Fehler aufgetreten sind.
if (errors > 0) {
  dbRollback(con)
} else {
  dbCommit(con)
}
