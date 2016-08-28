use Switch;
use Term::ANSIColor;
use Time::HiRes qw(gettimeofday time tv_interval);

sub _output;		# Output to STDOUT or a log (if daemonized)

sub logInfo {
  my $message = shift || return;
  _output($message, 1);
}

sub logDebug {
  my $message = shift || return;
  _output($message, 2);
}

sub logTrace {
  my $message = shift || return;
  _output($message, 3);
}

sub logWarn {
  my $message = shift || return;
  _output($message, -1);
}

sub logError {
  my $message = shift || return;
  _output($message, -2);
}

sub logFatal {
  my $message = shift || return;
  _output($message, -3);
}

# Catch die() calls
sub catch_die {
  logFatal("ERROR CAUGHT: Attempted die() call with error: ".$_[0]);
}

# Output htsldapd messages to STDOUT (or log if daemonized)
sub _output {
  my $message = shift || return;
  my $level = shift || 0;
  if (%config && $config{'VERBOSITY'} < $level) { return; }
  my @time = gettimeofday;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time[0]);
  $year += 1900;
  my $levelTag = '';
  switch ($level) {
    case -3 { $levelTag = '[FATAL] '; print color('red'); }
    case -2 { $levelTag = '[ERROR] '; print color('yellow'); }
    case -1 { $levelTag = '[WARN] ';  print color('magenta'); }
    case 1  { $levelTag = '[INFO]  '; print color('white'); }
    case 2  { $levelTag = '[DEBUG] '; print color('grey16'); }
    case 3  { $levelTag = '[TRACE] '; print color('dark grey10'); }
    case 0  { next; }
    else    { $levelTag = ''; }
  }
  print $colorPrefix."[$mon/$mday/$year $hour:$min:$sec.".$time[1]."] $levelTag$message\n";
  print color('reset');

  exit(-1) if ($level == -3 && $message != "Test fatal");
}

print "\nTesting Logging Functions\n";
logTrace("Test trace");
logDebug("Test debug");
logInfo("Test info");
logWarn("Test warn");
logError("Test error");
logFatal("Test fatal");
print "Logging Test Finished\n\n";

1;