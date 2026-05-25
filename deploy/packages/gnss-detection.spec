Name: gnss-detection
Version: 0.1.0
Release: 1%{?dist}
Summary: GNSS Spoofing/Jamming Early Warning System
License: MIT
URL: https://github.com/quantumworld-dpdns-io/gnss-spoofing-jamming-early-warning
Source0: %{name}-%{version}.tar.gz
BuildRequires: rust >= 1.85, python3 >= 3.12
Requires: libc >= 2.31, python3 >= 3.12, openssl >= 3.0

%description
Distributed detection network aggregating GNSS signals to generate
spoofing heatmaps using classical and quantum-enhanced detection algorithms.

%prep
%setup -q

%build
make build

%install
mkdir -p %{buildroot}%{_bindir}
cp target/release/mcp-server %{buildroot}%{_bindir}/gnss-mcp-server
cp bin/api-gateway %{buildroot}%{_bindir}/gnss-api-gateway
cp -r src/detection-engine/python/quantum %{buildroot}%{python3_sitelib}/quantum
cp -r src/detection-engine/python/gnss_core %{buildroot}%{python3_sitelib}/gnss_core

%files
%{_bindir}/gnss-mcp-server
%{_bindir}/gnss-api-gateway
%{python3_sitelib}/quantum/
%{python3_sitelib}/gnss_core/

%post
if command -v systemctl &> /dev/null; then
    systemctl daemon-reload
fi

%changelog
* Mon May 25 2026 quantumworld-dpdns-io <admin@quantumworld.io>
- Initial RPM release
