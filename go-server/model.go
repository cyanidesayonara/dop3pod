// model.go

package main

import (
	"database/sql"
)

type podcast struct {
	ID    int     `json:"id"`
	Name  string  `json:"name"`
	Price float64 `json:"price"`
}

func (p *podcast) getPodcast(db *sql.DB) error {
	return db.QueryRow("SELECT name, price FROM podcasts WHERE id=$1",
		p.ID).Scan(&p.Name, &p.Price)
}

func (p *podcast) updatePodcast(db *sql.DB) error {
	_, err :=
		db.Exec("UPDATE podcasts SET name=$1, price=$2 WHERE id=$3",
			p.Name, p.Price, p.ID)

	return err
}

func (p *podcast) deletePodcast(db *sql.DB) error {
	_, err := db.Exec("DELETE FROM podcasts WHERE id=$1", p.ID)

	return err
}

func (p *podcast) createPodcast(db *sql.DB) error {
	err := db.QueryRow(
		"INSERT INTO podcasts(name, price) VALUES($1, $2) RETURNING id",
		p.Name, p.Price).Scan(&p.ID)

	if err != nil {
		return err
	}

	return nil
}

func getPodcasts(db *sql.DB, start, count int) ([]podcast, error) {
	rows, err := db.Query(
		"SELECT id, name,  price FROM podcasts LIMIT $1 OFFSET $2",
		count, start)

	if err != nil {
		return nil, err
	}

	defer rows.Close()

	podcasts := []podcast{}

	for rows.Next() {
		var p podcast
		if err := rows.Scan(&p.ID, &p.Name, &p.Price); err != nil {
			return nil, err
		}
		podcasts = append(podcasts, p)
	}

	return podcasts, nil
}
