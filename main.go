package main

import (
	"encoding/json"
	"flag"
	"log"
	"net/http"
)

type Response struct {
	Message string `json:"message"`
	Version string `json:"version"`
}

func main() {
	// Parse command line flags
	certFile := flag.String("cert", "server.crt", "Path to the TLS certificate file")
	keyFile := flag.String("key", "server.key", "Path to the TLS key file")
	port := flag.String("port", "443", "Port to listen on")
	flag.Parse()

	// Create a simple handler that returns JSON
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		response := Response{
			Message: "Hello from TLS server",
			Version: "1.0",
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	})

	// Start the server with TLS
	log.Printf("Starting server on :%s", *port)
	log.Fatal(http.ListenAndServeTLS(":"+*port, *certFile, *keyFile, nil))
}
