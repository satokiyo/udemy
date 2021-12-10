package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/mattn/go-sqlite3" // コード内では不使用だが、一緒にビルドする必要あるためimport
)

var DbConnecction *sql.DB

type Person struct {
	Name string
	Age int
}

func main(){
	DbConnecction, _ := sql.Open("sqlite3", "./example.sql")
	defer DbConnecction.Close()
	cmd := `CREATE TABLE IF NOT EXISTS person(
			name STRING,
			age INT)`
	_, err := DbConnecction.Exec(cmd)
	if err != nil{
		log.Fatalln(err)
	}

	cmd = "INSERT INTO person (name, age) VALUES (?, ?)"
	_, err = DbConnecction.Exec(cmd, "Nancy", 20)
	if err != nil{
		log.Fatalln(err)
	}
	_, err = DbConnecction.Exec(cmd, "Nancy", 25) // multiple row
	if err != nil{
		log.Fatalln(err)
	}

	cmd = "UPDATE person SET age = ? WHERE name = ?"
	_, err = DbConnecction.Exec(cmd, 40, "Nancy")
	if err != nil{
		log.Fatalln(err)
	}

	cmd = "SELECT * FROM person"
        // multiple select
	rows, _ := DbConnecction.Query(cmd) 
	defer rows.Close()
	var pp []Person
	for rows.Next(){
		var p Person
		err := rows.Scan(&p.Name, &p.Age)
		if err != nil {
			log.Fatalln(err)
		}
		pp = append(pp, p)
	}
	err = rows.Err()
	if err != nil {
		log.Fatalln(err)
	}
	for _, p := range pp {
		fmt.Println(p.Name, p.Age)
	}

	// single select
	cmd = "SELECT * FROM person WHERE age = ?"
	row := DbConnecction.QueryRow(cmd, 1000)
	var p Person
	err = row.Scan(&p.Name, &p.Age)
	if err != nil {
		if err == sql.ErrNoRows{
			log.Println("No row")
		} else {
			log.Println(err)
		}
	}
	fmt.Println(p.Name, p.Age)

//	// delete
//	cmd = "DELETE FROM person WHERE name = ? "
//	_, err = DbConnecction.Exec(cmd, "Nancy")
//	if err != nil {
//		log.Fatalln(err)
//	}
		
	tableName := "person"
	cmd = fmt.Sprintf("SELECT * FROM %s", tableName)
        // multiple select
	rows, _ = DbConnecction.Query(cmd) 
	defer rows.Close()
	for rows.Next(){
		var p Person
		err := rows.Scan(&p.Name, &p.Age)
		if err != nil {
			log.Fatalln(err)
		}
		pp = append(pp, p)
	}
	err = rows.Err()
	if err != nil {
		log.Fatalln(err)
	}
	for _, p := range pp {
		fmt.Println(p.Name, p.Age)
	}

}