// netstat -n -p tcp | grep 54.202.118.199.80 | perl -ne '@a=split; $b{$a[5]}+=1; END{ for $ii (keys(%b)) { print"$ii $b{$ii}\n"}}'

package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net"

	// "math/rand"
	"net/http"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/cloudwatch"
	"github.com/prozz/aws-embedded-metrics-golang/emf"
	"golang.org/x/sys/unix"
)

type runResult struct {
	id            int
	success       bool
	statusCode    int
	bytesReceived int
	startTime     time.Time
	endTime       time.Time
	duration      time.Duration
}

func runner(client *http.Client, id int, targetUrl string, retData chan<- runResult) {
	startTime := time.Now()
	// fmt.Printf("Run %d\n", id)
	resp, err := client.Get(targetUrl)
	if err != nil {
		// log.Println(err)
		// retData <- fmt.Sprintf("%d failed to open - %s", id, err)
		// duration := time.Since(startTime)
		endTime := time.Now()
		duration := endTime.Sub(startTime)
		retData <- runResult{
			id:            id,
			success:       false,
			statusCode:    -2,
			bytesReceived: 0,
			startTime:     startTime,
			endTime:       endTime,
			duration:      duration,
		}
		return
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		// log.Println(err)
		// retData <- fmt.Sprintf("%d failed to read - %s", id, err)
		// duration := time.Since(startTime)
		endTime := time.Now()
		duration := endTime.Sub(startTime)
		retData <- runResult{
			id:            id,
			success:       false,
			statusCode:    -1,
			bytesReceived: 0,
			startTime:     startTime,
			endTime:       endTime,
			duration:      duration,
		}
		return
	}
	bytesReceived := len(body)
	// retData <- fmt.Sprintf("%d succeeded - %d status / %d bytes received", id, resp.StatusCode, bytesReceived)
	// duration := time.Since(startTime)
	endTime := time.Now()
	duration := endTime.Sub(startTime)
	retData <- runResult{
		id:            id,
		success:       true,
		statusCode:    resp.StatusCode,
		bytesReceived: bytesReceived,
		startTime:     startTime,
		endTime:       endTime,
		duration:      duration,
	}

}

func launcher(client *http.Client, id int, targetUrl string, numthreads int) {

	ticker := time.NewTicker(1000 * time.Millisecond)
	defer ticker.Stop()

	retChan := make(chan runResult, numthreads)
	for ii := 0; ii < numthreads; ii++ {
		// fmt.Printf("Launch %d\n", ii)
		go runner(client, ii, targetUrl, retChan)
	}

	jj := 0
	// for ii := 0; ii < numthreads; ii++ {
	// 	res := <-retChan
	for jj < numthreads {
		var res_err_connect float64 = 0
		var res_err_read float64 = 0
		var res_2xx float64 = 0
		var res_4xx float64 = 0
		var res_5xx float64 = 0
		var res_success float64 = 0
		var res_duration_min time.Duration = 10 * time.Minute
		var res_duration_max time.Duration = 0 * time.Microsecond
		var res_duration_sum time.Duration = 0 * time.Microsecond

		var runStart int = jj
	launcherLoop:
		for jj < numthreads {
			select {
			case res := <-retChan:
				jj++
				// fmt.Printf("Collect %04d/%04d - success:%v code:%v duration:%v start:%v end:%v\n", id, res.id, res.success, res.statusCode, res.duration, res.startTime, res.endTime)
				if res.statusCode == -2 {
					res_err_connect++
				}
				if res.statusCode == -1 {
					res_err_read++
				}
				if (res.statusCode >= 200) && (res.statusCode < 300) {
					res_2xx++
				}
				if (res.statusCode >= 400) && (res.statusCode < 500) {
					res_4xx++
				}
				if (res.statusCode >= 500) && (res.statusCode < 600) {
					res_5xx++
				}
				if res.success {
					res_success++
				}
				if res.duration > res_duration_max {
					res_duration_max = res.duration
				}
				if res.duration < res_duration_min {
					res_duration_min = res.duration
				}
				res_duration_sum += res.duration
			case tt := <-ticker.C:
				// fmt.Printf("Ticker id:%d value:%v\n", id, tt)
				_ = tt
				if jj-runStart > 0 {
					break launcherLoop
				}
			}
		}
		var runCount float64 = float64(jj - runStart)
		// fmt.Printf(
		// 	"Percentages: success:%v 2xx:%v 4xx:%v 5xx:%v fail_connect:%v fail_read:%v\n",
		// 	res_success*100/runCount,
		// 	res_2xx*100/runCount,
		// 	res_4xx*100/runCount,
		// 	res_5xx*100/runCount,
		// 	res_err_connect*100/runCount,
		// 	res_err_read*100/runCount,
		// )
		// fmt.Printf(
		// 	"Durations: duration_min:%v duration_avg:%v duration_max:%v\n",
		// 	res_duration_min,
		// 	res_duration_sum/time.Duration(runCount),
		// 	res_duration_max,
		// )
		if data_log {
			logLine := emf.New().Namespace("goad")
			logLine.MetricAs("_invocation_id", id, emf.Count)
			logLine.MetricAs("_invocations", int(runCount), emf.Count)
			logLine.MetricFloatAs("success", (100.0*res_success)/runCount, emf.Percent)
			logLine.MetricFloatAs("status_2xx", (100.0*res_2xx)/runCount, emf.Percent)
			logLine.MetricFloatAs("status_4xx", (100.0*res_4xx)/runCount, emf.Percent)
			logLine.MetricFloatAs("status_5xx", (100.0*res_5xx)/runCount, emf.Percent)
			logLine.MetricFloatAs("error_connect", (100.0*res_err_connect)/runCount, emf.Percent)
			logLine.MetricFloatAs("error_read", (100.0*res_err_read)/runCount, emf.Percent)
			logLine.MetricFloatAs("duration_min", float64(res_duration_min.Milliseconds()), emf.Milliseconds)
			logLine.MetricFloatAs("duration_avg", float64((res_duration_sum / time.Duration(runCount)).Milliseconds()), emf.Milliseconds)
			logLine.MetricFloatAs("duration_max", float64(res_duration_max.Milliseconds()), emf.Milliseconds)
			logLine.Log()
		}
		// Based on https://github.com/awsdocs/aws-doc-sdk-examples/blob/master/go/example_code/cloudwatch/custom_metrics.go
		if data_put && (svc_cw != nil) {
			timeStamp := time.Now()
			_, err := svc_cw.PutMetricData(&cloudwatch.PutMetricDataInput{
				Namespace: aws.String("goad"),
				MetricData: []*cloudwatch.MetricDatum{

					&cloudwatch.MetricDatum{
						MetricName:        aws.String("_invocation_id"),
						Unit:              aws.String("Count"),
						Value:             aws.Float64(runCount),
						StorageResolution: aws.Int64(int64(1)),
						Timestamp:         aws.Time(timeStamp),
						Dimensions: []*cloudwatch.Dimension{
							&cloudwatch.Dimension{
								Name:  aws.String("SiteName"),
								Value: aws.String(targetUrl),
							},
						},
					},
					&cloudwatch.MetricDatum{
						MetricName:        aws.String("_invocations"),
						Unit:              aws.String("Count"),
						Value:             aws.Float64(float64(id)),
						StorageResolution: aws.Int64(1),
						Timestamp:         aws.Time(timeStamp),
						Dimensions: []*cloudwatch.Dimension{
							&cloudwatch.Dimension{
								Name:  aws.String("SiteName"),
								Value: aws.String(targetUrl),
							},
						},
					},
					&cloudwatch.MetricDatum{
						MetricName:        aws.String("success"),
						Unit:              aws.String("Percent"),
						Value:             aws.Float64((100.0 * res_success) / runCount),
						StorageResolution: aws.Int64(1),
						Timestamp:         aws.Time(timeStamp),
						Dimensions: []*cloudwatch.Dimension{
							&cloudwatch.Dimension{
								Name:  aws.String("SiteName"),
								Value: aws.String(targetUrl),
							},
						},
					},
					&cloudwatch.MetricDatum{
						MetricName:        aws.String("status_2xx"),
						Unit:              aws.String("Percent"),
						Value:             aws.Float64((100.0 * res_2xx) / runCount),
						StorageResolution: aws.Int64(1),
						Timestamp:         aws.Time(timeStamp),
						Dimensions: []*cloudwatch.Dimension{
							&cloudwatch.Dimension{
								Name:  aws.String("SiteName"),
								Value: aws.String(targetUrl),
							},
						},
					},
					&cloudwatch.MetricDatum{
						MetricName:        aws.String("status_4xx"),
						Unit:              aws.String("Percent"),
						Value:             aws.Float64((100.0 * res_4xx) / runCount),
						StorageResolution: aws.Int64(1),
						Timestamp:         aws.Time(timeStamp),
						Dimensions: []*cloudwatch.Dimension{
							&cloudwatch.Dimension{
								Name:  aws.String("SiteName"),
								Value: aws.String(targetUrl),
							},
						},
					},
					&cloudwatch.MetricDatum{
						MetricName:        aws.String("status_5xx"),
						Unit:              aws.String("Percent"),
						Value:             aws.Float64((100.0 * res_5xx) / runCount),
						StorageResolution: aws.Int64(1),
						Timestamp:         aws.Time(timeStamp),
						Dimensions: []*cloudwatch.Dimension{
							&cloudwatch.Dimension{
								Name:  aws.String("SiteName"),
								Value: aws.String(targetUrl),
							},
						},
					},
					&cloudwatch.MetricDatum{
						MetricName:        aws.String("error_connect"),
						Unit:              aws.String("Percent"),
						Value:             aws.Float64((100.0 * res_err_connect) / runCount),
						StorageResolution: aws.Int64(1),
						Timestamp:         aws.Time(timeStamp),
						Dimensions: []*cloudwatch.Dimension{
							&cloudwatch.Dimension{
								Name:  aws.String("SiteName"),
								Value: aws.String(targetUrl),
							},
						},
					},
					&cloudwatch.MetricDatum{
						MetricName:        aws.String("error_read"),
						Unit:              aws.String("Percent"),
						Value:             aws.Float64((100.0 * res_err_read) / runCount),
						StorageResolution: aws.Int64(1),
						Timestamp:         aws.Time(timeStamp),
						Dimensions: []*cloudwatch.Dimension{
							&cloudwatch.Dimension{
								Name:  aws.String("SiteName"),
								Value: aws.String(targetUrl),
							},
						},
					},
					&cloudwatch.MetricDatum{
						MetricName:        aws.String("duration_min"),
						Unit:              aws.String("Milliseconds"),
						Value:             aws.Float64(float64(res_duration_min.Milliseconds())),
						StorageResolution: aws.Int64(1),
						Timestamp:         aws.Time(timeStamp),
						Dimensions: []*cloudwatch.Dimension{
							&cloudwatch.Dimension{
								Name:  aws.String("SiteName"),
								Value: aws.String(targetUrl),
							},
						},
					},
					&cloudwatch.MetricDatum{
						MetricName:        aws.String("duration_avg"),
						Unit:              aws.String("Milliseconds"),
						Value:             aws.Float64(float64((res_duration_sum / time.Duration(runCount)).Milliseconds())),
						StorageResolution: aws.Int64(1),
						Timestamp:         aws.Time(timeStamp),
						Dimensions: []*cloudwatch.Dimension{
							&cloudwatch.Dimension{
								Name:  aws.String("SiteName"),
								Value: aws.String(targetUrl),
							},
						},
					},
					&cloudwatch.MetricDatum{
						MetricName:        aws.String("duration_max"),
						Unit:              aws.String("Milliseconds"),
						Value:             aws.Float64(float64(res_duration_max.Milliseconds())),
						StorageResolution: aws.Int64(1),
						Timestamp:         aws.Time(timeStamp),
						Dimensions: []*cloudwatch.Dimension{
							&cloudwatch.Dimension{
								Name:  aws.String("SiteName"),
								Value: aws.String(targetUrl),
							},
						},
					},
				},
			})
			if err != nil {
				fmt.Println("Error adding metrics:", err.Error())
				return
			} else {
				fmt.Println("Called PutMetrics")
			}
		}
	}
}

// type controlData struct {
// 	ConnectionTargetUrl           string
// 	ExperimentDurationSeconds     int
// 	ConnectionsPerSecond          int
// 	ReportingMilliseconds         int
// 	ConnectionTimeoutMilliseconds int
// 	TlsTimeoutMilliseconds        int
// 	TotalTimeoutMilliseconds      int
// }

func rlimitValidator(desired int) {
	var rLimitActual unix.Rlimit
	err := unix.Getrlimit(unix.RLIMIT_NOFILE, &rLimitActual)
	if err != nil {
		fmt.Println("Error getting Rlimit", err)
	}
	fmt.Printf("Rlimit before: %v\n", rLimitActual)

	var rLimitDesired unix.Rlimit
	rLimitDesired.Max = 65535
	rLimitDesired.Cur = 65535

	err = unix.Setrlimit(unix.RLIMIT_NOFILE, &rLimitDesired)
	if err != nil {
		fmt.Println("Error Setting Rlimit ", err)
	}

	err = unix.Getrlimit(unix.RLIMIT_NOFILE, &rLimitActual)
	if err != nil {
		fmt.Println("Error getting Rlimit", err)
	}
	fmt.Printf("Rlimit after: %v\n", rLimitActual)

	if rLimitActual.Cur < uint64(desired) {
		log.Printf("WARNING: max open files %d < desired concurrent connections %d", rLimitActual.Cur, desired)
	}
}

func loadgen(control controlData) {
	timeStart := time.Now()
	rlimitValidator(control.ConnectionsPerSecond)
	netTransport := &http.Transport{
		Dial: (&net.Dialer{
			Timeout: time.Duration(control.ConnectionTimeoutMilliseconds) * time.Millisecond,
		}).Dial,
		TLSHandshakeTimeout: time.Duration(control.TlsTimeoutMilliseconds) * time.Millisecond,
		MaxIdleConns:        control.ConnectionsPerSecond,
		MaxConnsPerHost:     control.ConnectionsPerSecond,
		MaxIdleConnsPerHost: control.ConnectionsPerSecond,
	}
	netClient := &http.Client{
		Timeout:   time.Duration(control.TotalTimeoutMilliseconds) * time.Millisecond,
		Transport: netTransport,
	}
	for ii := 0; ii < control.ExperimentDurationSeconds; ii++ {
		go launcher(netClient, ii, control.ConnectionTargetUrl, control.ConnectionsPerSecond)
		time.Sleep(time.Duration(control.ReportingMilliseconds) * time.Millisecond)
	}
	fmt.Printf("LoadGen ran for %s\n", time.Since(timeStart))
	// time.Sleep(1 * time.Second)
	fmt.Println("That's all for now!")
}
