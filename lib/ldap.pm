use Net::LDAP;
use Net::LDAP::Control::PasswordPolicy;
use Net::LDAP::Constant qw( LDAP_INVALID_CREDENTIALS LDAP_CONTROL_PASSWORDPOLICY LDAP_PP_PASSWORD_EXPIRED LDAP_PP_ACCOUNT_LOCKED LDAP_PP_CHANGE_AFTER_RESET );
use Net::LDAP::Util qw(ldap_error_text ldap_error_name ldap_error_desc);

sub ldap_add {
  my $ldif = shift;

  # All basic error checking for these should've been done already
  my $uid	= $ldif->{'uid'};
  my $gecos	= $ldif->{'gecos'};
  my $password	= $ldif->{'password'};
  my $email	= $ldif->{'email'};
  my $question	= $ldif->{'question'};
  my $answer	= $ldif->{'answer'};
  my $mysql_id	= $ldif->{'mysql_id'};

# TODO: Finish this
}

sub ldap_search {
    my ($ldap, $filter) = @_;

    logTrace("LDAP Search Filter: $filter");

    return $ldap->search(
	    base	=> $config{'LDAPDN'},
        scope   => "sub",
        filter	=> $filter,
        attrs => ( )
    );
}

sub ldap_cleanup {
  my $ldap = shift;
  if ($ldap) {
    $ldap->unbind();
    $ldap->disconnect();
  }
}

sub ldap_bind {
  my ($ldap, $user, $pass, $ou) = @_;

  my $pp = Net::LDAP::Control::PasswordPolicy->new;
  my (@warns, @crits);
  my $authsuccess = 0;

# TODO: Review and re-test all this

  # Attempt to bind
  my $mesg = $ldap->bind('uid='.$user.',ou='.$ou.','.$config{'LDAPDN'}, password => $pass, control => [ $pp ]);
  if ($mesg->code == LDAP_INVALID_CREDENTIALS) {
    logWarn('Bind: Invalid credentials');
    push(@crits, 'LDAP_INVALID_CREDENTIALS');
  } elsif ($mesg->code) {
    logError('Bind: Error: '.$mesg->code);
    push(@crits, 'LDAP_ERR:'.$mesg->code);
  } else {
    logDebug('Bind: Success');
    $authsuccess = 1;
  }

  # Retrieve Password Policy return values, if any
  my $resp = $mesg->control(LDAP_CONTROL_PASSWORDPOLICY); # 1.3.6.1.4.1.42.2.27.8.5.1
  if ($resp) { 
    logDebug('Password Policy responses returned');
    # Check if expiring soon
    my $exp = $resp->time_before_expiration; # $exp is in seconds
    push(@warns, "LDAP_PP_PASSWORD_EXPIRING:$exp") if ($exp);

    # Check if they are in the grace period
    my $grace = $resp->grace_authentications_remaining; # $grace is the amount of logins they have left
    push(@warns, "LDAP_PP_GRACE_LOGINS_LEFT:$grace") if ($grace);

    # Check for other Password Policy errors
    my $pperr = $resp->pp_error;
    if ($pperr) {
      push(@crits, "LDAP_PP_PASSWORD_EXPIRED") if ($pperr == LDAP_PP_PASSWORD_EXPIRED);
      push(@crits, "LDAP_PP_ACCOUNT_LOCKED") if ($pperr == LDAP_PP_ACCOUNT_LOCKED);
      push(@crits, "LDAP_PP_CHANGE_AFTER_RESET") if ($pperr == LDAP_PP_CHANGE_AFTER_RESET);
    }
  }

  # Check for banned state (expired account)
  if ($authsuccess) {
    logDebug('Checking if banned');
    my $search = $ldap->search(base => 'ou='.$ou.',dc=example,dc=com', scope => 'sub', filter => '(uid='.$user.')', attrs => [ 'shadowExpire' ]);
    print "LDAP SEARCH ERROR ".$search->code().": ".$search->error if ($search->code());
    my $curday = int(time()/(24*60*60));
    foreach my $entry ($search->entries) {
      if ($entry->exists('shadowExpire')) {
        push(@crits, 'LDAP_BANNED') if ($entry->get_value('shadowExpire') != -1 && $entry->get_value('shadowExpire') lt $curday);
      }
    }
  }

  # Assemble hashref 
  my $ret = {};
  $ret->{'warns'} = [@warns] if (@warns);
  $ret->{'crits'} = [@crits] if (@crits);
  if ($#crits >= 0) {
    $ret->{'exit'} = 2;
    $ret->{'mesg'} = 'CRITICAL';
  } elsif ($#warns >= 0) {
    $ret->{'exit'} = 1;
    $ret->{'mesg'} = 'WARNING';
  } else { # No warnings or criticals
    if ($authsuccess) {
      $ret->{'exit'} = 0;
      $ret->{'mesg'} = 'OK';
    } else {
      $ret->{'exit'} = 3;
      $ret->{'mesg'} = 'UNKNOWN';
    }
  }
  return $ret;
}

1;