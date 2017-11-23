NAME=java-1.9.0-oracle
MAJOR_VERSION=9.0.1
MINOR_VERSION=11
VERSION=$(shell echo $(MAJOR_VERSION))
ITERATION=1.lru
PREFIX=/opt/java
LICENSE="BSL"
VENDOR="Oracle"
MAINTAINER="Ryan Parman"
DESCRIPTION="The Oracle Java Runtime Environment."
URL=https://oracle.com/java/
RHEL=$(shell rpm -q --queryformat '%{VERSION}' centos-release)

define AFTER_INSTALL
update-alternatives --install /usr/bin/java java /opt/java/latest/jre/bin/java 100
update-alternatives --install /usr/bin/javac javac /opt/java/latest/jre/bin/javac 100
echo "source /opt/java/exports" >> /etc/bashrc
source /etc/bashrc
endef

define AFTER_REMOVE
update-alternatives --remove java /opt/java/latest/jre/bin/java
update-alternatives --remove javac /opt/java/latest/jre/bin/javac
endef

export AFTER_INSTALL
export AFTER_REMOVE

.PHONY: package
package: clean
	@ echo "NAME:          $(NAME)"
	@ echo "MAJOR_VERSION: $(MAJOR_VERSION)"
	@ echo "MINOR_VERSION: $(MINOR_VERSION)"
	@ echo "VERSION:       $(VERSION)"
	@ echo "ITERATION:     $(ITERATION)"
	@ echo "PREFIX:        $(PREFIX)"
	@ echo "LICENSE:       $(LICENSE)"
	@ echo "VENDOR:        $(VENDOR)"
	@ echo "MAINTAINER:    $(MAINTAINER)"
	@ echo "DESCRIPTION:   $(DESCRIPTION)"
	@ echo "URL:           $(URL)"
	@ echo "RHEL:          $(RHEL)"
	@ echo " "

	mkdir -p /tmp/installdir-$(NAME)-$(VERSION)

	# Download JDK
	wget -O jdk-$(VERSION)-linux-x64.tar.gz \
		--no-cookies \
		--no-check-certificate \
		--header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
		"http://download.oracle.com/otn-pub/java/jdk/$(MAJOR_VERSION)+$(MINOR_VERSION)/jdk-$(VERSION)_linux-x64_bin.tar.gz" \
	;

	# Unpack JDK
	tar -zxf jdk-$(VERSION)-linux-x64.tar.gz -C /tmp/installdir-$(NAME)-$(VERSION)
	cd /tmp/installdir-$(NAME)-$(VERSION) && ln -s jdk1.9.0_$(MINOR_VERSION) latest
	cp exports /tmp/installdir-$(NAME)-$(VERSION)/exports
	chmod -f 0644 /tmp/installdir-$(NAME)-$(VERSION)/exports

	echo "$$AFTER_INSTALL" > after-install.sh
	echo "$$AFTER_REMOVE" > after-remove.sh

	# Main package
	fpm \
		-s dir \
		-t rpm \
		-n $(NAME) \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--iteration $(ITERATION) \
		--epoch 1 \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix $(PREFIX) \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG.txt \
		--rpm-auto-add-directories \
		--template-scripts \
		--after-install after-install.sh \
		--after-remove after-remove.sh \
		jdk1.9.0_$(MINOR_VERSION) \
		latest \
		exports \
	;

	mv *.rpm /vagrant/repo

.PHONY: clean
clean:
	rm -Rf java*.rpm jdk* after*.sh
	rm -Rf /tmp/installdir*
