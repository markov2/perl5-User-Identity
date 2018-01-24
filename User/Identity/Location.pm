package User::Identity::Location;
use base 'User::Identity::Collection::Item';

use strict;
use warnings;

use User::Identity;
use Scalar::Util 'weaken';

=head1 NAME

User::Identity::Location - physical location of a person

=head1 SYNOPSIS

 use User::Identity;
 use User::Identity::Location;
 my $me   = User::Identity->new(...);
 my $addr = User::Identity::Location->new(...);
 $me->add(location => $addr);

 # Simpler

 use User::Identity;
 my $me   = User::Indentity->new(...);
 my $addr = $me->add(location => ...);

=head1 DESCRIPTION

The User::Identity::Location object contains the description of a physical
location of a person: home, work, travel.  The locations are collected
by a User::Identity::Collection::Locations object.

Nearly all methods can return undef.  Some methods produce language or
country specific output.

=head1 METHODS

=head2 Initiation

=cut

#-----------------------------------------

=c_method new [NAME], OPTIONS

Create a new location.  You can specify a name as first argument, or
in the OPTION list.  Without a specific name, the organization is used as name.

=option  country STRING
=default country undef

=option  country_code STRING
=default country_code undef

=option  organization STRING
=default organization undef

=option  pobox STRING
=default pobox undef

=option  pobox_pc STRING
=default pobox_pc undef

=option  postal_code STRING
=default postal_code undef

=option  street STRING
=default street undef

=option  state STRING
=default state undef

=option  telephone STRING|ARRAY
=default telephone undef

=option  fax STRING|ARRAY
=default fax undef

=cut

sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args);
    defined $args->{$_} && ($self->{'UIL_'.$_} = delete $args->{$_})
        foreach qw/
city
country
country_code
fax
organization
pobox
pobox_pc
postal_code
state
street
telephone
/;

   $self;
}

#-----------------------------------------

=head2 Attributes

=cut

#-----------------------------------------

=method street

Returns the address of this location.  Since Perl 5.7.3, you can use
unicode in strings, so why not format the address nicely?

=cut

sub street() { shift->{UIL_street} }

#-----------------------------------------

=method postalCode

The postal code is very country dependent.  Also, the location of the
code within the formatted string is country dependent.

=cut

sub postalCode() { shift->{UIL_postal_code} }

#-----------------------------------------

=method pobox

Post Office mail box specification.  Use C<"P.O.Box 314">, not simple C<314>.

=cut

sub pobox() { shift->{UIL_pobox} }

#-----------------------------------------

=method poboxPostalCode

The postal code related to the Post-Office mail box.  Defined by new() option
C<pobox_pc>.

=cut

sub poboxPostalCode() { shift->{UIL_pobox_pc} }

#-----------------------------------------

=method city

The city where the address is located.

=cut

sub city() { shift->{UIL_city} }

#-----------------------------------------

=method state

The state, which is important for some contries but certainly not for
the smaller ones.  Only set this value when you state has to appear on
printed addresses.

=cut

sub state() { shift->{UIL_state} }

#-----------------------------------------

=method country

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

=method countryCode

Each country has an ISO standard abbreviation.  Specify the country or the
country code, and the other will be filled in automatically.

=cut

sub countryCode() { shift->{UIL_country_code} }

#-----------------------------------------

=method organization

The organization (for instance company) which is related to this location.

=cut

sub organization() { shift->{UIL_organization} }

#-----------------------------------------

=method telephone

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

=method fax

One or more fax numbers. Like the telephone() method above.

=cut

sub fax()
{   my $self = shift;

    my $fax = $self->{UIL_fax} or return ();
    my @fax = ref $fax ? @$fax : $fax;
    wantarray ? @fax : $fax[0];
}

#-----------------------------------------

=method fullAddress

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

1;

