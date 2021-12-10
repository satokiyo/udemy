package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/url"
)

type T struct {}

type Person struct {
	Name      string   `json:"name"` // jsonにするときのkeyを別途指定できる
	Age       int      `json:"age,string"` // jsonにするときはstringにする指定
	Nicknames []string `json:"nicknames,omitempty"` // 空文字列だったら無視する
	T         *T       `json:"T,omitempty"`
}

// json.Marshalをカスタマイズしたい場合に書くメソッド
//func (p Person) MarshalJSON() ([]byte, error) {
//	v, err := json.Marshal(struct{
//		Name string
//	}{
//		Name:  "Mr." + p.Name,
//	})
//	return v, err
//}

// json.Marshalをカスタマイズしたい場合に書くメソッド
//func (p *Person) UnmarshalJSON(b []byte) error {
//	type Person2 struct {
//		Name string
//	}
//	var p2 Person2
//	err := json.Unmarshal(b, &p2)
//	if err != nil{
//		fmt.Println(err)
//	}
//	p.Name = p2.Name + "!!!"
//	return err
//}

func main() {
	resp, err := http.Get("http://example.com")
	if err != nil {
		log.Fatalln("error")
	}
	defer resp.Body.Close()
	body, _ := ioutil.ReadAll(resp.Body)
	fmt.Println(string(body))

	// ulr.Parse()で、URLが正しいものかどうかを判定する
	base, err := url.Parse("http://example.com")
	fmt.Println(base, err)

	// get requestを送る場合、？に続けて書く。また、&でつなぐ
	reference, _ := url.Parse("/test?a=1&b=2")
	endpoint := base.ResolveReference(reference).String() // ResolveReference()で、baseURLが間違っていたりしても正しいURLを作ってくれる
	fmt.Println(endpoint)

	// get request
	req, err := http.NewRequest("GET", endpoint, nil) // POSTの場合はnilではなくデータを入れる
	//req, err := http.NewRequest("POST", endpoint, bytes.NewBuffer([]byte("password")))
	if err != nil {
		log.Fatalln("Error!")
	}
	req.Header.Add("If-None-Match", `W/"wyzzy"`) // ヘッダをつけることで、Webサーバに対してキャッシュを使う/使わないなどを指定できる
	q := req.URL.Query()                         // queryの取り出し.上で指定した？に続くqueryがmap形式で取得できる
	fmt.Println(q)
	q.Add("c", "3&%") // key : value でqueryを追加
	fmt.Println(q)
	fmt.Println(q.Encode()) // &はqueryにおいて区切り文字なので、クエリのvalueとしては、エンコードされて%26とかになる
	req.URL.RawQuery = q.Encode()

	var client *http.Client = &http.Client{}
	resp, _ = client.Do(req)
	body, _ = ioutil.ReadAll(resp.Body)
	fmt.Println(string(body))

	// json.Unmarshal
	b := []byte(`{"name":"mike", "age":20, "nicknames":["a","b","c"]}`) // structのメンバはpublicで大文字で始まるが、小文字でも上手くUnmarshalしてくれる
	var p Person
	if err := json.Unmarshal(b, &p); err != nil {
		fmt.Println(err)
	}
	fmt.Println(p.Name, p.Age, p.Nicknames)

	// json.Marshal -> inverse of Unmarshal
	v, _ := json.Marshal(p)
	fmt.Println(string(v))

}
