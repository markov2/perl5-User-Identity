package User::Identity::Collection::Locations;
use base 'User::Identity::Collection';

use strict;
use warnings;

use User::Identity::Location;

use Carp qw/croak/;

=chapter NAME

User::Identity::Collection::Locations - a collection of locations

=chapter SYNOPSIS

=chapter DESCRIPTION

The C<User::Identity::Collection::Location> object maintains a set
M<User::Identity::Location> objects, each describing a physical location.

=chapter METHODS

=c_method new [NAME], OPTIONS

=default name      C<'locations'>
=default item_type M<User::Identity::Location>

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

sub type() { 'whereabouts' }

1;

