use vars qw( %config );
use Cwd 'abs_path';
use File::Basename;
use constant BASEDIR => abs_path(dirname(abs_path($0)).'/../');

#
# Load config
#

unless (my $return = do(BASEDIR.'/conf/ldap.conf')) {
  logFatal("Couldn't parse ldap.conf: $@") if $@;
  logFatal("ldap.conf appears empty: $!") unless defined $return;
  logFatal("Couldn't run ldap.conf") unless $return;
}
logFatal("Config not defined") unless %config;

logDebug("Config loaded");

1;