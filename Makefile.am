## Process this file with automake to produce Makefile.in

AUTOMAKE_OPTIONS =
bin_PROGRAMS = virasoro
libexec_PROGRAMS = $(VWSTP)
EXTRA_DIST = README.md LICENSE.txt
EXTRA_PROGRAMS = vwstp
## LDADD = $(AM_LDADD) @staticlibs@
LDADD = $(AM_LDADD)
IDIR = include/
virasoro_SOURCES = main.cpp virasoro.cpp runfile.cpp access.cpp $(IDIR)virasoro.h $(IDIR)runfile.h $(IDIR)hmn.h $(IDIR)cpqmn.h $(IDIR)access.h $(IDIR)mpreal.h $(IDIR)mpcomplex.h
virasoro_LDADD = $(LDADD)
vwstp_SOURCES = vwstp.cpp virasoro.cpp runfile.cpp access.cpp vwstp.tm $(IDIR)virasoro.h $(IDIR)runfile.h $(IDIR)hmn.h $(IDIR)cpqmn.h $(IDIR)access.h $(IDIR)mpreal.h $(IDIR)mpcomplex.h
nodist_vwstp_SOURCES = vwstptm.c
vwstp_CFLAGS = $(AM_CFLAGS) @wstpflags@
vwstp_CXXFLAGS = $(AM_CXXFLAGS) @wstpflags@
vwstp_CPPFLAGS = -DHAVE_WSTP
vwstp_LDADD = $(LDADD) @wstpextralibs@
PKGDIR = @pkgdatadir@

if MAKE_VWSTP
dist_pkgdata_DATA = Virasoro.m
BUILT_SOURCES = vwstptm.c
CLEANFILES = vwstptm.c
vwstptm.c: vwstp.tm
	$(WSPREP) $? -o $@

install-data-hook:
	chown $(USERNAME) $(PKGDIR)/Virasoro.m
endif
