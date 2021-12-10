package main

import (
	"awesomeProject/mylib"
	"bytes"
	"context"
	"fmt"
	"io/ioutil"
	"regexp"
	"sort"
	"time"

	"github.com/markcheno/go-quote"
	"github.com/markcheno/go-talib"
	"gopkg.in/ini.v1"
)

const (
	_      = iota             // 0
	KB int = 1 << (10 * iota) // 1kB=1024B=2^10B ※1B=8bitだが、1KB=10bitではない。単に10bit=1024通りであるというだけ。1KBは1B=8bitが2^10=1024個集まったもの。
	MB                        // コンピュータの世界で2進数はビットシフト10回で1024倍になるから、K→M→Gと増えていく
	GB
)

// context
func longProcess(ctx context.Context, ch chan string) {
	fmt.Println("run")
	time.Sleep(2 * time.Second)
	fmt.Println("finish")
	ch <- "result"
}

// use config.ini
type ConfigList struct{
	Port int
	DbName string
	SQLDriver string
} 

var Config ConfigList

// mainの前に呼ばれる
func init(){
	cfg, _ := ini.Load("config.ini") // ローカルファイル読み込み 
	Config = ConfigList{
		Port: cfg.Section("web").Key("port").MustInt(),
		DbName: cfg.Section("db").Key("name").MustString("example.sql"), // example.sqlをdefaultとする
		SQLDriver: cfg.Section("db").Key("driver").String(),

	}
}



func main() {
	s := []int{1, 2, 3, 4, 5}
	fmt.Println(mylib.Average(s))
	spy, _ := quote.NewQuoteFromYahoo("spy", "2016-01-01", "2016-06-01", quote.Daily, true)
	rsi2 := talib.Rsi(spy.Close, 2)
	fmt.Println(rsi2)

	// time
	t := time.Now()
	fmt.Println(t.Format(time.RFC3339))

	// regex
	match, _ := regexp.MatchString(("a[a-z0-9]+le"), "app99le")
	fmt.Println(match)

	r := regexp.MustCompile("a[a-z0-9]+le")
	ms := r.MatchString("app99le")
	fmt.Println(ms)

	r2 := regexp.MustCompile("^/(edit|save|view)/([a-zA-Z0-9]+)$")
	fs := r2.FindString("/view/test")
	fmt.Println(fs)

	// sort
	ii := []int{5, 4, 2, 6, 4, 2, 9, 7, 7}
	ss := []string{"Bob", "Nancy", "Akira"}
	pp := []struct {
		Name string
		Age  int
	}{
		{"Nancy", 20},
		{"Vera", 39},
		{"Andre", 19},
	}

	fmt.Println(ii, ss, pp)
	sort.Ints(ii)
	fmt.Println(ii)
	sort.Strings(ss)
	fmt.Println(ss)
	sort.Slice(pp, func(i, j int) bool { return pp[i].Age > pp[j].Age })
	fmt.Println(pp)

	// iota
	fmt.Println(KB)
	fmt.Println(MB)
	fmt.Println(GB)

	// context
	ch := make(chan string)
	ctx := context.Background()
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	go longProcess(ctx, ch)

CTXLOOP:
	for {
		select {
		case <-ctx.Done():
			fmt.Println(ctx.Err()) // timeout
			break CTXLOOP
		case <-ch:
			fmt.Println("success")
			break CTXLOOP
		}
	}
	fmt.Println("##########################")

	// ioutil
	//content, err := ioutil.ReadFile("mylib/math.go")
	//if err != nil{
	//	log.Fatalln(err)
	//}
	//fmt.Println(string(content))

	//if err := ioutil.WriteFile("ioutil_temp.go", content, 0666); err != nil{
	//	log.Fatalln(err)
	//}
	
	rr := bytes.NewBuffer([]byte("abc"))
	content, _ := ioutil.ReadAll(rr)
	fmt.Println(string(content))

	// config.iniの読み込みチェック
	fmt.Printf("%T %v\n", Config.Port, Config.Port)
	fmt.Printf("%T %v\n", Config.DbName, Config.DbName)
	fmt.Printf("%T %v\n", Config.SQLDriver, Config.SQLDriver)

}
