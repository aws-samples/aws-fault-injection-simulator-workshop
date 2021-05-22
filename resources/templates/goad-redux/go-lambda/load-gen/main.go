package main

import (
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/cloudwatch"
)

var data_log bool = true
var data_put bool = false

var svc_cw *cloudwatch.CloudWatch

type controlData struct {
	ConnectionTargetUrl           string
	ExperimentDurationSeconds     int
	ConnectionsPerSecond          int
	ReportingMilliseconds         int
	ConnectionTimeoutMilliseconds int
	TlsTimeoutMilliseconds        int
	TotalTimeoutMilliseconds      int
}

func handler(control controlData) {
	// fmt.Printf("Event: %v\n", control)

	// Parameter validation and setting defaults
	if control.ConnectionTargetUrl == "" {
		log.Fatal("Must provide at least ConnectionTargetUrl in calling paramweters!")
		return
	}
	if control.ExperimentDurationSeconds == 0 {
		control.ExperimentDurationSeconds = 5
	}
	if control.ConnectionsPerSecond == 0 {
		control.ConnectionsPerSecond = 1000
	}
	if control.ReportingMilliseconds == 0 {
		control.ReportingMilliseconds = 1000
	}
	if control.ConnectionTimeoutMilliseconds == 0 {
		control.ConnectionTimeoutMilliseconds = 2000
	}
	if control.TlsTimeoutMilliseconds == 0 {
		control.TlsTimeoutMilliseconds = 2000
	}
	if control.TotalTimeoutMilliseconds == 0 {
		control.TotalTimeoutMilliseconds = 2000
	}

	fmt.Printf("Fixed Event: %+v\n", control)
	fmt.Printf("Output 1s data (namespace: goad): %v\n", data_put)
	fmt.Printf("Output 1m data (lambda logs EMF): %v\n", data_log)

	loadgen(control)
}

func main() {
	// Init stuffs
	switch os.Getenv("USE_PUT_METRICS") {
	case "true", "1":
		data_put = true
	case "false", "0":
		data_put = false
	}
	switch os.Getenv("USE_LOG_METRICS") {
	case "true", "1":
		data_log = true
	case "false", "0":
		data_log = false
	}

	if data_put {
		// Initialize a session that the SDK uses to load
		// credentials from the shared credentials file ~/.aws/credentials
		// and configuration from the shared configuration file ~/.aws/config.
		sess := session.Must(session.NewSessionWithOptions(session.Options{
			SharedConfigState: session.SharedConfigEnable,
		}))

		// Create new cloudwatch client.
		svc_cw = cloudwatch.New(sess)
	}

	// Handler loop
	lambda.Start(handler)
	// // for local testing
	// handler(controlData{ConnectionTargetUrl: "http://34.218.235.51/phpinfo/"})
}
