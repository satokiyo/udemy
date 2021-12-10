package main

import (
	_ "fmt"
	"io/ioutil"
	"log"
	"net/http"
	"regexp"
	"text/template"
)

type Page struct {
	Title string
	Body  []byte
}

func (p *Page) save() error {
	filename := p.Title + ".txt"
	return ioutil.WriteFile(filename, p.Body, 0600)
}

func loadPage(title string) (*Page, error) {
	filename := title + ".txt"
	body, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, err
	}
	return &Page{Title: title, Body: body}, nil
}

var templates = template.Must(template.ParseFiles("edit.html", "view.html"))

func renderTemplate(w http.ResponseWriter, tmpl string, p *Page){
	//t, _ := template.ParseFiles(tmpl + ".html")
	//t.Execute(w, p)
	// ファイル読み込みでなくキャッシュしたテンプレートを使う
	err := templates.ExecuteTemplate(w, tmpl+".html", p)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func viewHandler(w http.ResponseWriter, r *http.Request, title string){
	// /view/test
	//title := r.URL.Path[len("/view/"):] // python like slicing!
	p, err := loadPage(title)
	//fmt.Fprintf(w, "<h1>%s</h1><div>%s</div>", p.Title, p.Body)
	if err != nil { // /view/xxxのxxxに対応するページがまだ存在しなければeditして作成する
		http.Redirect(w,r,"/edit/"+title, http.StatusFound)
		return
	}
	renderTemplate(w, "view",  p)
}

func editHandler(w http.ResponseWriter, r *http.Request, title string){
	// /edit/test
	//title := r.URL.Path[len("/edit/"):] // python like slicing!
	p, err := loadPage(title)
	if err != nil {
		p = &Page{Title: title}
	}
	renderTemplate(w, "edit",  p)
}

func saveHandler(w http.ResponseWriter, r *http.Request, title string){
	// /save/test
	//title := r.URL.Path[len("/save/"):] // python like slicing!
	body := r.FormValue("body") // form のtextareaのname="body"
	p := &Page{Title: title, Body: []byte(body)}
	err := p.save()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.Redirect(w, r, "/view/"+title, http.StatusFound)
}

var validPath = regexp.MustCompile("^/(edit|save|view)/([a-zA-Z0-9]+)$")

// Handler関数のラッパー
func makeHandler(fn func(http.ResponseWriter, *http.Request, string)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request){
		m := validPath.FindStringSubmatch(r.URL.Path)
		if m == nil {
			http.NotFound(w,r)
			return 
		}
		fn(w, r, m[2])
	}
}

func main() {
	//p1 := &Page{Title: "test", Body: []byte("This is a sample Page.")}
	//p1.save()

	//p2, _ := loadPage(p1.Title)
	//fmt.Println(string(p2.Body))
	http.HandleFunc("/view/", makeHandler(viewHandler))
	http.HandleFunc("/edit/", makeHandler(editHandler))
	http.HandleFunc("/save/", makeHandler(saveHandler))
	log.Fatal(http.ListenAndServe(":8080", nil))

}