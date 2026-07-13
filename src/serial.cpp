// Serial (CDC/COM port) I/O for Axivity AX3/AX6 devices.
//
// Commands and responses follow the documented Open Movement serial
// protocol: plain 7-bit ASCII, CR/LF ("\r\n") terminated. See
// https://github.com/openmovementproject/openmovement/blob/master/Docs/ax3/ax3-technical.md
//
// This file only speaks the wire protocol -- it knows nothing about .cwa
// file contents. That's left to downstream packages (mrpheus, zeitR).

#include <Rcpp.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <termios.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/select.h>
#include <cerrno>
#include <cstring>
#endif

#include <string>

// A serial handle wraps either a POSIX file descriptor or a Windows HANDLE.
// The destructor closes the underlying descriptor exactly once: either when
// axR_serial_close_cpp() is called explicitly (which invalidates the
// descriptor), or -- if the R object is dropped without an explicit close --
// when the XPtr's default finalizer runs `delete` on garbage collection.
struct SerialHandle {
#ifdef _WIN32
  HANDLE h = INVALID_HANDLE_VALUE;
#else
  int fd = -1;
#endif

  ~SerialHandle() {
#ifdef _WIN32
    if (h != INVALID_HANDLE_VALUE) CloseHandle(h);
#else
    if (fd >= 0) close(fd);
#endif
  }
};

#ifndef _WIN32
static speed_t baud_to_speed(int baud) {
  switch (baud) {
    case 9600:   return B9600;
    case 19200:  return B19200;
    case 38400:  return B38400;
    case 57600:  return B57600;
    case 115200: return B115200;
    case 230400: return B230400;
    default:     return B115200;
  }
}

// Block until the fd is readable or timeout_ms elapses. Returns true if
// data is available to read.
static bool wait_readable(int fd, int timeout_ms) {
  fd_set set;
  FD_ZERO(&set);
  FD_SET(fd, &set);
  struct timeval tv;
  tv.tv_sec  = timeout_ms / 1000;
  tv.tv_usec = (timeout_ms % 1000) * 1000;
  int rv = select(fd + 1, &set, NULL, NULL, &tv);
  return rv > 0;
}
#endif

// [[Rcpp::export]]
SEXP axR_serial_open_cpp(std::string port, int baud) {
#ifdef _WIN32
  // COM10 and above require the \\.\ prefix; harmless for COM1-9 too.
  std::string full_path = "\\\\.\\" + port;
  HANDLE h = CreateFileA(full_path.c_str(), GENERIC_READ | GENERIC_WRITE,
                         0, NULL, OPEN_EXISTING, 0, NULL);
  if (h == INVALID_HANDLE_VALUE) {
    Rcpp::stop("Could not open serial port '%s' (Windows error %lu).",
               port.c_str(), GetLastError());
  }

  DCB dcb;
  SecureZeroMemory(&dcb, sizeof(DCB));
  dcb.DCBlength = sizeof(DCB);
  if (!GetCommState(h, &dcb)) {
    CloseHandle(h);
    Rcpp::stop("GetCommState() failed for port '%s'.", port.c_str());
  }
  dcb.BaudRate     = static_cast<DWORD>(baud);
  dcb.ByteSize     = 8;
  dcb.Parity       = NOPARITY;
  dcb.StopBits     = ONESTOPBIT;
  dcb.fBinary      = TRUE;
  dcb.fParity      = FALSE;
  dcb.fOutxCtsFlow = FALSE;
  dcb.fOutxDsrFlow = FALSE;
  dcb.fDtrControl  = DTR_CONTROL_ENABLE;
  dcb.fRtsControl  = RTS_CONTROL_ENABLE;
  if (!SetCommState(h, &dcb)) {
    CloseHandle(h);
    Rcpp::stop("SetCommState() failed for port '%s'.", port.c_str());
  }

  COMMTIMEOUTS timeouts;
  SecureZeroMemory(&timeouts, sizeof(COMMTIMEOUTS));
  timeouts.ReadIntervalTimeout         = 50;
  timeouts.ReadTotalTimeoutConstant    = 2000;
  timeouts.ReadTotalTimeoutMultiplier  = 10;
  timeouts.WriteTotalTimeoutConstant   = 2000;
  timeouts.WriteTotalTimeoutMultiplier = 10;
  if (!SetCommTimeouts(h, &timeouts)) {
    CloseHandle(h);
    Rcpp::stop("SetCommTimeouts() failed for port '%s'.", port.c_str());
  }

  SerialHandle* handle = new SerialHandle();
  handle->h = h;
  Rcpp::XPtr<SerialHandle> xptr(handle, true);
  xptr.attr("class") = "axR_serial_xptr";
  return xptr;

#else
  int fd = open(port.c_str(), O_RDWR | O_NOCTTY | O_NONBLOCK);
  if (fd < 0) {
    Rcpp::stop("Could not open serial port '%s': %s", port.c_str(), strerror(errno));
  }

  struct termios tty;
  if (tcgetattr(fd, &tty) != 0) {
    close(fd);
    Rcpp::stop("tcgetattr() failed for port '%s': %s", port.c_str(), strerror(errno));
  }

  speed_t speed = baud_to_speed(baud);
  cfsetispeed(&tty, speed);
  cfsetospeed(&tty, speed);

  tty.c_cflag |= (CLOCAL | CREAD);
  tty.c_cflag &= ~PARENB;
  tty.c_cflag &= ~CSTOPB;
  tty.c_cflag &= ~CSIZE;
  tty.c_cflag |= CS8;
  tty.c_cflag &= ~CRTSCTS;

  // Raw mode: no line editing, no signal chars, no CR/LF translation --
  // the protocol's own \r\n terminators must pass through untouched.
  tty.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
  tty.c_iflag &= ~(IXON | IXOFF | IXANY);
  tty.c_iflag &= ~(ICRNL | INLCR);
  tty.c_oflag &= ~OPOST;

  tty.c_cc[VMIN]  = 0;
  tty.c_cc[VTIME] = 0;  // timeouts are handled by wait_readable()/select(), not termios

  if (tcsetattr(fd, TCSANOW, &tty) != 0) {
    close(fd);
    Rcpp::stop("tcsetattr() failed for port '%s': %s", port.c_str(), strerror(errno));
  }

  // Drop O_NONBLOCK now that the port is configured: reads/writes below
  // block up to the select()-based timeout instead of returning EAGAIN.
  int flags = fcntl(fd, F_GETFL, 0);
  fcntl(fd, F_SETFL, flags & ~O_NONBLOCK);

  SerialHandle* handle = new SerialHandle();
  handle->fd = fd;
  Rcpp::XPtr<SerialHandle> xptr(handle, true);
  xptr.attr("class") = "axR_serial_xptr";
  return xptr;
#endif
}

// [[Rcpp::export]]
void axR_serial_close_cpp(SEXP handle) {
  Rcpp::XPtr<SerialHandle> xptr(handle);
#ifdef _WIN32
  if (xptr->h != INVALID_HANDLE_VALUE) {
    CloseHandle(xptr->h);
    xptr->h = INVALID_HANDLE_VALUE;
  }
#else
  if (xptr->fd >= 0) {
    close(xptr->fd);
    xptr->fd = -1;
  }
#endif
}

// Sends `command` + "\r\n" and reads until the first "\r\n" in the
// response or timeout_ms elapses, whichever comes first. Axivity command
// responses are documented as single-line, so this is sufficient for
// ID / TIME / SESSION / HIBERNATE / STOP / RATE / FORMAT; STREAM's
// multi-line preview output is intentionally out of scope here.
// [[Rcpp::export]]
std::string axR_serial_write_cmd_cpp(SEXP handle, std::string command, int timeout_ms) {
  Rcpp::XPtr<SerialHandle> xptr(handle);
  std::string line = command + "\r\n";

#ifdef _WIN32
  HANDLE h = xptr->h;
  DWORD written = 0;
  if (!WriteFile(h, line.c_str(), (DWORD)line.size(), &written, NULL) ||
      written != line.size()) {
    Rcpp::stop("Failed to write command '%s' to device.", command.c_str());
  }

  // COMMTIMEOUTS set at open() time bounds each ReadFile call; timeout_ms
  // is accepted for interface parity with the POSIX path but the per-call
  // timeout here is fixed at open time.
  (void)timeout_ms;

  std::string response;
  char buf[256];
  DWORD read_bytes = 0;
  while (true) {
    if (!ReadFile(h, buf, sizeof(buf), &read_bytes, NULL)) {
      Rcpp::stop("Failed to read response to command '%s'.", command.c_str());
    }
    if (read_bytes == 0) break;
    response.append(buf, read_bytes);
    if (response.find("\r\n") != std::string::npos) break;
  }
  return response;

#else
  int fd = xptr->fd;
  ssize_t n = write(fd, line.c_str(), line.size());
  if (n < 0 || static_cast<size_t>(n) != line.size()) {
    Rcpp::stop("Failed to write command '%s' to device: %s", command.c_str(), strerror(errno));
  }

  std::string response;
  char buf[256];
  while (wait_readable(fd, timeout_ms)) {
    ssize_t r = read(fd, buf, sizeof(buf));
    if (r <= 0) break;
    response.append(buf, r);
    if (response.find("\r\n") != std::string::npos) break;
  }
  return response;
#endif
}
