// Serial (CDC/COM port) I/O scaffold for Axivity devices.
//
// This file establishes the POSIX / Windows split used elsewhere in the
// Circadia Lab ecosystem (see dynR's Makevars pattern), but the actual
// open/write/read/close logic is not yet implemented. Protocol details
// (baud rate, timeouts, line-ending convention, device VID/PID matching)
// are a design decision pending review -- see R/serial.R for the
// user-facing function signatures this will eventually back.

#include <Rcpp.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <termios.h>
#include <fcntl.h>
#include <unistd.h>
#endif

// [[Rcpp::export]]
Rcpp::List axR_serial_open_cpp(std::string port, int baud) {
  Rcpp::stop("axR_serial_open_cpp() is not yet implemented.");
}

// [[Rcpp::export]]
void axR_serial_close_cpp(SEXP handle) {
  Rcpp::stop("axR_serial_close_cpp() is not yet implemented.");
}

// [[Rcpp::export]]
std::string axR_serial_write_cmd_cpp(SEXP handle, std::string command) {
  Rcpp::stop("axR_serial_write_cmd_cpp() is not yet implemented.");
}
