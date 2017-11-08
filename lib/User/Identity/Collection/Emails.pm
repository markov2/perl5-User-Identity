package User::Identity::Collection::Emails;
use base 'User::Identity::Collection';

use strict;
use warnings;

use Mail::Identity;

=chapter NAME

User::Identity::Collection::Emails - a collection of email roles

=chapter SYNOPSIS

=chapter DESCRIPTION

The C<User::Identity::Collection::Emails> object maintains a set
M<Mail::Identity> objects, each describing a role which the user has
in e-mail traffic.

=chapter METHODS

=section Constructors

=c_method new [$name], %options

=default name      C<'emails'>
=default item_type M<Mail::Identity>

=cut

sub new(@)
{   my $class = shift;
    $class->SUPER::new(name => 'emails', @_);
}

sub init($)
{   my ($self, $args) = @_;
    $args->{item_type} ||= 'Mail::Identity';

    $self->SUPER::init($args);
}

sub type() { 'mailgroup' }

1;

