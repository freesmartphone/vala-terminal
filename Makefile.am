NULL =

AUTOMAKE_OPTIONS = subdir-objects

SUBDIRS = \
	data \
	po \
	$(NULL)

INCLUDES = \
	$(VALA_TERMINAL_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

BUILT_SOURCES = src/.stamp

bin_PROGRAMS = vala-terminal

vala_terminal_VALASOURCES = \
	src/terminal.vala \
	src/mainwindow.vala \
	$(NULL)

vala_terminal_SOURCES = \
	$(vala_terminal_VALASOURCES:.vala=.c) \
	$(NULL)

$(BUILT_SOURCES): $(vala_terminal_VALASOURCES)
	$(VALAC) -c --pkg vte --save-temps --basedir $(top_srcdir) $^
	touch $@

vala_terminal_LDADD = \
	$(VALA_TERMINAL_LIBS) \
	$(NULL)

EXTRA_DIST = \
	intltool-extract.in \
	intltool-update.in \
	intltool-merge.in \
	$(vala_terminal_VALASOURCES) \
	$(BUILT_SOURCES) \
	$(NULL)

DISTCLEANFILES = \
	intltool-extract \
	intltool-update \
	intltool-merge \
	po/.intltool-merge-cache \
	$(NULL)

MAINTAINERCLEANFILES = aclocal.m4 compile config.guess config.sub \
                       configure depcomp install-sh ltmain.sh     \
                       Makefile.in missing config.h.in            \
                       intltool-extract \
                       intltool-merge \
                       intltool-update \
                       mkinstalldirs src/*.c
