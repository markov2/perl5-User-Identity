package User::Identity::System;
use base 'User::Identity::Item';

use strict;
use warnings;

use User::Identity;
use Scalar::Util 'weaken';

=chapter NAME

User::Identity::System - physical system of a person

=chapter SYNOPSIS

 use M<User::Identity>;
 use User::Identity::System;
 my $me   = User::Identity->new(...);
 my $server = User::Identity::System->new(...);
 $me->add(system => $server);

 # Simpler

 use User::Identity;
 my $me   = User::Identity->new(...);
 my $addr = $me->add(system => ...);

=chapter DESCRIPTION
The C<User::Identity::System> object contains the description of the
user's presence on a system.  The systems are collected
by an M<User::Identity::Collection::Systems> object.

Nearly all methods can return undef.

=chapter METHODS

=cut

sub type { "network" }

=c_method new [NAME], OPTIONS

Create a new system.  You can specify a name as first argument, or
in the OPTION list.  Without a specific name, the organization is used as name.

=option  hostname DOMAIN
=default hostname C<'localhost'>

The hostname of the described system.  It is prefered to use full
system names, not abbreviations.  For instance, you can better use
C<www.tux.aq> than C<www> to avoid confusion.

=option  location NICKNAME|OBJECT
=default location undef

The NICKNAME of a location which is defined for the same user.  You can
also specify a M<User::Identity::Location> OBJECT.

=option  os       STRING
=default os       undef

The name of the operating system which is run on the server.  It is
adviced to use the names as used by Perl's C<$^O> variable.  See the
perlvar man-page for this variable, and perlport for the possible
values.

=option  password STRING
=default password undef

The password to be used to login.  This password must be un-encoded:
directly usable.  Be warned that storing un-encoded passwords is a
high security list.

=option  username STRING
=default username undef

The username to be used to login to this host.

=cut

sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args);
    exists $args->{$_} && ($self->{'UIS_'.$_} = delete $args->{$_})
        foreach qw/hostname location os password username/;

   $self->{UIS_hostname} ||= 'localhost';
   $self;
}

=section Attributes
=method hostname

=cut

sub hostname() { shift->{UIS_hostname} }

=method username

=cut

sub username() { shift->{UIS_username} }

=method os

=cut

sub os() { shift->{UIS_os} }

=method password

=cut

sub password() { shift->{UIS_password} }

=method location

Returns the object which describes to which location this system relates.
The location may be used to find the name of the organization involved, or
to create a signature.  If no location is specified, undef is returned.

=cut

sub location()
{   my $self      = shift;
    my $location  = $self->{MI_location} or return;

    unless(ref $location)
    {   my $user  = $self->user or return;
        $location = $user->find(location => $location);
    }

    $location;
}

1;

