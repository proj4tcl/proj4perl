# proj4perl
perl interface to proj.org library

This is a work in progress but already quite usable.  See examples folder.
Manpage in lib/Proj.pod

There is no object oriented versin. Sorry. The C vesion is adquate.  Theoblect
oriented interfaces are a wank.

Installation

On linux  

proj needs to be installed including development library  

perl Makefile.pl  && make &&  make test  && make install  

On Windows  

If the proj library is installed using OSGeo4W, it may just work with Strawberry
perl.  Otherwise check out lib/Proj.pm and edit the sub mswin_conf.  
