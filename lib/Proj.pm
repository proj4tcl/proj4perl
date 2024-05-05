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

sub new {
    my $class = shift;
    my $n = @_;
    my $pj;

    if ($n == 1) {
        my $src = shift;
        $pj = $class->create($src);
    }
    elsif ($n == 2) {
        my ($src, $tgt) = @_;
        $pj = $class->crs2crs($src,$tgt);
    }
    return $pj;
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

SV* create(const char *class, const char *src) {
    PJ *P = proj_create(0,src);
    SV *obj = newSV(0);
    sv_setref_pv(obj, class, (void *)P);
    return obj;
}

SV* crs2crs(const char *class, const char *src, char* tgt) {
    PJ *P = proj_create_crs_to_crs(0,src,tgt,0);
    SV *obj = newSV(0);
    sv_setref_pv(obj, class, (void *)P);
    return obj;
}

SV* norm(SV* p) {
    PJ *P = ((PJ*)SvIV(SvRV(p)));
    PJ *Q = proj_normalize_for_visualization(0, P);
    SV *obj = newSV(0);
    sv_setref_pv(obj, "Proj", (void *)Q);
    return obj;
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
