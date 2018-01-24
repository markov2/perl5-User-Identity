package User::Identity::Collection::Locations;
use base 'User::Identity::Collection';

use strict;
use warnings;

use User::Identity::Location;

use Carp qw/croak/;

=head1 NAME

User::Identity::Collection::Locations - a collection of locations

=head1 SYNOPSIS

=head1 DESCRIPTION

The User::Identity::Collection::Location object maintains a set
User::Identity::Location objects, each describing a physical location.

=head1 METHODS

=head2 Initiation

=cut

#-----------------------------------------

=c_method new [NAME], OPTIONS

=default name      'locations'
=default item_type 'User::Identity::Location'

=cut

sub new(@)
{   my $class = shift;
    $class->SUPER::new(locations => @_);
}

sub init($)
{   my ($self, $args) = @_;
    $args->{item_type} ||= 'User::Identity::Location';

    $self->SUPER::init($args);

    $self;
}

#-----------------------------------------

=head2 Attributes

=cut

#-----------------------------------------

1;

