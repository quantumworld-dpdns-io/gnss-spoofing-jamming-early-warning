package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gorilla/mux"
)

func setupRouter() *mux.Router {
	router := mux.NewRouter()
	api := router.PathPrefix("/v1").Subrouter()
	api.HandleFunc("/health", healthHandler).Methods("GET")
	api.HandleFunc("/detect", detectHandler).Methods("POST")
	api.HandleFunc("/heatmap", heatmapHandler).Methods("GET")
	api.HandleFunc("/alerts", alertsHandler).Methods("GET")
	api.HandleFunc("/sensors", sensorsHandler).Methods("GET")
	return router
}

func TestHealthEndpoint(t *testing.T) {
	router := setupRouter()
	req := httptest.NewRequest("GET", "/v1/health", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}

	var result map[string]interface{}
	if err := json.NewDecoder(rec.Body).Decode(&result); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if result["status"] != "ok" {
		t.Errorf("expected status 'ok', got '%v'", result["status"])
	}
}

func TestDetectEndpoint(t *testing.T) {
	router := setupRouter()
	req := httptest.NewRequest("POST", "/v1/detect", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}

	var result map[string]interface{}
	if err := json.NewDecoder(rec.Body).Decode(&result); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if _, ok := result["is_spoofed"]; !ok {
		t.Error("response missing 'is_spoofed' field")
	}
}

func TestHeatmapEndpoint(t *testing.T) {
	router := setupRouter()
	req := httptest.NewRequest("GET", "/v1/heatmap?lat=25.0330&lon=121.5654", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}
}

func TestAlertsEndpoint(t *testing.T) {
	router := setupRouter()
	req := httptest.NewRequest("GET", "/v1/alerts", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}
}

func TestSensorsEndpoint(t *testing.T) {
	router := setupRouter()
	req := httptest.NewRequest("GET", "/v1/sensors", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}
}

func TestNotFound(t *testing.T) {
	router := setupRouter()
	req := httptest.NewRequest("GET", "/v1/nonexistent", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", rec.Code)
	}
}
