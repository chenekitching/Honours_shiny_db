library(DBI)
library(RSQLite)

from_lit <- read.csv("from_lit_for_db.csv")
axiom_table <- read.csv("axiom_table_for_db.csv")
consequence <- read.csv("consequence_for_db.csv")
id_pos <- read.csv("id_pos_for_db.csv")
merged <- read.csv("merged_for_db.csv")


mydb <- dbConnect(RSQLite::SQLite(), "Variant.db")

dbSendQuery(conn = mydb,
            "CREATE TABLE from_lit
            (Paper VARCHAR(500),
            RSID VARCHAR(500),
            [Effect.Allele] TEXT,
            [Ref.Allele] TEXT,
            [p.value] FLOAT,
            Gene VARCHAR(50),
            Population VARCHAR(250),
            Phenotype TEXT,
            FOREIGN KEY(RSID) REFERENCES id_pos(RSID) ON UPDATE CASCADE)
            ")
dbSendQuery(conn = mydb, 
            "CREATE TABLE axiom
            (RSID VARCHAR(500),
            [Ref.Allele] TEXT,
            [Alt.Allele] TEXT,
            FOREIGN KEY(RSID) REFERENCES id_pos(RSID) ON UPDATE CASCADE)")

dbSendQuery(conn = mydb,
            "CREATE TABLE id_pos
            (RSID VARCHAR(50) PRIMARY KEY,
            Chromosome VARCHAR(250),
            Position VARCHAR(50)
            )")

dbSendQuery(conn = mydb,
            "CREATE TABLE consequence
            (RSID VARCHAR(25),
            Allele TEXT,
            Consequence VARCHAR(200),
            [Gene.Symbol] VARCHAR(50),
            AF VARCHAR(50),
            [AFR.AF] VARCHAR(50),
            [AMR.AF] VARCHAR(50),
            [EAS.AF] VARCHAR(50),
            [EUR.AF] VARCHAR(50),
            [SAS.AF] VARCHAR(50),
            [Associated.Phenotypes] VARCHAR(1000),
            [NCBI.dbSNP] VARCHAR(300),
            FOREIGN KEY(RSID) REFERENCES id_pos(RSID) ON UPDATE CASCADE)")

dbSendQuery(conn = mydb,
            "CREATE TABLE merged
            (RSID VARCHAR(500),
            MAF FLOAT,
            Comment TEXT,
            FOREIGN KEY(RSID) REFERENCES id_pos(RSID) ON UPDATE CASCADE)")

dbAppendTable(mydb, "from_lit", from_lit)
dbAppendTable(mydb, "axiom", axiom_table)
dbAppendTable(mydb, "id_pos", id_pos)
dbAppendTable(mydb, "consequence", consequence)
dbAppendTable(mydb, "merged", merged)

test <- dbSendQuery(mydb, "SELECT * FROM from_lit
                    ")
dbFetch(test)
dbDisconnect(mydb)
