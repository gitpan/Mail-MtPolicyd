%define module_name Mail-MtPolicyd

Name: mtpolicyd
Version: 1.12
Release: %(date +%Y%m%d)%{dist}
Summary: the Mailteam policy daemon for postfix

Group: Applications/CPAN
License: restricted
Vendor: Markus Benning <ich@markusbenning.de>
Packager: Markus Benning <ich@markusbenning.de>

BuildArch: noarch
BuildRoot: /var/tmp/buildroot-%{name}-%{version}

Source0: %{module_name}-%{version}.tar.gz

#AutoProv: 0

# only require core dependencies
AutoReq: 0
Requires: perl(Cache::Memcached), perl(Config::General), perl(Moose), perl(Tie::IxHash), perl(Time::HiRes), perl(DBI), perl(Mail::RBL), perl(JSON)
BuildRequires: perl, perl(ExtUtils::MakeMaker)

%description
the Mailteam policy daemon for postfix

%prep
rm -rf $RPM_BUILD_ROOT
%setup -q -n %{module_name}-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
if [ -d "$RPM_BUILD_ROOT" ] ; then
        rm -rf $RPM_BUILD_ROOT
fi
make install DESTDIR=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -type f -name perllocal.pod -exec rm -f {} \;
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

mkdir -p "$RPM_BUILD_ROOT/%{_sysconfdir}/rc.d/init.d"
mkdir -p "$RPM_BUILD_ROOT/%{_sysconfdir}/mtpolicyd"
mkdir -p "$RPM_BUILD_ROOT/var/run/mtpolicyd"

install -m755 rpm/mtpolicyd.init-redhat "$RPM_BUILD_ROOT/%{_sysconfdir}/rc.d/init.d/mtpolicyd"
install -m640 etc/mtpolicyd.conf "$RPM_BUILD_ROOT/%{_sysconfdir}/mtpolicyd/mtpolicyd.conf"

%{_fixperms} $RPM_BUILD_ROOT/*

%clean
if [ "$RPM_BUILD_ROOT" = "" -o "$RPM_BUILD_ROOT" = "/" ]; then
  RPM_BUILD_ROOT=/var/tmp/rpm-build-root
  export RPM_BUILD_ROOT
fi
rm -rf $RPM_BUILD_ROOT

%pre
( /usr/sbin/useradd \
	-c 'mtpolicyd daemon' \
	-d /var/run/mtpolicyd \
	-M -r \
	 -s /bin/false \
	mtpolicyd 2>&1 >/dev/null || exit 0 )

%post
/sbin/chkconfig --add mtpolicyd

%preun
if [ "$1" = 0 ]; then
	/sbin/service mtpolicyd stop &>/dev/null
	/sbin/chkconfig --del mtpolicyd
fi

%files
%defattr(-,root,root)
%doc README
%attr(755,root,root) %{_bindir}/mtpolicyd
%attr(755,root,root) %{_bindir}/policyd-client
%attr(755,root,root) %{_sysconfdir}/rc.d/init.d/mtpolicyd
%attr(640,root,mtpolicyd) %config(noreplace) %{_sysconfdir}/mtpolicyd/mtpolicyd.conf
%attr(750,mtpolicyd,mtpolicyd) %dir /var/run/mtpolicyd
%{perl_vendorlib}
%{_mandir}/man1/*
%{_mandir}/man3/*
