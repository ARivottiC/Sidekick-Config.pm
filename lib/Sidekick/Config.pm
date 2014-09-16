#!/usr/bin/perl
package Sidekick::Config;

use v5.10;

use strict;
use warnings;

use Sidekick::Data ();
use Config::Any ();
use Hash::Merge ();
use Log::Log4perl qw(:nowarn);

my $logger     = Log::Log4perl->get_logger();
my $hash_merge = Hash::Merge->new();

# for internal functions
my ($file2hash, $instance2hash, $merge_hashes, $override);

sub new {
    my $class = shift;
    my @args  = @_;

    my @hashes;
    for my $arg ( @args ) {
        given ( ref $arg ) {
            when ( 'HASH' ) { push @hashes, $arg;                       }
            when ( ''     ) { push @hashes, $class->$file2hash( $arg ); }
        };
    }

    return Sidekick::Data->new(
            'ro' => 1, 'data' => $class->$merge_hashes( @hashes )
        );
}

# Internal Functions
$file2hash = sub {
    my $class = shift;
    my $file  = shift;

    my $type = 'stems';
    if ( $file =~ /\.[^\.]{2,4}$/ ) {
        $type = 'files';
    }

    my $method = sprintf('load_%s', $type);
    my $stems  = Config::Any->$method({
            $type     => [ $file ],
            'use_ext' => 1,
        });

    if ( my $config = shift @{ $stems } ) {
        my (undef,$hash) = %{ $config };
        return $hash;
    }

    return ();
};

$instance2hash = sub {
    my $class = shift;
    my %arg = @_;
    my ($instance) = $arg{'instance'};

    if ( $instance && exists $arg{ $instance } ) {
        return $arg{ $instance };
    }

    return ();
};

$merge_hashes = sub {
    my $class  = shift;
    my $merged = shift @_;
    my @hashes = @_;

    while ( my $hash = shift @hashes ) {
        $merged = $hash_merge->merge( $merged, $hash );
    }

    return $merged;
};

$override = sub { $_[1] };

$hash_merge->specify_behavior(
    {
        'SCALAR' => {
            'SCALAR' => $override, 'ARRAY' => $override, 'HASH' => $override,
        },
        'ARRAY' => {
            'SCALAR' => $override, 'ARRAY' => $override, 'HASH' => $override,
        },
        'HASH' => {
            'SCALAR' => $override,
            'ARRAY'  => $override,
            'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
        },
    },
    'RIGHT_PRECEDENT_NONHASH_OVERRIDE',
);

1;
# ABSTRACT: we'll get there
# vim:ts=4:sw=4:syn=perl
