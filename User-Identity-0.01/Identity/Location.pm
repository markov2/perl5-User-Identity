package User::Identity::Location;
our $VERSION = '0.01';

use strict;
use warnings;

use User::Identity;
use Scalar::Util 'weaken';

=head1 NAME

User::Identity::Location - physical location of a person

=head1 SYNOPSIS

 use User::Identity;
 use User::Identity::Location;
 my $me   = User::Indentity->new(...);
 my $addr = User::Indentity::Location->new(...);
 $me->attach($addr);

 # Simpler

 use User::Identity;
 my $me   = User::Indentity->new(...);
 my $addr = $me->Location(...);

=head1 DESCRIPTION

The User::Identity::Location object contains the description of a physical
location of a person: home, work, travel.  Nearly all methods can return
undef.

=head1 METHODS

=over 4

=cut

#-----------------------------------------

=item new [NAME], OPTIONS

Create a new location.  You can specify a name as first argument, or
in the OPTION list.  Without a specific name, the organization is used as name.

Available OPTIONS:

=over 4

=item * country => STRING

=item * country_code => STRING

=item * name => STRING

A simple name for this location, like 'home' or 'work'.

=item * organization => STRING

=item * pobox => STRING

=item * pobox_pc => STRING

=item * postal_code => STRING

=item * street => STRING

=item * state => STRING

=item * telephone => STRING|ARRAY

=item * fax => STRING|ARRAY

=item * user => OBJECT

=back

=cut

sub new(@)
{   my $class = shift;
    return undef unless @_;           # no empty users.

    unshift @_, 'name' if @_ %2;  # odd-length list: starts with nick

    (bless {}, $class)->init( {@_} );
}

sub init($)
{   my ($self, $args) = @_;

    defined $args->{$_} && ($self->{'UIL_'.$_} = delete $args->{$_})
        foreach qw/
city
country
country_code
fax
name
organization
pobox
pobox_pc
postal_code
state
street
telephone
/;

   if(my $user = delete $args->{user})
   {   $self->user($user);
   }

   if(keys %$args)
   {   require Carp;
       local $" = ', ';
       Carp::croak("Unknown option(s): @{ [keys %$args ] }");
   }

   unless(defined $self->name)
   {   require Carp;
       Carp::croak("Each location requires a name");
   }

   $self;
}

#-----------------------------------------

=item name

Reports the logical name for this location.  This is the specified name or, if
that was not specified, the name of the organization.  This will always return
a valid string.

=cut

sub name()
{   my $self = shift;
    $self->{UIL_name} || $self->{UIL_organization};
}

#-----------------------------------------

=item street

Returns the address of this location.  Since Perl 5.7.3, you can use
unicode in strings, so why not format the address nicely?

=cut

sub street() { shift->{UIL_street} }

#-----------------------------------------

=item postalCode

The postal code is very country dependent.  Also, the location of the
code within the formatted string is country dependent.

=cut

sub postalCode() { shift->{UIL_postal_code} }

#-----------------------------------------

=item pobox

Post Office mail box specification.  Use C<"P.O.Box 314">, not simple C<314>.

=cut

sub pobox() { shift->{UIL_pobox} }

#-----------------------------------------

=item poboxPostalCode

The postal code related to the Post-Office mail box.  Defined by new() option
C<pobox_pc>.

=cut

sub poboxPostalCode() { shift->{UIL_pobox_pc} }

#-----------------------------------------

=item city

The city where the address is located.

=cut

sub city() { shift->{UIL_city} }

#-----------------------------------------

=item state

The state, which is important for some contries but certainly not for
the smaller ones.  Only set this value when you state has to appear on
printed addresses.

=cut

sub state() { shift->{UIL_state} }

#-----------------------------------------

=item country

The country where the address is located.  If the name of the country is
not known but a country code is defined, the name will be looked-up
using Geography::Countries (if installed).

=cut

sub country()
{   my $self = shift;

    return $self->{UIL_country}
        if defined $self->{UIL_country};

    my $cc = $self->countryCode or return;

    eval 'require Geography::Countries';
    return if $@;

    scalar Geography::Countries::country($cc);
}

#-----------------------------------------

=item countryCode

Each country has an ISO standard abbreviation.  Specify the country or the
country code, and the other will be filled in automatically.

=cut

sub countryCode() { shift->{UIL_country_code} }

#-----------------------------------------

=item organization

The organization (for instance company) which is related to this location.

=cut

sub organization() { shift->{UIL_organization} }

#-----------------------------------------

=item telephone

One or more phone numbers.  Please use the internation notation, which
starts with C<'+'>, for instance C<+31-26-12131>.  In scalar context,
only the first number is produced.  In list context, all numbers are
presented.

=cut

sub telephone()
{   my $self = shift;

    my $phone = $self->{UIL_telephone} or return ();
    my @phone = ref $phone ? @$phone : $phone;
    wantarray ? @phone : $phone[0];
}
    
#-----------------------------------------

=item fax

One or more fax numbers. Like the telephone() method above.

=cut

sub fax()
{   my $self = shift;

    my $fax = $self->{UIL_fax} or return ();
    my @fax = ref $fax ? @$fax : $fax;
    wantarray ? @fax : $fax[0];
}

#-----------------------------------------

=item user [USER]

The user whose address this is.  This is a weak link, which means that
the location object will be removed when the user object is deleted and
no other references to this location object exist.

=cut

sub user(;$)
{   my $self = shift;
    if(@_)
    {   $self->{UIL_user} = shift;
        weaken($self->{UIL_user});
    }

    $self->{UIL_user};
}

#-----------------------------------------

=item fullAddress

Create an address to put on a postal mailing, in the format as normal in
the country where it must go to.  To be able to achieve that, the country
code must be known.  If the city is not specified or no street or pobox is
given, undef will be returned: an incomplete address.

 print $uil->fullAddress;
 print $user->find(location => 'home')->fullAddress;

=cut

sub fullAddress()
{   my $self = shift;
    my $cc   = $self->countryCode || 'en';

    my ($address, $pc);
    if($address = $self->pobox) { $pc = $self->poboxPostalCode }
    else { $address = $self->street; $pc = $self->postalCode }
    
    my ($org, $city, $state) = @$self{ qw/UIL_organization UIL_city UIL_state/ };
    return unless defined $city && defined $address;

    my $country = $self->country;
    $country
      = defined $country ? "\n$country"
      : defined $cc      ? "\n".uc($cc)
      : '';

    if(defined $org) {$org .= "\n"} else {$org = ''};

    if($cc eq 'nl')
    {   $pc = "$1 ".uc($2)."  " if defined $pc && $pc =~ m/(\d{4})\s*([a-zA-Z]{2})/;
        return "$org$address\n$pc$city$country\n";
    }
    else
    {   $state ||= '';
        return "$org$address\n$city$state$country\n$pc";
    }
}

#-----------------------------------------

=back

=head1 SEE ALSO

User::Identity can be used in combination with Mail::Identity.

=head1 AUTHOR

Mark Overmeer, E<lt>mark@overmeer.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Mark Overmeer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;

