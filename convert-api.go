package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/exec"
	"time"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"github.com/savaki/swag"
	"github.com/savaki/swag/endpoint"
	"github.com/savaki/swag/swagger"
)

const apiStub = "/api/v1"
const logStdout = true
const apiServerHost = "0.0.0.0"
const apiServerPort = "9000"

const convertBinPath = "/convert.sh"

var hits int

func main() {

	// init the hits counter
	hits++

	// init the REST router and declare endpoints
	r := mux.NewRouter()

	postConvert := endpoint.New("POST", "/convert", "Fire up doxtak-convert",
		endpoint.Handler(convertHandler),
		endpoint.Response(http.StatusOK, convertResponse{}, "Reterns ok"),
		endpoint.Tags("Convert"),
	)

	healthCheck := endpoint.New("GET", "/ping", "Check if doxtak-convert is up",
		endpoint.Handler(pingHandler),
		endpoint.Tags("Ping"),
	)

	api := swag.New(
		swag.Endpoints(
			postConvert,
			healthCheck,
		),
		swag.Title("DoXtak Convert"),
		swag.Description("DoXtak convert API"),
		swag.ContactEmail("ayoub.bousselmi@orange.com"),
		swag.License("MIT", "https://opensource.org/licenses/MIT"),
		swag.Version("v1"),
		swag.BasePath(apiStub),
		swag.Tag("Convert", "Convert operation"),
		swag.Tag("Ping", "Heath Check operation"),
	)

	api.Walk(func(path string, endpoint *swagger.Endpoint) {
		swagh := endpoint.Handler.(http.HandlerFunc)
		r.Path(path).Methods(endpoint.Method).Handler(swagh)
	})
	r.Path("/swagger.json").Methods("GET").Handler(api.Handler(true))
	if logStdout {
		r.Walk(apiWalk)
	}

	// start the server
	log.Println("Serving HTTP on " + apiServerHost + " port " + apiServerPort + " ...")
	var customHandler http.Handler = r
	if logStdout {
		customHandler = handlers.LoggingHandler(os.Stdout, r)
	}
	log.Fatal(http.ListenAndServe(apiServerHost+":"+apiServerPort, customHandler))

}

func apiWalk(route *mux.Route, router *mux.Router, ancestors []*mux.Route) error {
	path, err := route.GetPathTemplate()
	log.Println("[+] route -", path)
	return err
}

// convert response message struct
type convertResponse struct {
	Timestamp time.Time `json:"timestamp"`
	Duration  float64   `json:"duration"`
	ID        int       `json:"id"`
}

// get json of a convert response message
func jsonifyConvertResponse(timestamp time.Time, duration float64, id int) ([]byte, error) {
	js, err := json.Marshal(convertResponse{
		Timestamp: timestamp,
		Duration:  duration,
		ID:        id,
	})
	return js, err
}

func convertHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {

		// fire up convert script
		start := time.Now()
		convert := exec.Command("/bin/bash", convertBinPath)
		err := convert.Run()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		elapsed := time.Since(start)

		// return operation status
		js, err := jsonifyConvertResponse(start, elapsed.Seconds(), hits)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// increment the hits counter
		hits++

		// write response to the http buffer
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write(js)
	}
}

func pingHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "GET" {
		//return pong
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("pong\n"))
	}
}
