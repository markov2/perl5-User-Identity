package Mail::Identity;
use base 'User::Identity::Item';

use strict;
use warnings;

use User::Identity;
use Scalar::Util 'weaken';

=chapter NAME

Mail::Identity - an e-mail role

=chapter SYNOPSIS

 use M<User::Identity>;
 use Mail::Identity;
 my $me   = User::Identity->new(...);
 my $addr = Mail::Identity->new(address => 'x@y');
 $me->add(email => $addr);

 # Simpler

 use User::Identity;
 my $me   = User::Identity->new(...);
 my $addr = $me->add(email => 'x@y');
 my $addr = $me->add( email => 'home'
                    , address => 'x@y');

 # Conversion
 my $ma   = Mail::Address->new(...);
 my $mi   = Mail::Identity->coerce($ma);

=chapter DESCRIPTION

The C<Mail::Identity> object contains the description of role played by
a human when sending e-mail.  Most people have more than one role these
days: for instance, a private and a company role with different e-mail
addresses.

An C<Mail::Identity> object combines an e-mail address, user description
("phrase"), a signature, pgp-key, and so on.  All fields are optional,
and some fields are smart.  One such set of data represents one role.
C<Mail::Identity> is therefore the smart cousine of the M<Mail::Address>
object.

=chapter METHODS

=cut

sub type() { "email" }

=c_method new [NAME], OPTIONS

=default name    <phrase or user's fullName>

=option  charset STRING
=default charset <user's charset>

=option  comment STRING
=default comment <user's fullname if phrase is different>

=option  domain STRING
=default domain <from email or localhost>

=option  address STRING
=default address <username@domain or name>

The e-mail address is constructed from the username/domain, but
when both do not exist, the name is taken.

=option  language STRING
=default language <from user>

=option  location NAME|OBJECT
=default location <random user's location>

The user's location which relates to this mail identity.  This can be
specified as location name (which will be looked-up when needed), or
as M<User::Identity::Location> object.

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
=default username <from address or user's nickname>

=cut

sub init($)
{   my ($self, $args) = @_;

    $args->{name} ||= '-x-';

    $self->SUPER::init($args);

    exists $args->{$_} && ($self->{'MI_'.$_} = delete $args->{$_})
        foreach qw/address charset comment domain language
                   location organization pgp_key phrase signature
                   username/;

   $self->{UII_name} = $self->phrase || $self->address
      if $self->{UII_name} eq '-x-';

   $self;
}

=section Constructors

=method from OBJECT

Convert an OBJECT into a C<Mail::Identity>.  On the moment, you can
specify M<Mail::Address> and M<User::Identity> objects.  In the
former case, a new C<Mail::Identity> is created containing the same
information.  In the latter, the first address of the user is picked
and returned.

=cut

sub from($)
{   my ($class, $other) = @_;
    return $other if $other->isa(__PACKAGE__);

    if($other->isa('Mail::Address'))
    {   return $class->new
          ( phrase  => $other->phrase
          , address => $other->address
          , comment => $other->comment
          , @_);
    }

    if($other->isa('User::Identity'))
    {   my $emails = $other->collection('emails') or next;
        my @roles  = $emails->roles or return ();
        return $roles[0];      # first Mail::Identity
    }

    undef;
}

=section Attributes

=method comment [STRING]
E-mail address -when included in message MIME headers- can contain a comment.
The RFCs advice not to store useful information in these comments, but it
you really want to, you can do it.  The comment defaults to the user's
fullname if the phrase is not the fullname and there is a user defined.

Comments will be enclosed in parenthesis when used. Parenthesis (matching)
or non-matching) which are already in the string will carefully escaped
when needed.  You do not need to worry.

=cut

sub comment($)
{   my $self = shift;
    return $self->{MI_comment} = shift if @_;
    return $self->{MI_comment} if defined $self->{MI_comment};

    my $user = $self->user     or return undef;
    my $full = $user->fullName or return undef;
    $self->phrase eq $full ? undef : $full;
}

=method charset
Returns the character set used in comment and phrase.  When set to
C<undef>, the strings (are already encoded to) contain only ASCII
characters.  This defaults to the value of the user's charset, if a user
is defined.

=cut

sub charset()
{   my $self = shift;
    return $self->{MI_charset} if defined $self->{MI_charset};

    my $user = $self->user     or return undef;
    $user->charset;
}

=method language
Returns the language which is used for the description fields of this
e-mail address, which defaults to the user's language.

=cut

sub language()
{   my $self = shift;
   
    return $self->{MI_language} if defined $self->{MI_language};

    my $user = $self->user     or return undef;
    $user->language;
}

=method domain
The domain is the part of the e-mail address after the C<@>-sign.
When this is not defined, it can be deducted from the email address
(see M<address()>).  If nothing is known, C<localhost> is returned.

=cut

sub domain()
{   my $self = shift;
    return $self->{MI_domain}
        if defined $self->{MI_domain};

    my $address = $self->{MI_address} or return 'localhost';
    $address =~ s/.*?\@// ? $address : undef;
}

=method address
Returns the e-mail address for this role.  If none was specified, it will
be constructed from the username and domain.  If those are not present
as well, then the M<name()> is used when it contains a C<@>, else the
user's nickname is taken.

=cut

sub address()
{   my $self = shift;
    return $self->{MI_address} if defined $self->{MI_address};

    return $self->username .'@'. $self->domain
        if $self->{MI_username} || $self->{MI_domain};

    my $name = $self->name;
    return $name if index($name, '@') >= 0;

    my $user = $self->user;
    defined $user ? $user->nickname : $name;
}

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
=method phrase
The phrase is used in an e-mail address to explain who is sending the
message.  This usually is the fullname (the user's fullname is used by
default), description of your function (Webmaster), or any other text.

When an email string is produced, the phase will be quoted if needed.
Quotes which are within the string will automatically be escaped, so
you do no need to worry: input cannot break the outcome!

=cut

sub phrase()
{  my $self = shift;
    return $self->{MI_phrase} if defined $self->{MI_phrase};
    my $user = $self->user     or return undef;
    my $full = $user->fullName or return undef;
    $full;
}

#signature

=method username
Returns the username of this e-mail address.  If none is specified, first
it is tried to extract it from the specified e-mail address.  If there is
also no username in the e-mail address, the user identity's nickname is
taken.

=cut

sub username()
{   my $self = shift;
    return $self->{MI_username} if defined $self->{MI_username};
 
    if(my $address = $self->{MI_address})
    {   $address =~ s/\@.*$//;   # strip domain part if present
        return $address;
    }

    my $user = $self->user or return;
    $user->nickname;
}

1;

