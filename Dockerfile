FROM centos:centos7
LABEL maintainer='Jason White <git@fastpbx.com>'
ENV build_date 2021-02-01

ENV ASTERISK_VERSION=18.2 \
    BCG729_VERSION=1.0.4 \
    DONGLE_VERSION=20200610 \
    G72X_CPUHOST=penryn \
    G72X_VERSION=0.1 \
    MONGODB_VERSION=4.2 \
    PHP_VERSION=5.6 \
    SPANDSP_VERSION=20180108 \
    RTP_START=18000 \
    RTP_FINISH=20000

# Copy in default configs
# COPY http.conf /etc/asterisk/http.conf
RUN yum update -y \
    && yum install -y \
            epel-release \
            git \
            kernel-headers \
            patch \
            libedit-devel \
            file \
            wget \
            gcc \
            gcc-c++ \
            cpp \
            ncurses \
            ncurses-devel \
            libxml2 \
            libxml2-devel \
            sqlite \
            sqlite-devel \
            openssl-devel \
            newt-devel \
            kernel-devel \
            libuuid-devel \
            net-snmp-devel \
            xinetd \
            tar \
            make \
            bzip2 \
            pjproject-devel \
            libsrtp-devel \
            gsm-devel \
            speex-devel \
            libtiff-devel \
            gettext \
            autoconf \
            automake \
            libtool \
    && yum clean all \
    # Download And Build SPANDSP
    && mkdir -p /usr/src/spandsp \
    && curl -kL http://sources.buildroot.net/spandsp/spandsp-${SPANDSP_VERSION}.tar.gz | tar xvfz - --strip 1 -C /usr/src/spandsp \
    && cd /usr/src/spandsp \
    && ./configure --prefix=/usr \
    && make \
    && make install \
    # Download asterisk.
    && cd /usr/src \
    && git clone -b 18.2 --depth 1 https://github.com/asterisk/asterisk.git \
    && cd /usr/src/asterisk \
    # Configure
    && ./configure \
            --libdir=/usr/lib64 \
            --with-jansson-bundled \
                        1> /dev/null \
    # Remove the native build option
    # from: https://wiki.asterisk.org/wiki/display/AST/Building+and+Installing+Asterisk
    && make -j$(nproc) menuselect.makeopts \
    && menuselect/menuselect \
                  --disable BUILD_NATIVE \
                  --enable cdr_csv \
                  --enable res_snmp \
                  --enable res_http_websocket \
                  --enable res_hep_pjsip \
                  --enable res_hep_rtcp \
                  --enable res_fax_spandsp \
                  --enable res_sorcery_astdb \
                  --enable res_sorcery_config \
                  --enable res_sorcery_memory \
                  --enable res_sorcery_memory_cache \
                  --enable res_pjproject \
                  --enable res_rtp_asterisk \
                  --enable res_ari \
                  --enable res_ari_applications \
                  --enable res_ari_asterisk \
                  --enable res_ari_bridges \
                  --enable res_ari_channels \
                  --enable res_ari_device_states \
                  --enable res_ari_endpoints \
                  --enable res_ari_events \
                  --enable res_ari_mailboxes \
                  --enable res_ari_model \
                  --enable res_ari_playbacks \
                  --enable res_ari_recordings \
                  --enable res_ari_sounds \
                  --enable res_pjsip \
                  --enable res_pjsip_acl \
                  --enable res_pjsip_authenticator_digest \
                  --enable res_pjsip_caller_id \
                  --enable res_pjsip_config_wizard \
                  --enable res_pjsip_dialog_info_body_generator \
                  --enable res_pjsip_diversion \
                  --enable res_pjsip_dlg_options \
                  --enable res_pjsip_dtmf_info \
                  --enable res_pjsip_empty_info \
                  --enable res_pjsip_endpoint_identifier_anonymous \
                  --enable res_pjsip_endpoint_identifier_ip \
                  --enable res_pjsip_endpoint_identifier_user \
                  --enable res_pjsip_exten_state \
                  --enable res_pjsip_header_funcs \
                  --enable res_pjsip_logger \
                  --enable res_pjsip_messaging \
                  --enable res_pjsip_mwi \
                  --enable res_pjsip_mwi_body_generator \
                  --enable res_pjsip_nat \
                  --enable res_pjsip_notify \
                  --enable res_pjsip_one_touch_record_info \
                  --enable res_pjsip_outbound_authenticator_digest \
                  --enable res_pjsip_outbound_publish \
                  --enable res_pjsip_outbound_registration \
                  --enable res_pjsip_path \
                  --enable res_pjsip_pidf_body_generator \
                  --enable res_pjsip_publish_asterisk \
                  --enable res_pjsip_pubsub \
                  --enable res_pjsip_refer \
                  --enable res_pjsip_registrar \
                  --enable res_pjsip_registrar_expire \
                  --enable res_pjsip_rfc3326 \
                  --enable res_pjsip_sdp_rtp \
                  --enable res_pjsip_send_to_voicemail \
                  --enable res_pjsip_session \
                  --enable res_pjsip_sips_contact \
                  --enable res_pjsip_t38 \
                  --enable res_pjsip_transport_management \
                  --enable res_pjsip_transport_websocket \
                  --enable res_pjsip_xpidf_body_generator \
                  --enable res_stasis \
                  --enable res_stasis_answer \
                  --enable res_stasis_device_state \
                  --enable res_stasis_mailbox \
                  --enable res_stasis_playback \
                  --enable res_stasis_recording \
                  --enable res_stasis_snoop \
                  --enable res_stasis_test \
                  --enable res_statsd \
                  --enable res_timing_timerfd \
          menuselect.makeopts \
    # ./buildmenu.sh app_stasis res_stasis cdr_syslog chan_bridge_media chan_rtp chan_pjsip codec_a_mu codec_ulaw pbx_config

    # Continue with a standard make.
    && make -j$(nproc) 1> /dev/null \
    && make -j$(nproc) install 1> /dev/null \
    && make -j$(nproc) samples 1> /dev/null && \
#    && make dist-clean && \
    #### Add G729 codecs
	git clone https://github.com/BelledonneCommunications/bcg729 /usr/src/bcg729 && \
    cd /usr/src/bcg729 && \
    git checkout tags/$BCG729_VERSION && \
    ./autogen.sh && \
    ./configure --prefix=/usr --libdir=/lib64 && \
    make && \
    make install && \
	mkdir -p /usr/src/asterisk-g72x && \
    curl https://bitbucket.org/arkadi/asterisk-g72x/get/master.tar.gz | tar xvfz - --strip 1 -C /usr/src/asterisk-g72x && \
    cd /usr/src/asterisk-g72x && \
    ./autogen.sh && \
    ./configure --prefix=/usr --libdir=/lib64 --with-asterisk-includes=/usr/src/asterisk/include --with-bcg729 --enable-$G72X_CPUHOST && \
    make && \
    make install \
    # Update max number of open files.
    && sed -i -e 's/# MAXFILES=/MAXFILES=/' /usr/sbin/safe_asterisk \
    # This is weird huh? I'd shell into the container and get errors about en_US.UTF-8 file not found
    # found @ https://github.com/CentOS/sig-cloud-instance-images/issues/71
    && localedef -i en_US -f UTF-8 en_US.UTF-8 \
    # Create and configure asterisk for running asterisk user.
    && useradd -m asterisk -s /sbin/nologin \
    && chown -R asterisk:asterisk /var/run/asterisk \
                                  /etc/asterisk/ \
                                  /var/lib/asterisk \
                                  /var/log/asterisk \
                                  /var/spool/asterisk \
                                  /usr/lib64/asterisk/ \
    && rm -rf /usr/src/* \
    && rm -rf /tmp/*

# And run asterisk in the foreground.
USER asterisk
CMD /usr/sbin/asterisk -f

## TODO: look what's wrong here: 'res_pjsip_registrar_expire' not found
                                #'res_pjsip_transport_management' not found