package main

import (
	"fmt"
	"sync"
	"time"
)

func goroutine(s string, wg *sync.WaitGroup) {
	defer wg.Done()
	for i := 0; i < 5; i++ {
		fmt.Println(s)
	}
}

func normal(s string) {
	for i := 0; i < 5; i++ {
		fmt.Println(s)
	}
}

func goroutineChn(s []int, c chan int) {
	sum := 0
	for _, v := range s {
		sum += v
	}
	c <- sum
}

func producer(ch chan int, i int) {
	// Something
	fmt.Println("produce", i*2)
	ch <- i * 2
}

func consumer(ch chan int, wg *sync.WaitGroup) {
	for i := range ch { // main側でclose(ch)をするまでrangeは回り続ける
		fmt.Println("process", i*1000)
		wg.Done()
	}
}

func producer2(first chan int) {
	defer close(first) // close()で閉じる
	for i := 0; i < 10; i++ {
		first <- i
	}
}

//func multi2(first chan int, second chan int) {
func multi2(first <-chan int, second chan<- int) {
	defer close(second) // close()で閉じる
	for i := range first {
		second <- i * 2
	}
}

func multi4(second <-chan int, third chan<- int) {
	defer close(third) // close()で閉じる
	for i := range second {
		third <- i * 4
	}
}

func packetReceive1(ch chan string) {
	for {
		ch <- "packet from 1"
		time.Sleep(1 * time.Second)
	}
}

func packetReceive2(ch chan string) {
	for {
		ch <- "packet from 2"
		time.Sleep(1 * time.Second)
	}
}

func main() {
	fmt.Println("lesson5")

	// without channel. stand alone
	var wg sync.WaitGroup
	wg.Add(1)                // 1組の並列処理をWaitGroupに追加
	go goroutine("Go!", &wg) // go routineはスレッド生成の時間がかかるため下のfuncが終わると何もせずに修了してしまう
	normal("Hello")
	wg.Wait() // goroutineは起動が遅いので注意

	// use channel. exchange data
	s := []int{1, 2, 3, 4, 5}
	c := make(chan int)
	go goroutineChn(s, c)
	x := <-c // waitgroup不要。ここでチャネル待ちでブロッキングする
	fmt.Println(x)

	// producer/consumer
	ch := make(chan int)
	// Producer
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go producer(ch, i)
	}
	//Consumer
	go consumer(ch, &wg)
	wg.Wait()
	close(ch) // channel closeしないとconsumerがrangeでずっと回っている

	// fan out fan in
	first := make(chan int)
	second := make(chan int)
	third := make(chan int)

	go producer2(first)
	go multi2(first, second)
	go multi4(second, third) // それぞれのfuncは依存関係のあるchannelをclose()するまで待っているから、WaitGroupは不要みたい
	for result := range third {
		fmt.Println(result)
	}

	// select receive channel
	// 複数のポートでメッセージを待っているようなイメージ
	c1 := make(chan string)
	c2 := make(chan string)
	go packetReceive1(c1)
	go packetReceive2(c2)
OuterLoop:
	for {
		select {
		case msg1 := <-c1:
			fmt.Println(msg1)
		case msg2 := <-c2:
			fmt.Println(msg2)
			break OuterLoop // 単にbreakしても、selectブロックを抜けるだけでforは回り続ける
		}
	}

}
