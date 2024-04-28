.libPaths( c( .libPaths(), "~/.R/x86_64-pc-linux-gnu-library/4.3") )
library("RSQLite")

db_path <- "../db/SteamGames.db"
stopifnot(file.exists(db_path))

con <- dbConnect(SQLite(), db_path)
dbBegin(con)

# INDEX on Name
dbSendQuery(con, "CREATE INDEX NameIndex on SteamGames(Name)")
cat("Index added: NameIndex@SteamGames(Name)\n")


# Remove duplicate Names
# Entnehme Felder
results <- dbGetQuery(con, paste("SELECT Name, AppID FROM SteamGames"))

list_of_all_names <- list()
# results[,1] -> Name List
# results[,2] -> AppId List
list_to_remove <- list()

for (i in seq_along(results[,1])) {
  cat(paste(i, "/", nrow(results), "...finding duplicate Names...\n"), sep = "\t")
  entry <- results[i,1]


  # to lowercase, without spaces
  game_name <- gsub("\\s", "", tolower(entry))
  cat(game_name, "\n")
  # check if in list
  if (game_name %in% list_of_all_names){
    # if yes remove @ AppId
    list_to_remove <- c( results[i,2] , list_to_remove )
  } else {
    # if not add
    list_of_all_names <- c( game_name, list_of_all_names )
  }  
}

for (i in seq_along(list_to_remove)) {
    cat(paste(i, "/", length(list_to_remove), "...deleting duplicate Names...", "[", list_to_remove[i], "]\n"), sep = "\t")

   # drop from SteamGames DB 
   dbSendQuery(con, "DELETE FROM SteamGames WHERE AppId = (?)", list_to_remove[i])
}

dbCommit(con)
cat("Done.\n")