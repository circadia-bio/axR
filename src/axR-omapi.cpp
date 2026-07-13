// axR Rcpp wrapper around the vendored Open Movement OMAPI library.
//
// This file is thin by design: it translates between R-friendly types and
// OMAPI's C calling convention (int deviceId, out-parameters via pointers,
// negative-int error codes), and does not reimplement any device logic --
// that all lives in omapi/*.c, vendored unmodified from
// https://github.com/openmovementproject/libomapi (BSD 2-clause,
// Newcastle University). See omapi/LICENSE.TXT.
//
// Every wrapper here returns an Rcpp::List with a $status element (the raw
// OMAPI return code) plus any out-parameters; R-side .om_check() in
// R/omapi.R decides whether to raise an error, using OmErrorString() for
// the message. Business logic (validation, enum/string mapping, sentinel
// handling) lives in R -- this file just moves data across the boundary.

#include <Rcpp.h>
#include <fcntl.h>
#include "omapi/omapi.h"

// ---- Session lifecycle -----------------------------------------------

// [[Rcpp::export]]
int axR_omapi_startup_cpp() {
  return OmStartup(OM_VERSION);
}

// [[Rcpp::export]]
int axR_omapi_shutdown_cpp() {
  return OmShutdown();
}

// Diagnostic escape hatch: OMAPI logs internally via OmLog(), but axR's
// default log target is NULL (see omapi-main.c's axR patch) so that
// compiled code doesn't write to stderr unprompted -- see NEWS.md. This
// lets a caller opt back into stderr logging when actually debugging a
// device-detection problem. Note this only controls *where* logged lines
// go; *whether* anything is logged at all is controlled by OMAPI's debug
// level, which is set once from the OMDEBUG environment variable at
// OmStartup() time (i.e. before library(axR) is called) and can't be
// changed afterward.
// [[Rcpp::export]]
int axR_omapi_set_log_stream_cpp(int fd) {
  return OmSetLogStream(fd);
}

// File variant of the above, for when a raw fd 2 (stderr) write from a
// background pthread doesn't reliably reach the R console/terminal --
// this sidesteps that ambiguity entirely by writing to a plain file that
// can be read back with readLines() afterward. Uses low-level open() (not
// fopen()) so the fd handed to OmSetLogStream() isn't already wrapped in
// a FILE* we'd otherwise have to avoid double-closing.
// [[Rcpp::export]]
int axR_omapi_set_log_file_cpp(std::string path) {
  int fd = open(path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0644);
  if (fd < 0) return -1;
  return OmSetLogStream(fd);
}

// [[Rcpp::export]]
Rcpp::CharacterVector axR_omapi_error_string_cpp(int status) {
  return Rcpp::CharacterVector::create(OmErrorString(status));
}

// ---- Discovery ---------------------------------------------------------

// [[Rcpp::export]]
Rcpp::IntegerVector axR_omapi_get_device_ids_cpp() {
  int count = OmGetDeviceIds(NULL, 0);
  if (count <= 0) return Rcpp::IntegerVector(0);

  std::vector<int> ids(count);
  int actual = OmGetDeviceIds(ids.data(), count);
  if (actual < 0) Rcpp::stop("OmGetDeviceIds() failed: %s", OmErrorString(actual));
  ids.resize(actual);
  return Rcpp::wrap(ids);
}

// [[Rcpp::export]]
Rcpp::List axR_omapi_get_device_info_cpp(int deviceId) {
  char serialBuffer[OM_MAX_PATH] = {0};
  char portBuffer[OM_MAX_PATH]   = {0};
  char pathBuffer[OM_MAX_PATH]   = {0};
  int firmwareVersion = 0, hardwareVersion = 0;

  int statusSerial = OmGetDeviceSerial(deviceId, serialBuffer);
  int statusPort   = OmGetDevicePort(deviceId, portBuffer);
  int statusPath   = OmGetDevicePath(deviceId, pathBuffer);
  int statusVer    = OmGetVersion(deviceId, &firmwareVersion, &hardwareVersion);
  int batteryLevel = OmGetBatteryLevel(deviceId);

  // Report the first failure encountered, in call order; callers can still
  // use whichever fields did succeed.
  int status = OM_OK;
  if (statusSerial < 0) status = statusSerial;
  else if (statusPort < 0) status = statusPort;
  else if (statusPath < 0) status = statusPath;
  else if (statusVer < 0) status = statusVer;

  return Rcpp::List::create(
    Rcpp::Named("status") = status,
    Rcpp::Named("device_id") = deviceId,
    Rcpp::Named("serial") = std::string(serialBuffer),
    Rcpp::Named("port") = std::string(portBuffer),
    Rcpp::Named("path") = std::string(pathBuffer),
    Rcpp::Named("firmware_version") = firmwareVersion,
    Rcpp::Named("hardware_version") = hardwareVersion,
    Rcpp::Named("battery_level") = batteryLevel
  );
}

// ---- Device status -------------------------------------------------

// [[Rcpp::export]]
Rcpp::List axR_omapi_get_battery_cpp(int deviceId) {
  int level = OmGetBatteryLevel(deviceId);
  int health = OmGetBatteryHealth(deviceId);
  int status = (level < 0) ? level : (health < 0 ? health : OM_OK);
  return Rcpp::List::create(
    Rcpp::Named("status") = status,
    Rcpp::Named("level_pct") = level,
    Rcpp::Named("recharge_cycles") = health
  );
}

// [[Rcpp::export]]
Rcpp::List axR_omapi_self_test_cpp(int deviceId) {
  int result = OmSelfTest(deviceId);
  return Rcpp::List::create(
    Rcpp::Named("status") = (result < 0 ? result : OM_OK),
    Rcpp::Named("diagnostic_code") = result
  );
}

// [[Rcpp::export]]
Rcpp::List axR_omapi_get_memory_health_cpp(int deviceId) {
  int result = OmGetMemoryHealth(deviceId);
  return Rcpp::List::create(
    Rcpp::Named("status") = (result < 0 ? result : OM_OK),
    Rcpp::Named("spare_blocks") = result
  );
}

// [[Rcpp::export]]
Rcpp::List axR_omapi_get_accelerometer_cpp(int deviceId) {
  int x = 0, y = 0, z = 0;
  int status = OmGetAccelerometer(deviceId, &x, &y, &z);
  return Rcpp::List::create(
    Rcpp::Named("status") = status,
    Rcpp::Named("x") = x, Rcpp::Named("y") = y, Rcpp::Named("z") = z
  );
}

// Datetimes cross the boundary as broken-down Y/M/D/h/m/s components
// (decoded/encoded with OMAPI's own OM_DATETIME_* macros), not as the raw
// packed integer -- R builds a POSIXct from the components on one side,
// C++ never has to know about R's date representation on the other.

// [[Rcpp::export]]
Rcpp::List axR_omapi_get_time_cpp(int deviceId) {
  OM_DATETIME t = 0;
  int status = OmGetTime(deviceId, &t);
  return Rcpp::List::create(
    Rcpp::Named("status") = status,
    Rcpp::Named("year") = (int)OM_DATETIME_YEAR(t),
    Rcpp::Named("month") = (int)OM_DATETIME_MONTH(t),
    Rcpp::Named("day") = (int)OM_DATETIME_DAY(t),
    Rcpp::Named("hour") = (int)OM_DATETIME_HOURS(t),
    Rcpp::Named("min") = (int)OM_DATETIME_MINUTES(t),
    Rcpp::Named("sec") = (int)OM_DATETIME_SECONDS(t)
  );
}

// [[Rcpp::export]]
int axR_omapi_set_time_cpp(int deviceId, int year, int month, int day, int hour, int min, int sec) {
  OM_DATETIME t = OM_DATETIME_FROM_YMDHMS(year, month, day, hour, min, sec);
  return OmSetTime(deviceId, t);
}

// [[Rcpp::export]]
int axR_omapi_set_led_cpp(int deviceId, int ledState) {
  return OmSetLed(deviceId, (OM_LED_STATE)ledState);
}

// [[Rcpp::export]]
Rcpp::List axR_omapi_is_locked_cpp(int deviceId) {
  int hasLockCode = 0;
  int status = OmIsLocked(deviceId, &hasLockCode);
  return Rcpp::List::create(
    Rcpp::Named("status") = status,
    Rcpp::Named("locked") = (status == OM_TRUE),
    Rcpp::Named("has_lock_code") = (bool)hasLockCode
  );
}

// [[Rcpp::export]]
int axR_omapi_set_lock_cpp(int deviceId, int code) {
  return OmSetLock(deviceId, (unsigned short)code);
}

// [[Rcpp::export]]
int axR_omapi_unlock_cpp(int deviceId, int code) {
  return OmUnlock(deviceId, (unsigned short)code);
}

// [[Rcpp::export]]
int axR_omapi_get_ecc_cpp(int deviceId) {
  return OmGetEcc(deviceId);
}

// [[Rcpp::export]]
int axR_omapi_set_ecc_cpp(int deviceId, bool enabled) {
  return OmSetEcc(deviceId, enabled ? OM_TRUE : OM_FALSE);
}

// [[Rcpp::export]]
Rcpp::List axR_omapi_command_cpp(int deviceId, std::string command, std::string expected, int timeoutMs) {
  char buffer[256] = {0};  // matches OMAPI's internal OM_MAX_RESPONSE_SIZE, not exposed via the public header
  const char* expectedPtr = expected.empty() ? NULL : expected.c_str();
  int result = OmCommand(deviceId, command.c_str(), buffer, sizeof(buffer),
                          expectedPtr, (unsigned int)timeoutMs, NULL, 0);
  return Rcpp::List::create(
    Rcpp::Named("status") = OM_OK,   // OmCommand's return is an offset, not an error code -- see offset
    Rcpp::Named("offset") = result,
    Rcpp::Named("response") = std::string(buffer)
  );
}

// ---- Settings & metadata -------------------------------------------

// [[Rcpp::export]]
Rcpp::List axR_omapi_get_delays_cpp(int deviceId) {
  OM_DATETIME startTime = 0, stopTime = 0;
  int status = OmGetDelays(deviceId, &startTime, &stopTime);
  return Rcpp::List::create(
    Rcpp::Named("status") = status,
    Rcpp::Named("start_raw") = (double)startTime,
    Rcpp::Named("stop_raw") = (double)stopTime,
    Rcpp::Named("start_is_zero") = (startTime == OM_DATETIME_ZERO),
    Rcpp::Named("start_is_infinite") = (startTime == OM_DATETIME_INFINITE),
    Rcpp::Named("stop_is_zero") = (stopTime == OM_DATETIME_ZERO),
    Rcpp::Named("stop_is_infinite") = (stopTime == OM_DATETIME_INFINITE)
  );
}

// [[Rcpp::export]]
int axR_omapi_set_delays_cpp(int deviceId, bool startZero, bool startInfinite,
                              int startYear, int startMonth, int startDay,
                              int startHour, int startMin, int startSec,
                              bool stopZero, bool stopInfinite,
                              int stopYear, int stopMonth, int stopDay,
                              int stopHour, int stopMin, int stopSec) {
  OM_DATETIME startTime = startZero ? OM_DATETIME_ZERO :
    startInfinite ? OM_DATETIME_INFINITE :
    OM_DATETIME_FROM_YMDHMS(startYear, startMonth, startDay, startHour, startMin, startSec);
  OM_DATETIME stopTime = stopZero ? OM_DATETIME_ZERO :
    stopInfinite ? OM_DATETIME_INFINITE :
    OM_DATETIME_FROM_YMDHMS(stopYear, stopMonth, stopDay, stopHour, stopMin, stopSec);
  return OmSetDelays(deviceId, startTime, stopTime);
}

// [[Rcpp::export]]
Rcpp::List axR_omapi_get_session_id_cpp(int deviceId) {
  unsigned int sessionId = 0;
  int status = OmGetSessionId(deviceId, &sessionId);
  return Rcpp::List::create(
    Rcpp::Named("status") = status,
    Rcpp::Named("session_id") = (double)sessionId
  );
}

// [[Rcpp::export]]
int axR_omapi_set_session_id_cpp(int deviceId, double sessionId) {
  return OmSetSessionId(deviceId, (unsigned int)sessionId);
}

// [[Rcpp::export]]
Rcpp::List axR_omapi_get_metadata_cpp(int deviceId) {
  char buffer[OM_METADATA_SIZE + 1] = {0};
  int status = OmGetMetadata(deviceId, buffer);
  return Rcpp::List::create(
    Rcpp::Named("status") = status,
    Rcpp::Named("metadata") = std::string(buffer)
  );
}

// [[Rcpp::export]]
int axR_omapi_set_metadata_cpp(int deviceId, std::string metadata) {
  return OmSetMetadata(deviceId, metadata.c_str(), (int)metadata.size());
}

// [[Rcpp::export]]
Rcpp::List axR_omapi_get_accel_config_cpp(int deviceId) {
  int rate = 0, range = 0;
  int status = OmGetAccelConfig(deviceId, &rate, &range);
  return Rcpp::List::create(
    Rcpp::Named("status") = status,
    Rcpp::Named("rate") = rate,
    Rcpp::Named("range") = range
  );
}

// [[Rcpp::export]]
int axR_omapi_set_accel_config_cpp(int deviceId, int rate, int range) {
  return OmSetAccelConfig(deviceId, rate, range);
}

// [[Rcpp::export]]
int axR_omapi_erase_and_commit_cpp(int deviceId, int eraseLevel) {
  return OmEraseDataAndCommit(deviceId, (OM_ERASE_LEVEL)eraseLevel);
}

// ---- Data download ---------------------------------------------------

// [[Rcpp::export]]
Rcpp::List axR_omapi_get_data_info_cpp(int deviceId) {
  int size = OmGetDataFileSize(deviceId);
  char filenameBuffer[OM_MAX_PATH] = {0};
  int statusName = OmGetDataFilename(deviceId, filenameBuffer);

  int dataBlockSize = 0, dataOffsetBlocks = 0, dataNumBlocks = 0;
  OM_DATETIME startTime = 0, endTime = 0;
  int statusRange = OmGetDataRange(deviceId, &dataBlockSize, &dataOffsetBlocks,
                                    &dataNumBlocks, &startTime, &endTime);

  int status = (size < 0) ? size : (statusName < 0 ? statusName : statusRange);

  return Rcpp::List::create(
    Rcpp::Named("status") = status,
    Rcpp::Named("size_bytes") = size,
    Rcpp::Named("filename") = std::string(filenameBuffer),
    Rcpp::Named("block_size") = dataBlockSize,
    Rcpp::Named("offset_blocks") = dataOffsetBlocks,
    Rcpp::Named("num_blocks") = dataNumBlocks,
    Rcpp::Named("start_year") = (int)OM_DATETIME_YEAR(startTime),
    Rcpp::Named("start_month") = (int)OM_DATETIME_MONTH(startTime),
    Rcpp::Named("start_day") = (int)OM_DATETIME_DAY(startTime),
    Rcpp::Named("start_hour") = (int)OM_DATETIME_HOURS(startTime),
    Rcpp::Named("start_min") = (int)OM_DATETIME_MINUTES(startTime),
    Rcpp::Named("start_sec") = (int)OM_DATETIME_SECONDS(startTime),
    Rcpp::Named("end_year") = (int)OM_DATETIME_YEAR(endTime),
    Rcpp::Named("end_month") = (int)OM_DATETIME_MONTH(endTime),
    Rcpp::Named("end_day") = (int)OM_DATETIME_DAY(endTime),
    Rcpp::Named("end_hour") = (int)OM_DATETIME_HOURS(endTime),
    Rcpp::Named("end_min") = (int)OM_DATETIME_MINUTES(endTime),
    Rcpp::Named("end_sec") = (int)OM_DATETIME_SECONDS(endTime)
  );
}

// [[Rcpp::export]]
int axR_omapi_begin_downloading_cpp(int deviceId, int offsetBlocks, int lengthBlocks, std::string destFile) {
  return OmBeginDownloading(deviceId, offsetBlocks, lengthBlocks, destFile.c_str());
}

// [[Rcpp::export]]
Rcpp::List axR_omapi_query_download_cpp(int deviceId) {
  OM_DOWNLOAD_STATUS downloadStatus = OM_DOWNLOAD_NONE;
  int downloadValue = 0;
  int status = OmQueryDownload(deviceId, &downloadStatus, &downloadValue);
  return Rcpp::List::create(
    Rcpp::Named("status") = status,
    Rcpp::Named("download_status") = (int)downloadStatus,
    Rcpp::Named("value") = downloadValue
  );
}

// [[Rcpp::export]]
Rcpp::List axR_omapi_wait_download_cpp(int deviceId) {
  OM_DOWNLOAD_STATUS downloadStatus = OM_DOWNLOAD_NONE;
  int downloadValue = 0;
  int status = OmWaitForDownload(deviceId, &downloadStatus, &downloadValue);
  return Rcpp::List::create(
    Rcpp::Named("status") = status,
    Rcpp::Named("download_status") = (int)downloadStatus,
    Rcpp::Named("value") = downloadValue
  );
}

// [[Rcpp::export]]
int axR_omapi_cancel_download_cpp(int deviceId) {
  return OmCancelDownload(deviceId);
}
