package Mail::Identity;
use base 'User::Identity::Collection::Item';

use strict;
use warnings;

use User::Identity;
use Scalar::Util 'weaken';

=head1 NAME

Mail::Identity - an e-mail role

=head1 SYNOPSIS

 use User::Identity;
 use Mail::Identity;
 my $me   = User::Identity->new(...);
 my $addr = Mail::Identity->new(...);
 $me->add(email => $addr);

 # Simpler

 use User::Identity;
 my $me   = User::Identity->new(...);
 my $addr = $me->add(email => ...);

=head1 DESCRIPTION

The Mail::Identity object contains the description of role played by
a human when sending e-mail.  Most people have more than one role these
days: for instance, a private and a company role with different e-mail
addresses.

An Mail::Identity object combines an e-mail address, user description
("phrase"), a signature, pgp-key, and so on.  All fields are optional,
and some fields are smart.  One such set of data represents one role.
Mail::Identity is therefore the smart cousine of the Mail::Address object.

=head1 METHODS

=head2 Initiation

=cut

#-----------------------------------------

=c_method new [NAME], OPTIONS

=option  comment STRING
=default comment <user's fullname if phrase is different>

=option  domainname STRING
=default domainname <from email or localhost>

=option  email STRING
=default email <username@domainname>

=option  location NAME|OBJECT
=default location <random user's location>

The user's location which relates to this mail identity.  This can be
specified as location name (which will be looked-up when needed), or
as User::Identity::Location object.

=option  organization STRING
=default organization <location's organization>

Usually defined for e-mail addresses which are used by a company or
other organization, but less common for personal addresses.  This
value will be used to fill the C<Organization> header field of messages.

=option  pgp_key STRING|FILENAME
=default pgp_key undef

=option  phrase STRING
=default phrase <user's fullName>

=option  signature STRING
=default signature undef

=option  username STRING
=default username <from email or user's nickname>

=cut

sub init($)
{   my ($self, $args) = @_;

    $self->SUPER::init($args);
    defined $args->{$_} && ($self->{'MI_'.$_} = delete $args->{$_})
        foreach qw/
comment
domainname
email
location
organization
pgp_key
phrase
signature
username
/;

   $self;
}

#-----------------------------------------

=head2 Attributes

=cut

#-----------------------------------------

=method comment

E-mail address -when included in message MIME headers- can contain a comment.
The RFCs advice not to store useful information in these comments, but it
you really want to, you can do it.  The comment defaults to the user's
fuilname if the phrase is not the fullname and there is a user defined.

=cut

sub comment()
{   my $self = shift;
    return $self->{MI_comment} if defined $self->{MI_comment};

    my $user = $self->user     or return undef;
    my $full = $user->fullName or return undef;
    $self->phrase eq $full ? undef : $full;
}

#-----------------------------------------

=method domainname

The domainname is the part of the e-mail address after the C<@>-sign.  When this
is not defined, it can be deducted from the email address (see email()).  If
nothing is known, C<localhost> is returned.

=cut

sub domainname()
{   my $self = shift;
    return $self->{MI_domainname}
        if defined $self->{MI_domainname};

    my $email = $self->{MI_email} || '@localhost';
    $email =~ s/.*?\@// ? $email : undef;
}

#-----------------------------------------

=method email

Returns the e-mail address for this role.  If none was specified, it will
be constructed from the username and domainname.

=cut

sub email()
{   my $self = shift;
    return $self->{MI_email} if defined $self->{MI_email};
    $self->username .'@'. $self->domainname;
}

#-----------------------------------------

=method location

Returns the object which describes to which location this mail address relates.
The location may be used to find the name of the organization involved, or
to create a signature.  If no location is specified, but a user is defined
which has locations, one of those is randomly chosen.

=cut

sub location()
{   my $self      = shift;
    my $location  = $self->{MI_location};

    if(! defined $location)
    {   my $user  = $self->user or return;
        my @locs  = $user->collection('locations');
        $location =  @locs ? $locs[0] : undef;
    }
    elsif(! ref $location)
    {   my $user  = $self->user or return;
        $location = $user->find(location => $location);
    }

    $location;
}

#-----------------------------------------

=method organization

Returns the organization which relates to this e-mail identity.  If not
explicitly specified, it is tried to be found via the location.

=cut

sub organization()
{   my $self = shift;

    return $self->{MI_organization} if defined $self->{MI_organization};

    my $location = $self->location or return;
    $location->organization;
}

#pgp_key
#-----------------------------------------

=method phrase

The phrase is used in an e-mail address to explain who is sending the
message.  This usually is the fullname (the user's fullname is used by
default), description of your function (Webmaster), or any other text.

=cut

sub phrase()
{  my $self = shift;
    return $self->{MI_phrase} if defined $self->{MI_phrase};

    my $user = $self->user     or return undef;
    my $full = $user->fullName or return undef;
    $full;
}

#-----------------------------------------

#signature

#-----------------------------------------

=method username

Returns the username of this e-mail address.  If none is specified, first
it is tried to extract it from the specified e-mail address.  If there is
also no username in the e-mail address, the user identity's nickname is
taken.

=cut

sub username()
{   my $self = shift;
    return $self->{MI_username} if defined $self->{MI_username};
 
    if(my $email = $self->{MI_email})
    {   $email =~ s/\@.*$//;   # strip domain part if present
        return $email;
    }

    my $user = $self->user or return;
    $user->nickname;
}

#-----------------------------------------

1;

