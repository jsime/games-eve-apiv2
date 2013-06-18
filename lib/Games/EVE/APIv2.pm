package Games::EVE::APIv2;

=head1 NAME

Games::EVE::APIv2 - Perl interface to CCP's API (version 2) for EVE Online

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This library allows you to easily access EVE Online API endpoints. Instead of having
to deal with CCP's XML response directly, you gain access to much more Perl-esque data
structures. Additionally, the library makes it simpler to access related information,
such as making an initial call to the CharacterSheet and following that up with
Asset information for a pilot, or Corporations for which they're a member (or were in
the past), and so on.

    use Games::EVE::APIv2;

    my $eve = Games::EVE::APIv2->new( key_id => '...', v_code => '...' );

    foreach my $char ($eve->characters) {
        foreach my $corp ($char->corporations) {
            printf("%s %s in %s from %s until %s\n",
                $char->name, (defined $corp->end_date ? 'is' : 'was').
                $corp->name, $corp->start_date,
                (defined $corp->end_date ? $corp->end_date : 'present'));
        }
    }

=cut

use strict;
use warnings FATAL => 'all';

use Games::EVE::APIv2::Base;
use Games::EVE::APIv2::Character;

=head1 EXPORT

This library exports nothing but its constructor.

=head1 SUBROUTINES/METHODS

=head1 INTERNAL SUBROUTINES

The following methods and subroutines are not intended for use by applications,
but are documented here for anyone hoping to chip away at the internal workings
of this library.

=head2 new

Constructor hook.

=cut

sub new {
    my ($self, %opts) = @_;

    die "Must provide key_id and v_code arguments!"
        unless exists $opts{'key_id'} && exists $opts{'v_code'};

    return Games::EVE::APIv2::Base->new( key_id => $opts{'key_id'}, v_code => $opts{'v_code'} );
}

=head1 AUTHOR

Jon Sime, C<< <jonsime at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-eve-apiv2 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-EVE-APIv2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::EVE::APIv2


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-EVE-APIv2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-EVE-APIv2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-EVE-APIv2>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-EVE-APIv2/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Jon Sime.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
