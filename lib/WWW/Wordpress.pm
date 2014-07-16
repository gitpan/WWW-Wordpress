# Copyleft 2014 Daniel Torres 
# daniel.torres at owasp.org
# All rights released.
package WWW::Wordpress;


use strict;
use warnings FATAL => 'all';
use Carp qw(croak);
use Moose;
use Net::SSL (); # From Crypt-SSLeay
use LWP::UserAgent;
use HTTP::Cookies;
use JSON qw( decode_json ); 
use URI;
use Data::Dumper;

our $VERSION = '1.3';

###### default values #####
use constant WORDPRESS_URL => 'https://public-api.Wordpress.com/rest/v1/';
$Net::HTTPS::SSL_SOCKET_CLASS = "Net::SSL"; # Force use of Net::SSL for proxy compatibility
##############################

{
has 'blog', is => 'rw', isa => 'Str',required => 1;	
has 'blog_id', is => 'rw', isa => 'Str',required => 1;	
has 'access_token', is => 'rw', isa => 'Str',required => 1;

has proxy_host      => ( isa => 'Str', is => 'rw', default => '' );
has proxy_port      => ( isa => 'Str', is => 'rw', default => '' );
has proxy_user      => ( isa => 'Str', is => 'rw', default => '' );
has proxy_pass      => ( isa => 'Str', is => 'rw', default => '' );
has proxy_env      => ( isa => 'Str', is => 'rw', default => '' );

has browser  => ( isa => 'Object', is => 'rw', lazy => 1, builder => '_build_browser' );


##### site info #######       
sub site_info
{
my $self = shift;
my %options = @_;
my $blog = $self->blog;
my $response = $self->dispatch(path => "sites/$blog",method => 'GET');
#my content = $response->content;

my $response_json = decode_json($response->content);
#print Dumper $response_json;
my $post_count = $response_json->{'post_count'};
my $subscribers_count = $response_json->{'subscribers_count'};
return {post_count => $post_count, subscribers_count => $subscribers_count};
}

###################################### blog  functions ###################


# post to blog
sub post
{
my $self = shift;
my %options = @_;
my $post_data = $options{ post_data };
my $blog = $self->blog;

my $response = $self->dispatch(path => "sites/$blog/posts/new",method => 'POST',post_data =>$post_data);
#print "\n \n".$response->content;
my $response_json = decode_json($response->content);
my $id = $response_json->{'ID'};
my $URL = $response_json->{'URL'};

return {id => $id, URL => $URL};
}    


#edit post
sub edit_post
{
my $self = shift;
my %options = @_;
my $post_data = $options{ post_data };
my $post_id = $options{ post_id };
#print Dumper %options;
my $blog = $self->blog;
my $response = $self->dispatch(path => "sites/$blog/posts/$post_id",method => 'POST',post_data =>$post_data);
my $response_json = decode_json($response->content);
#print Dumper $response_json;
my $status = $response_json->{'status'};
return $status ;
}


###################################### Users  functions ##################

# Follow a blog
sub follow
{
my $self = shift;
my %options = @_;
my $blog = $options{ blog };
my $post_data = $options{ post_data };

my $response = $self->dispatch(path => "sites/$blog/follows/new",method => 'POST',post_data =>$post_data);
my $response_json = decode_json($response->content);
#print Dumper $response_json;
my $status = $response_json->{'success'};
return $status ;
}

# unfollow a blog
sub unfollow
{
my $self = shift;
my %options = @_;
my $blog = $options{ blog };
my $post_data = $options{ post_data };
my $response = $self->dispatch(path => "sites/$blog/follows/mine/delete",method => 'POST',post_data =>$post_data);
my $response_json = decode_json($response->content);
#print Dumper $response_json;
my $status = $response_json->{'success'};
#my $is_following = $response_json->{'is_following'};
return $status ;
}


###################################### internal functions ###################
sub dispatch {    
my $self = shift;
my %options = @_;
my $access_token = $self->access_token;

$self->browser->default_header('Authorization' => "Bearer $access_token");

my $base = WORDPRESS_URL;
my $path = $options{ path };
my $method = $options{ method };

my $url = $base.$path;
#print "url $url \n";
my $response = '';
if ($method eq 'GET')
  { $response = $self->browser->get($url);}
  
if ($method eq 'POST')
  {     
   my $post_data = $options{ post_data };        
   $response = $self->browser->post($url,$post_data);
  }  
  
return $response;
}

sub _build_browser {    
my $self = shift;

my $proxy_host = $self->proxy_host;
my $proxy_port = $self->proxy_port;
my $proxy_user = $self->proxy_user;
my $proxy_pass = $self->proxy_pass;
my $proxy_env = $self->proxy_env;

my $browser = LWP::UserAgent->new;
$browser->timeout(20);
$browser->show_progress(1);
#print "proxy_env $proxy_env \n";

if ( $proxy_env eq 'ENV' )
{
$Net::HTTPS::SSL_SOCKET_CLASS = "Net::SSL"; # Force use of Net::SSL
$ENV{HTTPS_PROXY} = "http://".$proxy_host.":".$proxy_port;
}
else
{
  if (($proxy_user ne "") && ($proxy_host ne ""))
  {
   $browser->proxy(['http', 'https'], 'http://'.$proxy_user.':'.$proxy_pass.'@'.$proxy_host.':'.$proxy_port); # Using a private proxy
  }
  elsif ($proxy_host ne "")
    { $browser->proxy(['http', 'https'], 'http://'.$proxy_host.':'.$proxy_port);} # Using a public proxy
  else
    { $browser->env_proxy;} # No proxy       
}     
    
return $browser;
}

}

1;



__END__

=head1 NAME

WWW::Wordpress - Wordpress API interface .


=head1 SYNOPSIS


Usage:

   use WWW::Wordpress;
   $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
   my $wordpress = WWW::Wordpress->new( blog => 'blog.Wordpress.com',
					blog_id => '00000',
					access_token => 'XXXXX');					



=head1 DESCRIPTION

Wordpress API interface

=head1 FUNCTIONS

=head2 constructor

    my $wordpress = WWW::Wordpress->new( blog => 'blog.Wordpress.com',
					blog_id => '00000',
					access_token => 'XXXXX');	

To get your Access Token check

http://developer.Wordpress.com/docs/oauth2/#receiving-an-access-token

=head2 site_info

    $site_info = $wordpress->site_info;
    $post_count = $site_info->{post_count};
    $subscribers_count = $site_info->{subscribers_count};
    print "post_count $post_count \n";
    print "subscribers_count $subscribers_count \n";

stats of the site.

=head2 post

    $content = "this is my test body ";
    $title = "new title";
    $tags = "linux";
    my $post_data = { content => $content,title => $title,tags => $tags };
    $post_info = $wordpress->post(post_data => $post_data );
    $id = $post_info->{id};
    $URL = $post_info->{URL};
    print "id $id URL $URL  \n";


Post an article

=head2 edit_post

    $new_content = "Edited test";
    $post_id = 19;

    my $post_data = { content => $new_content};
    $status = $wordpress->edit_post(post_data => $post_data, post_id => $post_id);
    print "status $status \n";

Edit a post by post id

=head2 follow

    my $post_data = { pretty => 1};
    $status = $wordpress->follow(blog => 'blog.Wordpress.com',post_data => $post_data);  
    print "status $status \n";

Follow another blog
   
=head2 unfollow

    my $post_data = { pretty => 1};
    $status = $wordpress->unfollow(blog => 'blog.Wordpress.com',post_data => $post_data);  
    print "status $status \n";

Unfollow blog
   
=head2 dispatch

 Internal function         
                  
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
=cut
