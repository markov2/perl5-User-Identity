package User::Identity::Collection::Systems;
use base 'User::Identity::Collection';

use strict;
use warnings;

use User::Identity::System;

=head1 NAME

User::Identity::Collection::Systems - a collection of system descriptions

=head1 SYNOPSIS

=head1 DESCRIPTION

The User::Identity::Collection::Systems object maintains a set
Use:::Identity::System objects, each describing a login for the
user on some system.

=head1 METHODS

=head2 Initiation

=cut

#-----------------------------------------

=c_method new [NAME], OPTIONS

=default name      'systems'
=default item_type 'User::Identity::System'

=cut

sub new(@)
{   my $class = shift;
    $class->SUPER::new(systems => @_);
}

sub init($)
{   my ($self, $args) = @_;
    $args->{item_type} ||= 'User::Identity::System';

    $self->SUPER::init($args);

    $self;
}

#-----------------------------------------

=head2 Attributes

=cut

#-----------------------------------------

1;

