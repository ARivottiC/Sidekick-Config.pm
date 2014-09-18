#!/usr/bin/perl
package Sidekick::App::Config;

use v5.10;

use strict;
use warnings;
use mro;

use Sidekick::Config ();

use Hash::Util::FieldHash ();
use Log::Log4perl qw(:nowarn);

my $logger = Log::Log4perl->get_logger();

Hash::Util::FieldHash::fieldhash my %Config;

sub defaults { return shift->maybe::next::method( @_ ); }

sub init {
    my $self = shift;
    my %arg  = @_;

    my $name = $self->name;
    my $root = $self->root || '/';

    $Config{ $self } = Sidekick::Config->new(
            $self->defaults,
            sprintf('%s/%s/etc/config.yaml', $root, $name ),
            ( $arg{'config'} || {} ),
        );

    return $self->maybe::next::method( %arg );
}

sub config { return $Config{ shift() }; }

1;
# ABSTRACT: we'll get there
# vim:ts=4:sw=4:syn=perl
