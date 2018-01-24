package User::Identity::Collection::Item;

use strict;
use warnings;

use User::Identity;
use Scalar::Util qw/weaken/;
use Carp         qw/carp croak/;

=head1 NAME

User::Identity::Collection::Item - bae class for any collectable item

=head1 SYNOPSIS

=head1 DESCRIPTION

The User::Identity::Collection::Item object is extended into objects which
contain data to be collected.

=head1 METHODS

=head2 Initiation

=cut

#-----------------------------------------

=c_method new [NAME], OPTIONS

=option  name STRING
=default name <required>

A simple name for this location, like 'home' or 'work'.

=option  user OBJECT
=default user undef

Refers to the user (a User::Identity object) who has this item in one of
his/het collections.  The item may be unrelated to any user.

=warning Unknown option $name

One used option is not defined.

=warning Unknown options @names

More than one option is not defined.

=error Each collectable item requires a name

You have to specify a name for each collected item.  These names need to be
unique within one collection.

=cut

sub new(@)
{   my $class = shift;
    return undef unless @_;       # no empty users.

    unshift @_, 'name' if @_ %2;  # odd-length list: starts with nick

    my %args = @_;
    my $self = (bless {}, $class)->init(\%args);

    if(my @missing = keys %args)
    {   local $" = ', ';
        carp "WARNING: Unknown ".(@missing==1 ? 'option' : 'options')." @missing";
    }

    $self;
}

sub init($)
{   my ($self, $args) = @_;

   unless($self->{UICI_name} = delete $args->{name})
   {   croak "ERROR: Each collectable item requires a name.";
   }

   if(my $user = delete $args->{user})
   {   $self->user($user);
   }

   $self;
}

#-----------------------------------------

=head2 Attributes

=cut

#-----------------------------------------

=method name

Reports the logical name for this location.  This is the specified name or, if
that was not specified, the name of the organization.  This will always return
a valid string.

=cut

sub name()
{   my $self = shift;
    $self->{UICI_name} || $self->{UICI_organization};
}

#-----------------------------------------

=method user [USER]

The user whose address this is.  This is a weak link, which means that
the location object will be removed when the user object is deleted and
no other references to this location object exist.

=cut

sub user(;$)
{   my $self = shift;
    if(@_)
    {   my $user = $self->{UICI_user} = shift;
        weaken($self->{UICI_user}) if defined $user;
    }

    $self->{UICI_user};
}

#-----------------------------------------

1;

