package main

import (
	"fmt"
	"strconv"
	"strings"
	//"os/user"
	//"time"
)

/*
func init(){ // 最初に呼ばれる
	fmt.Println(("Init"))
}
*/

const ( // constは型を指定しない変数宣言。なので、Print時などの実行時に型が遅延的に決定する
	Pi       = 3.14 // 外部から呼ばれるグローバル変数(関数)は大文字で始める
	Username = "test_user"
	Password = "test_pass"
)

var ( // var での宣言は関数外でも宣言出来る
	i    int     = 1
	f64  float64 = 1.2
	s    string  = "test"
	t, f bool    = true, false
)

func foo() {
	// shortの宣言法。関数外では宣言できないのがvarとの違い
	xi := 1
	xi = 2 // 上書き
	xf64 := 1.2
	xs := "string"
	xt := true
	xf := false
	fmt.Printf("%T, %v\n", f64, f64) // 型を出力
	fmt.Println(xi, xf64, xs, xt, xf)
	var xf32 float32 = 1.2
	fmt.Printf("%T, %v\n", xf32, xf32) // shortタイプの宣言では型を指定できないみたい。指定する場合はvarで宣言

	// shift operation
	fmt.Println(1 << 0) // 0001
	fmt.Println(1 << 1) // 0010
	fmt.Println(1 << 2) // 0100
	fmt.Println(1 << 3) // 1000
	fmt.Println(1 << 4) // 10000
	fmt.Println(1 << 5) // 10000

	// string
	fmt.Println(("Hello " + "World!!")[0])          // output ascii code 72
	fmt.Println(string(("Hello " + "World!!")[:3])) // output Hel
	var s string = "Hello Hello Hello World!!"
	fmt.Println(strings.Replace(s, "He", "Be", 2)) // 型のstringとは違う。package

	// type conversion
	var x int = 1
	xx := float64(x)
	fmt.Printf("%T %v %f\n", xx, xx, xx)

	var ss string = "14"
	i, _ := strconv.Atoi(ss)
	fmt.Printf("%T %v\n", i, i)

	// array
	var a [2]int = [2]int{100, 100}
	//var a = [2]int{100, 100} // 型宣言しなくてもいける
	fmt.Println(a)
	/*
		a = append(a, 100) // 配列はappend出来ない
	*/

	// slice
	//var slice[]int = []int{100, 200}
	var slice = []int{100, 200} // 型宣言しなくてもいける
	slice = append(slice, 300)  // sliceにはappend出来る
	fmt.Println(slice)

	var board [][]int = [][]int{
		{0, 1, 2},
		{0, 1, 2},
		{0, 1, 2},
	}
	fmt.Println(board)

	// make cap of slice
	n := make([]int, 3, 5) // make 3, capacity 5
	fmt.Printf("len=%d cap=%d value=%v\n", len(n), cap(n), n)
	n = append(n, 0, 0)
	fmt.Printf("len=%d cap=%d value=%v\n", len(n), cap(n), n)
	n = append(n, 0, 0)
	fmt.Printf("len=%d cap=%d value=%v\n", len(n), cap(n), n)

	var c []int = make([]int, 5) // make 5, capacity 5 となり、メモリに確保済み。appendはその後ろに追加される！
	for i := 0; i < 5; i++ {
		c = append(c, i)
		fmt.Println(c)
	}

	var cc []int = make([]int, 0, 5)
	for i := 0; i < 5; i++ {
		cc = append(cc, i)
		fmt.Println(cc)
	}

	// map
	m := map[string]int{"apple": 100, "banana": 200}
	fmt.Println(m)
	v, ok := m["apple"]
	fmt.Println(v, ok)
	v2, ok2 := m["nokey"]
	fmt.Println(v2, ok2)

	m2 := make(map[string]int)
	m2["pc"] = 300
	fmt.Println(m2) // ok

	var m3 map[string]int
	/*
		m3["pc"] = 300 // NG. makeでメモリを確保してないので、空のmapにassignしようとするとpanicとなる
	*/
	fmt.Println(m3)
	fmt.Println(nil == m3) // true. 空のsliceやmapはmakeしないとデフォルトではnilとなっている

	// byte
	b := []byte{72, 73}
	fmt.Println(b)
	fmt.Println(string(b))

	c3 := []byte("HI") // byte sliceキャスト
	fmt.Println(c3)
	fmt.Println(string(c3))

}

func add(x, y int) (r1, r2 int) {
	r1, r2 = x+y, x-y
	return // ネイキッドリターン
}

func convert(x int) float64 { // 戻り値が分かりやすいものは戻り値の変数名はつけない方がいい
	return float64(x)
}

// closure1
func incrementGenerator() func() int {
	x := 0
	return func() int {
		x++
		return x
	}
}


// closure2
func circleArea(pi float64) func(radius float64) float64{
	return func(radius float64) float64 {
		return pi * radius * radius
	}
}

// 可変長引数
func bar(params ...int){
	fmt.Println(len(params), params)
	for _, param := range params{
		fmt.Println(param)
	}
}

func main() {
	//fmt.Println("Hello World!", time.Now()) // private func は小文字で始まる。大文字のPulbic funcのみ呼び出せる
	//fmt.Println(user.Current())
	//var ( // 初期化しない場合、初期値が入る
	//	i int
	//	f64 float64
	//	s string
	//	t, f bool
	//)
	fmt.Println(i, f64, s, t, f)
	foo()
	r1, r2 := add(10, 20)
	fmt.Println(r1, r2)

	func(s string) {
		fmt.Println("Inner func", s)
	}("enter!")

	counter := incrementGenerator()
	fmt.Println(counter())
	fmt.Println(counter())
	fmt.Println(counter())
	fmt.Println(counter())

	area := circleArea(3.1415)
	fmt.Println(area(2))
	area2 := circleArea(3.14)
	fmt.Println(area2(2))

	s := []int{10,20}
	bar(s...)
	//bar(s) // []int型は可変長intの引数としては渡せない
	s2 := []int{10,20,30}
	bar(s2...)
}
