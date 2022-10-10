package gcsv

import "core:encoding/csv"
import "core:fmt"
import "core:io"
import "core:math"
import "core:os"
import "core:strconv"
import "game:gstring"
import "game:gstrconv"

CsvTableData :: struct($T: typeid) {
  data: map[string][dynamic]T,
}

@(require_results)
makeCsvTableData :: proc($T: typeid) -> CsvTableData(T) {
  out := CsvTableData(T){}
  out.data = make(map[string][dynamic]T)
  return out
}

deleteCsvTableData :: proc(table: ^CsvTableData($T)) {
  if table == nil {
    return
  }
  for k, v in table.data {
    delete(v)
  }
  delete(table.data)
  table.data = nil
}

getNumRows :: proc(table: ^CsvTableData($T)) -> int {
  for k, v in table.data {
    return len(v)
  }
  return 0
}

/////////////////////////////////////

@(require_results)
convertTable :: proc(table: ^CsvTableData($T), converter: $P/proc(_: T) -> ($S, bool), default: S) -> CsvTableData(S) {
  out := makeCsvTableData(S)
  for header, column in table.data {
    out.data[header] = make([dynamic]S, len(column))
    out_column := &out.data[header]
    for value, idx in column {
      new_value, ok := converter(value)
      if ok {
        out_column[idx] = new_value
      } else {
        out_column[idx] = default
      }
    }
  }
  return out
}

/////////////////////////////////////

readDictOfListsFromCsv_filepath :: proc(filepath: string, ignore_blank_lines: bool = true) -> CsvTableData(string) {
  fd, fd_err := os.open(filepath, os.O_RDONLY)
  defer os.close(fd)
  if fd_err != 0 {
    return makeCsvTableData(string)
  }
  return readDictOfListsFromCsv_filehandle(fd, ignore_blank_lines)
}

readDictOfListsFromCsv_filehandle :: proc(fd: os.Handle, ignore_blank_lines: bool = true) -> CsvTableData(string) {
  out := makeCsvTableData(string)
  stream := os.stream_from_handle(fd)
  return readDictOfListsFromCsv_stream(stream, ignore_blank_lines)
}

readDictOfListsFromCsv_stream :: proc(stream: io.Stream, ignore_blank_lines: bool = true) -> CsvTableData(string) {
  stream_reader := io.Reader{stream}
  return readDictOfListsFromCsv_io_reader(stream_reader, ignore_blank_lines)
}

readDictOfListsFromCsv_io_reader :: proc(reader: io.Reader, ignore_blank_lines: bool = true) -> CsvTableData(string) {
  out := makeCsvTableData(string)
  csv_reader := csv.Reader{}
  csv.reader_init(&csv_reader, reader)
  defer csv.reader_destroy(&csv_reader)
  return readDictOfListsFromCsv_csv_reader(&csv_reader, ignore_blank_lines)
}

readDictOfListsFromCsv_csv_reader :: proc(reader: ^csv.Reader, ignore_blank_lines: bool = true) -> CsvTableData(string) {
  out := makeCsvTableData(string)
  reader.reuse_record = true
  record: []string
  csv_err: csv.Error
  headers: [dynamic]string
  defer delete(headers)
  {
    // get headers
    for {
      record, csv_err = csv.read(reader)
      if csv_err == io.Error.No_Progress {
        break
      }
      if len(record) == 0 {
        continue
      }
      // set headers
      for header in record {
        append(&headers, header)
        out.data[header] = make([dynamic]string)
      }
      break
    }
    if len(headers) == 0 {
      return out
    }
  }
  {
    // read in data
    for {
      record, csv_err = csv.read(reader)
      if csv_err == io.Error.No_Progress {
        break
      }
      if ignore_blank_lines && len(record) == 0 {
        continue
      }
      for header, idx in headers {
        append(&out.data[header], record[idx])
      }
    }
    if len(headers) == 0 {
      return out
    }
  }
  return out
}

readDictOfListsFromCsv :: proc {
  readDictOfListsFromCsv_filepath,
  readDictOfListsFromCsv_filehandle,
  readDictOfListsFromCsv_stream,
  readDictOfListsFromCsv_io_reader,
  readDictOfListsFromCsv_csv_reader,
}

///////////////////////////

readDictOfFloatsFromCsv :: proc(input: $T, ignore_blank_lines: bool = true) -> CsvTableData(f64) {
  str_table := readDictOfListsFromCsv(input, ignore_blank_lines)
  defer deleteCsvTableData(&str_table)
  parse_f64 :: proc(s: string) -> (result: f64, ok: bool) {
    result, ok = gstrconv.parse_f64(s)
    return
  }
  nan := math.nan_f64()
  out := convertTable(&str_table, parse_f64, nan)
  return out
}

///////////////////////////

getComplexTableFromFloatTable :: proc(table: ^CsvTableData(f64), real_suffix: string = "_real", imag_suffix: string = "_imag") -> CsvTableData(complex128) {
  using gstring
  num_rows := getNumRows(table)
  out := makeCsvTableData(complex128)
  // look for keys that end with '_real', '_imag'
  complex_keys := make(map[string][2]string)
  defer delete(complex_keys)
  // fmt.printf("\n\nrtable:%v\n\n", table)
  suffixes := [?]type_of(real_suffix){real_suffix, imag_suffix}
  for k, _ in table.data {
    for suffix, idx in suffixes {
      ckey := removeSuffix(k, suffix)
      if endswith(k, suffix) {
        if !(ckey in complex_keys) {
          complex_keys[ckey] = {}
        }
        rkeys := &complex_keys[ckey]
        rkeys[idx] = k
      }
    }
  }
  assignment: for ckey, rkeys in complex_keys {
    out.data[ckey] = make([dynamic]complex128, num_rows)
    // check that all rkeys are in float table
    for rkey in rkeys {
      if !(rkey in table.data) {
        break assignment
      }
      if len(table.data[rkey]) != num_rows {
        break assignment
      }
    }
    real_data := &table.data[rkeys[0]]
    imag_data := &table.data[rkeys[1]]
    complex_data := &out.data[ckey]
    for n in 0 ..< num_rows {
      complex_data[n] = complex(real_data[n], imag_data[n])
    }
  }
  return out
}


getQuaternionTableFromFloatTable :: proc(
  table: ^CsvTableData(f64),
  real_suffix: string = "_real",
  imag_suffix: string = "_imag",
  jmag_suffix: string = "_jmag",
  kmag_suffix: string = "_kmag",
) -> CsvTableData(quaternion256) {
  using gstring
  num_rows := getNumRows(table)
  out := makeCsvTableData(quaternion256)
  // look for keys that end with '_real', '_imag', '_jmag', '_kmag'
  quat_keys := make(map[string][4]string)
  defer delete(quat_keys)
  // fmt.printf("\n\nrtable:%v\n\n", table)
  suffixes := [?]type_of(real_suffix){real_suffix, imag_suffix, jmag_suffix, kmag_suffix}
  for k, _ in table.data {
    for suffix, idx in suffixes {
      qkey := removeSuffix(k, suffix)
      if endswith(k, suffix) {
        if !(qkey in quat_keys) {
          quat_keys[qkey] = {}
        }
        rkeys := &quat_keys[qkey]
        rkeys[idx] = k
      }
    }
  }
  assignment: for qkey, rkeys in quat_keys {
    out.data[qkey] = make([dynamic]quaternion256, num_rows)
    // check that all rkeys are in quat table
    for rkey in rkeys {
      if !(rkey in table.data) {
        break assignment
      }
      if len(table.data[rkey]) != num_rows {
        break assignment
      }
    }
    real_data := &table.data[rkeys[0]]
    imag_data := &table.data[rkeys[1]]
    jmag_data := &table.data[rkeys[2]]
    kmag_data := &table.data[rkeys[3]]
    quat_data := &out.data[qkey]
    for n in 0 ..< num_rows {
      q := quaternion256{}
      q.w = real_data[n]
      q.x = imag_data[n]
      q.y = jmag_data[n]
      q.z = kmag_data[n]
      quat_data[n] = q
    }
  }
  return out
}
