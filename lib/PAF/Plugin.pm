package PAF::Plugin;
use strict;
use warnings;

=head1 NAME

PAF::Plugin - Base module for all PAF::Plugin modules.

=head1 SYNOPSIS

Inherit from this to get your module running

=cut

=head1 FUNCTIONS

=over

=item C<< new >>

Standard new method, blesses a hash into the right class and puts any
key/value pair passed to it into the blessed hash.

=cut

sub new {
    my ( $class, %param ) = @_;

    my $name = ref $class || $class;
    $name =~ s/^.*:://x;
    $param{name} ||= $name;

    my $self = \%param;
    bless $self, $class;

    return $self;
} ## end sub new

=item C<< handler >>

This method handles each FastCGI request.

This is the first method to override. It takes two arguments :
a FCGI::Async object and a FCGI::Async::Request object.

=cut

sub handler {
    my ( $self, $fcgi, $req ) = @_;
    $req->print_stdout("Oh noes ! I ate all teh cookies :(\r\n");
    $req->finish;

    return 0;
} ## end sub handler

=item C<< http_reproxy( $req, $url ) >>

Send reproxy headers to given URL (or URL list) on given FastCGI
request.

=cut

sub http_reproxy {
    my ( $req, @paths ) = @_;

    my $url = shift @paths;

    my $headers = "HTTP/1.0 200 OK\r\n";
    $headers .= "X-Redirect-Content-Type: image/jpeg\r\n";
    $headers .= "X-Accel-Redirect: /reproxy\r\n";
    $headers .= "X-Reproxy-Url: $url\r\n\r\n";

    $req->print_stdout($headers);
    $req->finish;

    return 0;
} ## end sub http_reproxy

=item C<< http_ok( $req, $data ) >>

Send given data through given FastCGI request

=cut

sub http_ok {
    my ( $req, $data ) = @_;

    my $headers = "HTTP/1.0 200 OK\r\n";
    $headers .= "Content-Type: image/jpeg\r\n";
    $headers .= "Content-Length: " . length($data) . "\r\n\r\n";

    $req->print_stdout($headers);
    $req->print_stdout($data);
    $req->finish;

    return 0;
} ## end sub http_ok

=item C<< http_predirect( $req, $url ) >>

Permanently redirect given FastCGI request

=cut

sub http_predirect {
    my ( $req, $url ) = @_;

    my $headers = "HTTP/1.0 301 Moved Permanently\r\n";
    $headers .= "Location: $url\r\n\r\n";

    $req->print_stdout($headers);
    $req->finish;

    return 0;
} ## end sub http_predirect

=item C<< http_notfound( $req ) >>

Send a 404 error through given FastCGI request

=cut

sub http_notfound {
    my $req = shift;

    my $data    = "404 Not Found";
    my $headers = "HTTP/1.0 404 Nor Found\r\n";
    $headers .= "Content-Type: text/html\r\n";
    $headers .= "Content-Length: " . length($data) . "\r\n\r\n";

    $req->print_stdout($headers);
    $req->print_stdout($data);
    $req->finish;

    return 0;
} ## end sub http_notfound

=back

=head1 AUTHOR

Guillaume Blairon, C<< <g at yom.be > >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc PAF::Plugin

=head1 COPYRIGHT & LICENSE

Copyright 2010 Guillaume Blairon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
