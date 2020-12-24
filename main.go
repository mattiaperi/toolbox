package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
)

func main() {
	// register hello function to handle all requests
	mux := http.NewServeMux()
	mux.HandleFunc("/", hello)

	// use PORT environment variable, or default to 8080
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// start the web server on port and accept requests
	log.Printf("Server listening on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, mux))
}

// hello responds to the request with a plain-text "Hello, world" message.
func hello(w http.ResponseWriter, r *http.Request) {
	log.Printf("Serving request: %s", r.URL.Path)
	host, _ := os.Hostname()
	fmt.Fprintf(w, "Hello, world!\n")
	fmt.Fprintf(w, "Version: 0.0.3\n")
	fmt.Fprintf(w, "Hostname: %s\n", host)
	fmt.Fprintf(w, "\n")
	fmt.Fprintf(w, "Environment variables:\n")
	for _, e := range os.Environ() {
		pair := strings.SplitN(e, "=", 2)
		//STOUT fmt.Println(pair[0], pair[1]) or fmt.Printf("%s: %s\n", pair[0], pair[1])
		fmt.Fprintf(w, "> %s: %s\n", pair[0], pair[1])
	}
	fmt.Fprintf(w, "\n")
	fmt.Fprintf(w, "HTTP request headers:\n")
	// Loop over header names
	for name, values := range r.Header {
		// Loop over all values for the name.
		for _, value := range values {
			//STDOUT fmt.Println(name, value)
			fmt.Fprintf(w, "> %s: %s\n", name, value)
		}
	}
}
