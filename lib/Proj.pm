# vim:ft=c:sts=4:sw=4:et

package Proj;

$VERSION = '0.01';
use base 'Exporter';
use strict;

BEGIN { 
    sub linux_conf {(LIBS => '-lproj')} 

    sub mswin_conf {
        (myextlib => 'C:/OSGeo4W/bin/proj_9_4.dll',
         inc      => '-IC:/OSGeo4W/include');
    }

    for ($^O) {
        *my_conf = do {
            /linux/ && \&linux_conf ||
            /MSWin32/ && \&mswin_conf ||
            die "unknown OS $^O, bailing out";
        }
    }
}

use Inline C => Config => my_conf ;

use Inline C => 'DATA',
    version => '0.01',
    name => 'Proj';

1;

__DATA__
__C__

#include <proj.h>

char* version() {
    PJ_INFO info = proj_info();
    return(info.version);
}
    
char* definition(SV* p) {
    PJ *P = ((PJ*)SvIV(SvRV(p)));
    PJ_PROJ_INFO info = proj_pj_info(P);
    return(info.definition);
}

SV* create(char *src) {
    PJ *P = proj_create(0,src);
    SV* obj = newSViv((IV)P);
    SV* obj_ref = newRV_noinc(obj);
    sv_bless(obj_ref, gv_stashpv("Proj", GV_ADD));
    SvREADONLY_on(obj);
    return obj_ref;
}

SV* crs2crs(char *src, char* tgt) {
    PJ *P = proj_create_crs_to_crs(0,src,tgt,0);
    SV* obj = newSViv((IV)P);
    SV* obj_ref = newRV_noinc(obj);
    sv_bless(obj_ref, gv_stashpv("Proj", GV_ADD));
    SvREADONLY_on(obj);
    return obj_ref;
}

SV* norm(SV* p) {
    PJ *P = ((PJ*)SvIV(SvRV(p)));
    PJ *Q = proj_normalize_for_visualization(0, P);
    SV* obj = newSViv((IV)Q);
    SV* obj_ref = newRV_noinc(obj);
    sv_bless(obj_ref, gv_stashpv("Proj", GV_ADD));
    SvREADONLY_on(obj);
    return obj_ref;
}

SV* trans(SV* p, int dirn, SV* coord_ref) {
    int n;
    if ((!SvROK(coord_ref)) || (SvTYPE(SvRV(coord_ref)) != SVt_PVAV)
        || ((n = av_len((AV *)SvRV(coord_ref))) < 0)) {
        return &PL_sv_undef;
    }
    n = n>3 ? 3 : n;    
    AV* coord = (AV*) SvRV(coord_ref);
    PJ *P = ((PJ*)SvIV(SvRV(p)));
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

SV* fwd(SV* p, SV* coord_ref) {
    return(trans(p,1,coord_ref));
}

SV* inv(SV* p, SV* coord_ref) {
    return(trans(p,-1,coord_ref));
}

void DESTROY(SV* obj) {
    PJ* P = (PJ*)SvIV(SvRV(obj));
    proj_destroy(P);
}
