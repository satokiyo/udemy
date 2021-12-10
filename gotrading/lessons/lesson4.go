package main

import (
	"fmt"
	"io"
	"log"
	"os"
	"time"
)

type Vertex struct {
	X, Y int // public
	S string
	z string // private
}

// custom error
type UserNotFound struct {
	UserName string
}

func (e *UserNotFound) Error() string{
	// pointer receiverで実装する。
	// エラーが同じ値でも起こった場所によって異なるインスタンスとして、処理を分けられるようにするため
	return "Error! : " + e.UserName
}

func myFunc() error { // errorは予約語。Error()を実装したCustom　structのアドレスを返す
	// something wrong
	ok := false
	if ok{
		return nil
	}
	return &UserNotFound{UserName: "Mike"}
}

// Go におけるコンストラクタ。パッケージ.New()で呼び出すのがデザインパターンとして決まっている。structのポインタを返す
func New(x,y int, s,z string) *Vertex {
	return &Vertex{x,y,s,z}
}

func Area(v Vertex) int {
	return v.X * v.Y
}

// method of struct Vertex
func (v Vertex) Area() int {
	return v.X * v.Y
}

// pointer receiver.
func (v *Vertex) Scale(i int) {
	v.X = v.X * i
	v.Y = v.Y * i
}

// interface : 型のようなもの。メソッドの実装を強制する。未実装の場合エラーとなる
type Human interface {
	Say() string // func Say()の実装を強制する
}

type Person struct {
	Name string
}

func (p *Person) Say() string{
	p.Name = "Mr." + p.Name
	fmt.Println(p.Name)
	return p.Name
}

func DriveCar(human Human){ // interfaceを引数にとる
	if human.Say() == "Mr.Kiyo"{
		fmt.Println("Run")
	}else{
		fmt.Println("Get out")
	}

}



func getOsName() string {
	return "windows"
}

func LoggingSettings(logFile string) {
	logfile, _ := os.OpenFile(logFile, os.O_RDWR|os.O_CREATE|os.O_APPEND, 0666)
	multiLogFile := io.MultiWriter(os.Stdout, logfile)
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)
	log.SetOutput(multiLogFile)
}

func thirdPartyConnectDB() {
	panic("Panic!!")
}

func save() {
	defer func() {
		s := recover()
		fmt.Println("recover!")
		fmt.Println(s)
	}()
	thirdPartyConnectDB()
}

func one(x int) {
	x = 1
}
func pone(x *int) {
	*x = 1
}

func typeassert(i interface{}) {
	// type assertionはinterfaceを特定の型にするもの
	// type convertion(=cast)は型の変換
	// 似ているが微妙に違う
	switch v := i.(type) { // switch とtypeはセットと覚える.　i.(type)でタイプアサーションしている
	case int:
		v *= 2
		fmt.Println("type assertion", i)
	case string:
		fmt.Println( v + "!")
	default:
		fmt.Printf("I dont know %T\n", v)


	}
}

func main() {
	num := 5
	if num%2 == 0 {
		fmt.Println("by 2")
	} else {
		fmt.Println("else")
	}

	for i := 0; i < 10; i++ {
		fmt.Println(i)
	}

	sum := 1
	//for ; sum<100;{ // 省略できる
	for sum < 100 { // ;も省略できる
		sum += sum
		if sum == 2 {
			continue
		}
		if sum > 50 {
			break
		}
		fmt.Println(sum)
	}

	// range
	l := []string{"python", "go", "java"}
	for _, v := range l {
		fmt.Println(v)
	}

	m := map[string]int{
		"apple":  100,
		"banana": 200,
	}
	for k, v := range m {
		fmt.Println(k, v)
	}
	for k := range m { // keyだけ取り出せる
		fmt.Println(k)
	}

	// switch case
	switch os := getOsName(); os {
	case "mac":
		fmt.Println("Mac!!")
	case "windows":
		fmt.Println("Windows!!")
	default:
		fmt.Println("Default!!")
	}

	t := time.Now()
	fmt.Println(t.Hour())
	switch { // switch 条件を書かなくてもいい
	case t.Hour() < 12:
		fmt.Println("Morning")
	case t.Hour() < 17:
		fmt.Println("Afternoon")
	}

	// stacking defer FILO stack
	defer fmt.Println(1)
	defer fmt.Println(2)
	defer fmt.Println(3)

	// logging
	LoggingSettings("test.log")
	log.Println("logging!") // yy/mm/dd hh:mm:ss logging!
	log.Printf("%T %v", "test", "test")
	//log.Fatalln("error! exit.") // Exitしてしまう。deferも実行されないで終わる

	file, err := os.Open("lesson3.go")
	if err != nil {
		log.Fatalln("Error!")
	}
	defer file.Close()            // error発生してexitするとdeferしても実行されないのでここに書く
	data := make([]byte, 100)     // 100 bytes
	count, err := file.Read(data) // err 変数は上で使用されているのにinitialize宣言している。これは左辺に一つでも新しい変数があればinitialize宣言が出来るからで、err 変数については初期化ではなく上書き代入されているのだ
	if err != nil {
		log.Fatalln("Error!")
	}
	fmt.Println("read", count, "bytes\n", string(data))

	// panic recover
	save()
	fmt.Println("OK?")

	// pointer
	var n int = 100
	fmt.Println(&n)
	var p *int = &n
	fmt.Println(p)
	fmt.Println(*p)

	one(n)                                // try to chage value to 1
	fmt.Println("call by value", n)       // not changed.
	pone(p)                               // try to chage value to 1
	fmt.Println("call by refference", *p) // changed.

	// new
	var pp *int = new(int) // new returns a pointer.
	var pp2 *int
	fmt.Println(pp)  // メモリに確保したaddress
	fmt.Println(pp2) // nil. メモリ未確保
	/*
		makeとの違いは、newがポインタを返すこと。
		ch := make(chan int)
		m := make(map[string]int)
		などはメモリ確保するがポインタではない
	*/

	// struct
	v := Vertex{X: 1, Y: 2, S: "test"}
	fmt.Println(v)
	fmt.Println(v.X, v.Y)
	v.X = 100
	fmt.Println(v.X, v.Y)
	v2 := Vertex{1, 2, "test", "private"}
	fmt.Println(v2)
	fmt.Println(v2.z)

	//v3 := Vertex{3,4,"test", "private"}
	v3 := New(3,4,"test", "private")
	fmt.Println(v3.Area()) // call value receiver
	v3.Scale(10) // call pointer receiver
	fmt.Println(v3.Area())

	// interface のダックタイピング
	var kiyo Human = &Person{"Kiyo"} // Human interfaceはメソッドSay()の実装を強制
	DriveCar(kiyo)
	var yasu Human = &Person{"Yasu"} // Human interfaceはメソッドSay()の実装を強制
	DriveCar(yasu)

	// interfaceのタイプアサーション
	//var i interface{} = 10
	typeassert(10)
	typeassert("Mike")
	typeassert(true)
	
	// custom error
	if err := myFunc(); err != nil {
		fmt.Println(err)
	}

}
