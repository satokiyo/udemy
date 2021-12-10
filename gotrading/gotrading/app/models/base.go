package models

import (
	"database/sql"
	"fmt"
	"gotrading/config"
	"log"
	"time"

	_ "github.com/mattn/go-sqlite3" // ビルドに必要
)

const (
	tableNameSignalEvents = "signal_events"
)

var DbConnection *sql.DB

func GetCandleTableName(productCode string, duration time.Duration) string {
	return fmt.Sprintf("%s_%s", productCode, duration)
}

func init(){
	var err error
	DbConnection, err = sql.Open(config.Config.SQLDriver, config.Config.DbName)
	if err != nil {
		log.Fatalln(err)
	}
	cmd := fmt.Sprintf(`
		CREATE TABLE IF NOT EXISTS %s (
			time DATATIME PRIMARY KEY NOT NULL,
			product_code STRING,
			side STRING,
			price FLOAT,
			size FLOAT)`, tableNameSignalEvents)
	// create table
	DbConnection.Exec(cmd)

	for _, duration := range config.Config.Durations{
		tableName := GetCandleTableName(config.Config.ProductCode, duration) // ex: BTC_USD_1m
		c := fmt.Sprintf(`
			CREATE TABLE IF NOT EXISTS %s (
			time DATATIME PRIMARY KEY NOT NULL,
			open FLOAT,
			close FLOAT,
			high FLOAT,
			low FLOAT,
			volume FLOAT)`, tableName)
		// create table
		DbConnection.Exec(c)
	}
}