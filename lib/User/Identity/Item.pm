package User::Identity::Item;

use strict;
use warnings;

use Scalar::Util qw/weaken/;
use Carp;

=chapter NAME

User::Identity::Item - general base class for User::Identity

=chapter SYNOPSIS

=chapter DESCRIPTION

The C<User::Identity::Item> base class is extended into useful modules: it
has no use by its own.

=chapter METHODS

=section Initiation

=c_method new [NAME], OPTIONS

=requires name STRING

A simple name for this location, like C<'home'> or C<'work'>.  Anything is
permitted as name.

=option  description STRING
=default description undef

Free format description on the collected item.

=warning Unknown option $name for a $class

One used option is not defined.  Check the manual page of the class to
see which options are accepted.

=warning Unknown options @names for a $class

More than one option is not defined.

=error Each item requires a name

You have to specify a name for each item.  These names need to be
unique within one collection, but feel free to give the same name
to an e-mail address and a location.

=cut

sub new(@)
{   my $class = shift;
    return undef unless @_;       # no empty users.

    unshift @_, 'name' if @_ %2;  # odd-length list: starts with nick

    my %args = @_;
    my $self = (bless {}, $class)->init(\%args);

    if(my @missing = keys %args)
    {   local $" = '", "';
        carp "WARNING: Unknown ".(@missing==1? 'option' : 'options' )
           . " \"@missing\" for a $class";
    }

    $self;
}

sub init($)
{   my ($self, $args) = @_;

   unless(defined($self->{UII_name} = delete $args->{name}))
   {   croak "ERROR: Each item requires a name";
   }

   $self->{UII_description} = delete $args->{description};
   $self;
}

#-----------------------------------------

=section Attributes

=method name

The name of this item.  Names are unique within a collection... a second
object with the same name within any collection will destroy the already
existing object with that name.

=cut

sub name() { shift->{UII_name} }

#-----------------------------------------

=method description

Free format description on this item.  Please do not add
any significance to the content of this field: if you are in need
for an extra attribute, please contact the author of the module to
implement it, or extend the object to suit your needs.

=cut

sub description() {shift->{UII_description}}

#-----------------------------------------

1;

