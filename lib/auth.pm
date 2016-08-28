
use Mojolicious::Lite;
use Mojolicious::Plugin::BasicAuth;

plugin 'basic_auth';

under sub {
  my $c = shift;

  return $c->basic_auth(
      realm => sub { 
      # Authenticated
        return 1 if "@_" eq 'key '.$config{'KEY'}; 

        # Not authenticated
        $c->res->headers->header('WWW-Authenticate' => 'basic');
        $c->render(template => 'denied');
        return undef;
      }
  );
};

__DATA__

@@ denied.html.ep
<!DOCTYPE html>
<html>
  <head><title>Authorization denied</title></head>
  <body>Authorization denied.</body>
</html>