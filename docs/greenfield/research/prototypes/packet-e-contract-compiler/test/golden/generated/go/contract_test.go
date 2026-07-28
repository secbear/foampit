package contract

import (
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestSharedOutcomeFixtures(t *testing.T) {
	directory := os.Getenv("PACKET_E_OUTCOME_FIXTURES")
	if directory == "" {
		t.Fatal("PACKET_E_OUTCOME_FIXTURES is required")
	}
	fixtures := []string{
		"start-sandbox-valid.json",
		"start-sandbox-invalid.json",
		"cancel-operation-valid.json",
		"cancel-operation-invalid.json",
		"write-process-input-valid.json",
		"write-process-input-invalid.json",
		"wait-operation-valid.json",
		"wait-operation-invalid.json",
	}
	for _, fixture := range fixtures {
		fixture := fixture
		t.Run(fixture, func(t *testing.T) {
			data, err := os.ReadFile(filepath.Join(directory, fixture))
			if err != nil {
				t.Fatal(err)
			}
			_, err = DecodeOutcome(data)
			if strings.Contains(fixture, "-valid.") {
				if err != nil {
					t.Fatalf("valid fixture rejected: %v", err)
				}
				return
			}
			var diagnostic *ContractDiagnostic
			if !errors.As(err, &diagnostic) || diagnostic.Category != InvalidOutcome {
				t.Fatalf("invalid fixture diagnostic = %v", err)
			}
		})
	}
}
