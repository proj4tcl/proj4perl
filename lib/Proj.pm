# vim:ft=c:sts=4:sw=4:et

package Proj;

$VERSION = '0.01';
use base 'Exporter';
use strict;

use Inline C => Config => LIBS => '-lproj';
use Inline C => 'DATA',
    version => '0.01',
    name => 'Proj';

# The following Inline->init() call is optional - see below for more info.
#Inline->init();
1;

__DATA__

=pod

=head1 NAME

Proj - perl interface to proj.org projection library.

=head1 VERSION

This documentation refers to Proj version 0.01

=head1 SYNOPSIS

    use Proj;

    say Proj::version();

    my $src = "EPSG:4326";
    my $tgt = "+proj=utm +zone=32 +datum=WGS84";
    my $p = Proj::crs2crs($src,$tgt);
    my $q = Proj::norm($p);
    say Proj::definition($p);
    say Proj::definition($q);

    my $a = [12, 55];
    my $b = Proj::fwd($q, $a);
    printf "\neasting: %.3f, northing: %.3f\n", @$b;

    my $c = Proj::inv($q, $b);
    printf "\nlongitude: %g, latitude: %g\n", @$c;

=head1 DESCRIPTION

Perl binding to L<proj|http://proj.org> library.

=head1 SUBROUTINES

=over

=item B<Proj::version>

=back

Returns the version of the current instance of proj.  This is the version field from the PJ_INFO structure returned from the proj_info function.

See L<https://proj.org/development/reference/functions.html#c.proj_info> and L<https://proj.org/development/reference/datatypes.html#c.PJ_INFO>

=over

=item B<Proj::create> I<projstring>

=back

Returns a transformation object from a projstring etc.

See L<https://proj.org/development/reference/functions.html#c.proj_create>








=head1 DEPENDENCIES

Requires proj libraries installed.

eg Debian - apt install proj-bin proj-data libproj-dev

=head1 SEE ALSO

projinfo(1), projsync(1)

=head1 BUGS AND LIMITATIONS

Ignores threading context in all functions. 

There are no known bugs in this module.
Patches are welcome.

=head1 AUTHOR

Peter Dean

=head1 LICENCE AND COPYRIGHT

Copyright 2024 Peter Dean

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

__C__

#include <proj.h>

char* version() {
    PJ_INFO info = proj_info();
    return(info.version);
}
    
char* definition(IV p) {
    PJ *P = INT2PTR(PJ* , p);
    PJ_PROJ_INFO info = proj_pj_info(P);
    return(info.definition);
}

IV create(char *src) {
    PJ *P = proj_create(0,src);
    return(PTR2IV(P));
}

IV crs2crs(char *src, char* tgt) {
    PJ *P = proj_create_crs_to_crs(0,src,tgt,0);
    return(PTR2IV(P));
}

IV norm(IV p) {
    PJ *P = INT2PTR(PJ* , p);
    PJ *Q = proj_normalize_for_visualization(0, P);
    return(PTR2IV(Q));
}

SV* trans(IV p, int dirn, SV* coord_ref) {
    int n;
    if ((!SvROK(coord_ref)) || (SvTYPE(SvRV(coord_ref)) != SVt_PVAV)
        || ((n = av_len((AV *)SvRV(coord_ref))) < 0)) {
        return &PL_sv_undef;
    }
    n = n>3 ? 3 : n;    
    AV* coord = (AV*) SvRV(coord_ref);
    PJ *P = INT2PTR(PJ* , p);
    PJ_COORD a = {{0.0, 0.0, 0.0, 0.0}};
    for (int i=0; i<=n; i++) {
        a.v[i] = SvNV(*av_fetch(coord, i, 0)); 
    }
    PJ_COORD b = proj_trans(P, dirn, a);
    AV* res = newAV();
    for (int i=0; i<=n; i++) {
        av_push(res, newSVnv(b.v[i]));
    }
    return newRV_noinc((SV*) res);
}

SV* fwd(IV p, SV* coord_ref) {
    return(trans(p,1,coord_ref));
}

SV* inv(IV p, SV* coord_ref) {
    return(trans(p,-1,coord_ref));
}
