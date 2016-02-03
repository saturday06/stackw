@set @stackw_script_temp=0 /* -*- mode: javascript, coding: us-ascii-dos -*- vim: set ft=javascript:
@echo off
set @stackw_script_temp=
setlocal
for /f "usebackq delims=" %%x in (`@cscript //Nologo //E:JScript "%~f0" %*`) do @set STACKW_REAL_COMMAND=%%x
if not "%STACKW_REAL_COMMAND%"=="" ("%STACKW_REAL_COMMAND%" %*)
exit /b %errorlevel%
:::::::::::::::::

  stack wrapper

::::::::::::::::: */

default_stack_version = "1.0.2";
filesystem = new ActiveXObject('Scripting.FileSystemObject');
shell = new ActiveXObject("WScript.Shell");
base_url = "https://github.com/commercialhaskell/stack/releases/download";
script_url = "https://raw.githubusercontent.com/saturday06/stackw/stable";

function write_stderr(message) {
  WScript.StdErr.Write(message);
}

function error_exit(message) {
  WScript.StdErr.WriteLine(message);
  WScript.Quit(1);
}

function temp_path(ext) {
  var temp_folder = filesystem.GetSpecialFolder(2);
  var temp_file;
  while (true) {
    var name = filesystem.GetTempName() + Math.round(Math.random() * 100) + ext;
    temp_file = filesystem.BuildPath(temp_folder, name);
    if (!filesystem.FileExists(temp_file)) {
      break;
    }
    WScript.Sleep(100);
  }
  return temp_file;
}

function execute_powershell(args, script) {
  var temp_file = temp_path(".ps1");
  var file = filesystem.OpenTextFile(temp_file, 2, true);
  try {
    file.Write(script);
  } finally {
    file.Close();
  }
  var arg_str = "";
  if (args.length > 0) {
    arg_str = '"' + args.join('" "') + '"';
  }
  var exec = shell.Exec('%COMSPEC% /c powershell -ExecutionPolicy RemoteSigned -File "' + temp_file + '" ' + arg_str + ' 2>&1');
  write_stderr(exec.StdOut.ReadAll());
  while (!exec.Status) {
    WScript.Sleep(100);
  }
  if (exec.ExitCode != 0) {
    error_exit("Failed to execute powershell script, ExitCode = " + exec.ExitCode);
  }
}

function parse_stack_yaml_option() {
  var args = WScript.Arguments;
  for (var i = 0; i < args.length; i++) {
    if (args(i) == "--stack-yaml") {
      if (i + 1 >= args.length) {
        return false;
      }
      return args(i + 1) + "";
    }
  }
  return false;
}

function find_ancestor_dir_stack_yaml() {
  var dir = shell.CurrentDirectory;
  while (true) {
    var file = filesystem.BuildPath(dir, "stack.yaml");
    if (filesystem.FileExists(file)) {
      return file;
    }
    var parent_dir = filesystem.GetParentFolderName(dir);
    if (parent_dir == "") {
      return false;
    }
    dir = parent_dir;
  }
}

function detect_stack_version() {
  var stack_yaml = parse_stack_yaml_option();
  if (!stack_yaml) {
    stack_yaml = shell.ExpandEnvironmentStrings("%STACK_YAML%");
  }
  if (!stack_yaml || stack_yaml == "%STACK_YAML%" || stack_yaml.length == 0) {
    stack_yaml = find_ancestor_dir_stack_yaml();
  }
  if (!stack_yaml || !filesystem.FileExists(stack_yaml)) {
    return default_stack_version;
  }
  var text = "";
  var stream = new ActiveXObject("ADODB.Stream");
  stream.CharSet = "utf-8";
  stream.Open();
  try {
    stream.LoadFromFile(stack_yaml);
    text = stream.ReadText();
  } finally {
    stream.Close();
  }
  var version = default_stack_version;
  var lines = text.replace(/\r/g, '').split(/\n/);
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    var re = /^# stack version: */;
    if (line.match(re)) {
      version = line.replace(re, "");
      break;
    }
  }
  return version;
}

function normalize_version(version) {
  version = (version + "").replace(/[._+-]+/g, ".");
  var normalized_version = "";
  while (version != "") {
    version = version.replace(/^\.+/, "");
    var integerMatch = version.match(/^[0-9]+/);
    if (integerMatch) {
      var value = version.substring(0, integerMatch[0].length);
      version = version.substring(integerMatch[0].length);
      normalized_version = normalized_version + "." + value;
      continue;
    }
    var stringMatch = version.match(/^[^.0-9]+/);
    if (stringMatch) {
      var value = version.substring(0, stringMatch[0].length);
      value = {
        "a": "alpha",
        "b": "beta",
        "RC": "rc",
        "p": "pl"
      }[value] || value;
      version = version.substring(stringMatch[0].length);
      normalized_version = normalized_version + "." + value;
      continue;
    }
  }
  return normalized_version.substring(1);
}

function compare_symbol(left, right, symbol) {
  if (left == right) {
    return 0;
  } else if (left == symbol) {
    return 1;
  } else if (right == symbol) {
    return -1;
  } else {
    return 0;
  }
}

function compare_string(left, right) {
  if (left > right) {
    return 1;
  } else if (left < right) {
    return -1;
  } else {
    return 0;
  }
}

function is_integer_string(str) {
  return !!(str + "").match(/^[0-9]+$/);
}

function compare_integer(left, right) {
  if (!is_integer_string(left) && !is_integer_string(right)) {
    return 0;
  } else if (!is_integer_string(left)) {
    return -1;
  } else if (!is_integer_string(right)) {
    return 1;
  }
  left = parseInt(left, 10);
  right = parseInt(right, 10);
  if (left > right) {
    return 1;
  } else if (left < right) {
    return -1;
  } else {
    return 0;
  }
}

function compare_version_element(left, right) {
  var comparison = [
    compare_symbol(left, right, "pl"),
    compare_integer(left, right),
    compare_symbol(left, right, "rc"),
    compare_symbol(left, right, "beta"),
    compare_symbol(left, right, "alpha"),
    compare_symbol(left, right, "dev"),
    compare_string(left, right)
  ];
  for (var i = 0; i < comparison.length; i++) {
    if (comparison[i] != 0) {
      return comparison[i];
    }
  }
  return 0;
}

function compare_version(left, right) {
  var lefts = normalize_version(left).split(".");
  var rights = normalize_version(right).split(".");
  for (var i = 0; i < Math.max(lefts.length, rights.length); i++) {
    var left_element = lefts.length > i ? lefts[i] : 0;
    var right_element = rights.length > i ? rights[i] : 0;
    var result = compare_version_element(left_element, right_element);
    if (result != 0) {
      return result;
    }
  }
  return 0;
}

function right_is_greater(left, right) {
  return compare_version(left, right) < 0;
}

function download(url, file) {
  if (filesystem.FileExists(file)) {
    filesystem.DeleteFile(file);
  }
  write_stderr("Download: " + url + "\n");
  execute_powershell([url, file], [
    'Param([string]$url, [string]$file)',
    '$ErrorActionPreference = "Stop"',
    'Invoke-WebRequest -Uri $url -OutFile $file'
  ].join('\n'));
}

function extract(zip_file, out_dir) {
  if (filesystem.FolderExists(out_dir)) {
    filesystem.DeleteFolder(out_dir);
  }
  filesystem.CreateFolder(out_dir);
  execute_powershell([zip_file, out_dir], [
    'Param([string]$zip_file, [string]$out_dir)',
    '$ErrorActionPreference = "Stop"',
    'if (Get-Command Expand-Archive -errorAction SilentlyContinue)',
    '{',
    '  Expand-Archive -Path $zip_file -DestinationPath $out_dir',
    '}',
    'else',
    '{',
    '  $shell = new-object -com shell.application',
    '  $zip = $shell.NameSpace($zip_file)',
    '  foreach($item in $zip.items())',
    '  {',
    '    $shell.Namespace($out_dir).copyhere($item)',
    '  }',
    '}'
  ].join('\n'));
}

function upgrade() {
  var exts = ["", ".bat"];
  for (var i = 0; i < exts.length; i++) {
    var name = "stackw" + exts[i];
    var file = filesystem.BuildPath(filesystem.GetParentFolderName(WScript.ScriptFullName), name);
    if (!filesystem.FileExists(file)) {
      continue;
    }
    var url = script_url + "/" + name;
    var tmp_file = temp_path(".stackw" + exts[i]);
    download(url, tmp_file);

    var from = filesystem.OpenTextFile(tmp_file); // TODO: multibyte
    var from_text;
    try {
      from_text = from.ReadAll();
    } finally {
      from.Close();
    }

    var to = filesystem.OpenTextFile(file); // TODO: multibyte
    var to_text;
    try {
      to_text = to.ReadAll();
    } finally {
      to.Close();
    }

    if (from_text != to_text) {
      filesystem.CopyFile(tmp_file, file, true);
    }
  }
}

function assert_equal(left, right) {
  if (left != right) {
    error_exit("ASSERT " + left + " != " + right + "\n");
  }
}

function selftest() {
  assert_equal(is_integer_string("12345"), 1);
  assert_equal(is_integer_string("a"), 0);
  assert_equal(is_integer_string("12a45"), 0);

  assert_equal(normalize_version(1), "1");
  assert_equal(normalize_version("10"), "10");
  assert_equal(normalize_version("10a"), "10.alpha");
  assert_equal(normalize_version("10a1"), "10.alpha.1");
  assert_equal(normalize_version("a1b23c"), "alpha.1.beta.23.c");
  assert_equal(normalize_version("123...dev"), "123.dev");
  assert_equal(normalize_version("devalphadev"), "devalphadev");

  assert_equal(compare_symbol("foo", "foo", "foo"), 0);
  assert_equal(compare_symbol("foo", "bar", "foo"), 1);
  assert_equal(compare_symbol("fooa", "bar", "foo"), 0);
  assert_equal(compare_symbol("bar", "foo", "foo"), -1);
  assert_equal(compare_symbol("bar", "fooa", "foo"), 0);
  assert_equal(compare_symbol("foo", "foo", "baz"), 0);

  assert_equal(compare_string("alpha", "alpha"), 0);
  assert_equal(compare_string("beta", "alpha"), 1);
  assert_equal(compare_string("alpha", "beta"), -1);
  assert_equal(compare_string("aaab", "aaa"), 1);
  assert_equal(compare_string("aaa", "aaab"), -1);

  assert_equal(compare_integer("a", "b"), 0);
  assert_equal(compare_integer("1", "b"), 1);
  assert_equal(compare_integer("c", "1"), -1);
  assert_equal(compare_integer("123", "9"), 1);
  assert_equal(compare_integer("123", "123"), 0);
  assert_equal(compare_integer("123", "124"), -1);

  assert_equal(compare_version_element("pl", "pl"),  0);
  assert_equal(compare_version_element("pl", "0"),   1);
  assert_equal(compare_version_element("pl", "rc"),  1);
  assert_equal(compare_version_element("pl", "foo"), 1);
  assert_equal(compare_version_element("0", "pl"),   -1);
  assert_equal(compare_version_element("rc", "pl"),  -1);
  assert_equal(compare_version_element("foo", "pl"), -1);
  assert_equal(compare_version_element("rc", "pl"),  -1);
  assert_equal(compare_version_element("rc", "0"),   -1);
  assert_equal(compare_version_element("rc", "rc"),  0);
  assert_equal(compare_version_element("rc", "foo"), 1);
  assert_equal(compare_version_element("0", "rc"),   1);
  assert_equal(compare_version_element("foo", "rc"), -1);

  assert_equal(compare_version("1rc", "1pl"),  -1);
  assert_equal(compare_version("0", "1"),  -1);
  assert_equal(compare_version("1.0pl1", "1.0"),  1);
  assert_equal(compare_version("0.3", "0.3"),  0);

  assert_equal(right_is_greater("1rc", "1pl"), 1);
  assert_equal(right_is_greater("0", "1"), 1);
  assert_equal(right_is_greater("1.0pl1", "1.0"), 0);
  assert_equal(right_is_greater("0.3", "0.3"), 0);

  return 0;
}

if (WScript.Arguments.Length == 1 && WScript.Arguments(0) == "stackw-upgrade") {
  upgrade();
  WScript.Quit(0);
}

if (WScript.Arguments.Length == 1 && WScript.Arguments(0) == "stackw-selftest") {
  selftest();
  WScript.Quit(0);
}

var machine = null;
var machine_env = shell.ExpandEnvironmentStrings("%PROCESSOR_ARCHITECTURE%");
if (machine_env == "AMD64") {
  machine = "x86_64";
} else if (machine_env == "x86") {
  machine = "i386";
} else {
  var address_width = GetObject("winmgmts:root\\cimv2:Win32_Processor='cpu0'").AddressWidth;
  if (address_width == 64) {
    machine = "x86_64";
  } else if (address_width == 32) {
    machine = "i386";
  }
}
if (!machine) {
  error_exit("Failed to detect your system");
}

var version = detect_stack_version();
var base_name = "";
if (right_is_greater(version, "0.1.6.0")) {
  base_name = "stack-" + version + "-" + machine + "-windows";
} else {
  base_name = "stack-" + version + "-windows-" + machine;
}
var url = base_url + "/v" + version + "/" + base_name + ".zip";

var base_dir = filesystem.BuildPath(shell.ExpandEnvironmentStrings("%APPDATA%"), "stack");
if (!filesystem.FolderExists(base_dir)) {
  filesystem.CreateFolder(base_dir);
}
var wrapper_dir = filesystem.BuildPath(base_dir, "wrapper");
if (!filesystem.FolderExists(wrapper_dir)) {
  filesystem.CreateFolder(wrapper_dir);
}
var programs_dir = filesystem.BuildPath(wrapper_dir, "programs");
if (!filesystem.FolderExists(programs_dir)) {
  filesystem.CreateFolder(programs_dir);
}
var extract_dir = filesystem.BuildPath(programs_dir, base_name);
var zip_file = filesystem.BuildPath(programs_dir, base_name + ".zip");
var done_file = filesystem.BuildPath(programs_dir, base_name + ".done");
var stack_path = filesystem.BuildPath(extract_dir, "stack.exe");

if (!filesystem.FileExists(done_file)) {
  download(url, zip_file);
  extract(zip_file, extract_dir);
  var verbose_path = filesystem.BuildPath(extract_dir, base_name + ".exe");
  if (filesystem.FileExists(verbose_path)) {
    filesystem.CopyFile(verbose_path, stack_path);
  }
  filesystem.CreateTextFile(done_file);
}

WScript.Echo(stack_path);
