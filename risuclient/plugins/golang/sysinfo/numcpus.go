// Author: Pablo Iranzo Gómez (Pablo.Iranzo@gmail.com)
// Header for risu metadata
// long_name: Report detected number of CPU's
// description: List the processors detected in the system
// priority: 200

package main

import (
	"bufio"
	"io"
	"os"
	"runtime"
	"strconv"
	"strings"
)

func main() {
	var OKAY, _ = strconv.Atoi(os.Getenv("RC_OKAY"))
	var SKIP, _ = strconv.Atoi(os.Getenv("RC_SKIPPED"))
	var INFO, _ = strconv.Atoi(os.Getenv("RC_INFO"))
	var RISU_ROOT = os.Getenv("RISU_ROOT")
	var RISU_LIVE, _ = strconv.Atoi(os.Getenv("RISU_LIVE"))
	var FAILED, _ = strconv.Atoi(os.Getenv("RC_FAILED"))
	if RISU_LIVE == 1 {
		// Report # of CPU's
		var CPUS = runtime.NumCPU()
		os.Stderr.WriteString(strconv.Itoa(CPUS))
		os.Exit(INFO)
	} else if RISU_LIVE == 0 {
		file, err := os.Open(RISU_ROOT + "/proc/cpuinfo")
		if err != nil {
			os.Stderr.WriteString("Failure to open required file " + RISU_ROOT + "/proc/cpuinfo")
			os.Exit(SKIP)
		}
		defer file.Close()
		counts := wordCount(file)
		os.Stderr.WriteString(strconv.Itoa(counts["processor"]))
		os.Exit(INFO)
	} else {
		os.Stderr.WriteString("Undefined RISU_LIVE status")
		os.Exit(FAILED)
	}
	// Failback case, exiting as OK
	os.Exit(OKAY)
}

// https://forgetcode.com/go/2348-count-the-number-of-word-occurrence-in-given-a-file
func wordCount(rdr io.Reader) map[string]int {
	counts := map[string]int{}
	scanner := bufio.NewScanner(rdr)
	scanner.Split(bufio.ScanWords)
	for scanner.Scan() {
		word := scanner.Text()
		word = strings.ToLower(word)
		counts[word]++
	}
	return counts
}
