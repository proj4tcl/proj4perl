
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
