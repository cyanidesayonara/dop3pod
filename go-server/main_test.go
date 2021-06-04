// main_test.go

package main

import (
	"log"
	"os"
	"testing"

	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strconv"
)

var a App

func TestMain(m *testing.M) {
	a.Initialize(
		os.Getenv("APP_DB_USERNAME"),
		os.Getenv("APP_DB_PASSWORD"),
		os.Getenv("APP_DB_NAME"))

	ensureTableExists()
	code := m.Run()
	clearTable()
	os.Exit(code)
}

func ensureTableExists() {
	if _, err := a.DB.Exec(tableCreationQuery); err != nil {
		log.Fatal(err)
	}
}

func clearTable() {
	a.DB.Exec("DELETE FROM podcasts")
	a.DB.Exec("ALTER SEQUENCE podcasts_id_seq RESTART WITH 1")
}

const tableCreationQuery = `CREATE TABLE IF NOT EXISTS podcasts
(
    id SERIAL,
    name TEXT NOT NULL,
    price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT podcasts_pkey PRIMARY KEY (id)
)`

func TestEmptyTable(t *testing.T) {
	clearTable()

	req, _ := http.NewRequest("GET", "/podcasts", nil)
	response := executeRequest(req)

	checkResponseCode(t, http.StatusOK, response.Code)

	if body := response.Body.String(); body != "[]" {
		t.Errorf("Expected an empty array. Got %s", body)
	}
}

func executeRequest(req *http.Request) *httptest.ResponseRecorder {
	rr := httptest.NewRecorder()
	a.Router.ServeHTTP(rr, req)

	return rr
}

func checkResponseCode(t *testing.T, expected, actual int) {
	if expected != actual {
		t.Errorf("Expected response code %d. Got %d\n", expected, actual)
	}
}

func TestGetNonExistentPodcast(t *testing.T) {
	clearTable()

	req, _ := http.NewRequest("GET", "/podcast/11", nil)
	response := executeRequest(req)

	checkResponseCode(t, http.StatusNotFound, response.Code)

	var m map[string]string
	json.Unmarshal(response.Body.Bytes(), &m)
	if m["error"] != "Podcast not found" {
		t.Errorf("Expected the 'error' key of the response to be set to 'Podcast not found'. Got '%s'", m["error"])
	}
}

func TestCreatePodcast(t *testing.T) {

	clearTable()

	var jsonStr = []byte(`{"name":"test podcast", "price": 11.22}`)
	req, _ := http.NewRequest("POST", "/podcast", bytes.NewBuffer(jsonStr))
	req.Header.Set("Content-Type", "application/json")

	response := executeRequest(req)
	checkResponseCode(t, http.StatusCreated, response.Code)

	var m map[string]interface{}
	json.Unmarshal(response.Body.Bytes(), &m)

	if m["name"] != "test podcast" {
		t.Errorf("Expected podcast name to be 'test podcast'. Got '%v'", m["name"])
	}

	if m["price"] != 11.22 {
		t.Errorf("Expected podcast price to be '11.22'. Got '%v'", m["price"])
	}

	// the id is compared to 1.0 because JSON unmarshaling converts numbers to
	// floats, when the target is a map[string]interface{}
	if m["id"] != 1.0 {
		t.Errorf("Expected podcast id to be '1'. Got '%v'", m["id"])
	}
}

func TestGetPodcast(t *testing.T) {
	clearTable()
	addPodcasts(1)

	req, _ := http.NewRequest("GET", "/podcast/1", nil)
	response := executeRequest(req)

	checkResponseCode(t, http.StatusOK, response.Code)
}

// main_test.go

func addPodcasts(count int) {
	if count < 1 {
		count = 1
	}

	for i := 0; i < count; i++ {
		a.DB.Exec("INSERT INTO podcasts(name, price) VALUES($1, $2)", "Podcast "+strconv.Itoa(i), (i+1.0)*10)
	}
}

func TestUpdatePodcast(t *testing.T) {

	clearTable()
	addPodcasts(1)

	req, _ := http.NewRequest("GET", "/podcast/1", nil)
	response := executeRequest(req)
	var originalPodcast map[string]interface{}
	json.Unmarshal(response.Body.Bytes(), &originalPodcast)

	var jsonStr = []byte(`{"name":"test podcast - updated name", "price": 11.22}`)
	req, _ = http.NewRequest("PUT", "/podcast/1", bytes.NewBuffer(jsonStr))
	req.Header.Set("Content-Type", "application/json")

	response = executeRequest(req)

	checkResponseCode(t, http.StatusOK, response.Code)

	var m map[string]interface{}
	json.Unmarshal(response.Body.Bytes(), &m)

	if m["id"] != originalPodcast["id"] {
		t.Errorf("Expected the id to remain the same (%v). Got %v", originalPodcast["id"], m["id"])
	}

	if m["name"] == originalPodcast["name"] {
		t.Errorf("Expected the name to change from '%v' to '%v'. Got '%v'", originalPodcast["name"], m["name"], m["name"])
	}

	if m["price"] == originalPodcast["price"] {
		t.Errorf("Expected the price to change from '%v' to '%v'. Got '%v'", originalPodcast["price"], m["price"], m["price"])
	}
}

func TestDeletePodcast(t *testing.T) {
	clearTable()
	addPodcasts(1)

	req, _ := http.NewRequest("GET", "/podcast/1", nil)
	response := executeRequest(req)
	checkResponseCode(t, http.StatusOK, response.Code)

	req, _ = http.NewRequest("DELETE", "/podcast/1", nil)
	response = executeRequest(req)

	checkResponseCode(t, http.StatusOK, response.Code)

	req, _ = http.NewRequest("GET", "/podcast/1", nil)
	response = executeRequest(req)
	checkResponseCode(t, http.StatusNotFound, response.Code)
}
