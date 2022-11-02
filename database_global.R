
user.access <- data.frame(
  user = c("chene", "user2"),
  password = c("genetics22", "password2")
)

mydb <- dbConnect(RSQLite::SQLite(), "Variant.db")
