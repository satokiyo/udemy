package main

import (
	"fmt"
	"gotrading/app/models"
	"gotrading/bitflyer"
	"gotrading/config"
	"gotrading/utils"
	"log"
	"time"
)

func main() {
	fmt.Println(config.Config.ApiKey)
	fmt.Println(config.Config.ApiSecret)
	utils.LoggingSettings(config.Config.LogFile)
	log.Println("test")
	apiClient := bitflyer.New(config.Config.ApiKey, config.Config.ApiSecret)
	fmt.Println(apiClient.GetBalance())
	ticker, _ := apiClient.GetTicker("BTC_USD")
	fmt.Println(ticker)
	fmt.Println(ticker.GetMidPrice())
	fmt.Println(ticker.DateTime())
	fmt.Println(ticker.TruncateDateTime(time.Hour))

	//// get data realtime
	//tickerChannel := make(chan bitflyer.Ticker) // Ticker structのチャネルを作成
	//go apiClient.GetRealTimeTicker(config.Config.ProductCode, tickerChannel)
	//for ticker := range tickerChannel {
	//	fmt.Println(ticker)
	//	fmt.Println(ticker.GetMidPrice())
	//	fmt.Println(ticker.TruncateDateTime(time.Second))
	//	fmt.Println(ticker.TruncateDateTime(time.Minute))
	//	fmt.Println(ticker.TruncateDateTime(time.Hour))
	//}

	// DB
	fmt.Println(models.DbConnection)

}
