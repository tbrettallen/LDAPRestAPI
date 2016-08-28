use strict;
use warnings;
use Mojolicious::Lite;

use lib::ldap;
use lib::logging;
use lib::conf;
use lib::auth;

# Start output/logging
logInfo("LDAP Daemon");

get '/' => sub {
  my $c = shift;
  $c->render(text => 'TODO: Usage instructions');
};

get '/search/:filter' => sub {
  my $c    = shift;
  my $ldap;

  unless ($ldap = Net::LDAP->new($config{'LDAPHOST'}.':'.$config{'LDAPPORT'})) {
    logError("Error: Cannot connect to LDAP: $@");
    $ldap->disconnect();
    $c->render(json => {
      exit => -10,
      msg => 'Unable to connect to LDAP'
    });
    return;
  }

  my $bindres = $ldap->bind ( version => 3 ); 

  my $result = ldap_search($ldap, $c->param('filter'));
  
  my $href = $result->as_struct;

  ldap_cleanup($ldap);

  $c->render(json => { %{ $href } });
};

post '/set' => sub {
  my $c    = shift;
  
  #TODO
};

post '/auth' => sub {
  my $c    = shift;
  my $jsonObject = $c->req->json;

  #TODO
};

post '/check' => sub {
  my $c    = shift;
  my $jsonObject = $c->req->json;

  #TODO
};

post '/add' => sub {
  my $c    = shift;
  my $jsonObject = $c->req->json;

  #TODO
};

app->start;