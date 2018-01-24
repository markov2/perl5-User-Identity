package User::Identity::Collection::Systems;
use base 'User::Identity::Collection';

use strict;
use warnings;

use Mail::Identity;

=head1 NAME

User::Identity::Collection::Systems - a collection of system descriptions

=head1 SYNOPSIS

=head1 DESCRIPTION

The User::Identity::Collection::Email object maintains a set
Mail::Identity objects, each describing a role which the user has
in e-mail traffic.

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
    $class->SUPER::new(emails => @_);
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

