# install toolboxes/bins/ from docker

FROM pyushkevich/itksnap

ENV FLYWHEEL /flywheel/v0
ENV FLYWHEEL_INPUT /flywheel/v0/input
ENV FLYWHEEL_OUTPUT /flywheel/v0/output

WORKDIR ${FLYWHEEL}

RUN mkdir -p ${FLYWHEEL_INPUT}
RUN mkdir -p ${FLYWHEEL_OUTPUT}

RUN apt update


#RUN apt install -y unzip wget imagemagick pandoc libxml2-dev libssl-dev libcurl4-openssl-dev texlive-latex-base bc  texlive-fonts-extra texlive-fonts-recommended 

#RUN apt install -y r-base r-base-dev 

## DO NOT UNDERSTAND
#COPY Rprofile.site /etc/R/
#RUN for i in  rmarkdown xml2 rvest latex2exp kableExtra ggplot2 ggthemes wesanderson extrafont fontcm gridExtra ggpubr tinytex; do R --quiet -e "install.packages('$i')"; done
##########

RUN apt install -y python3 python3-pip jq 
RUN pip3 install flywheel-sdk~=8.0.0
RUN pip3 install requests

# fwgearutils includes some local function scripts 
#COPY fwgearutils/ /usr/local/bin/ 
#########


#COPY priors*.nii.gz T_template0_BrainCerebellum.nii.gz T_template0.nii.gz T_template0_BrainCerebellumProbabilityMask.nii.gzT_template0_BrainCerebellumExtractionMask.nii.gz  run  ${FLYWHEEL}/

COPY priors*.nii.gz T_template0*.nii.gz  run ${FLYWHEEL}/

## revised by Jojo, created by neurodocker, to config ANTS
## cmd: neurodocker generate docker --base=pyushkevich/itksnap --pkg-manager=apt  --ants version=2.2.0 method=binaries

ARG DEBIAN_FRONTEND="noninteractive"

ENV LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    ND_ENTRYPOINT="/neurodocker/startup.sh"
RUN export ND_ENTRYPOINT="/neurodocker/startup.sh" \
    && apt-get update -qq \
    && apt-get install -y -q --no-install-recommends \
           apt-utils \
           bzip2 \
           ca-certificates \
           curl \
           locales \
           unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && update-locale LANG="en_US.UTF-8" \
    && chmod 777 /opt && chmod a+s /opt \
    && mkdir -p /neurodocker \
    && if [ ! -f "$ND_ENTRYPOINT" ]; then \
         echo '#!/usr/bin/env bash' >> "$ND_ENTRYPOINT" \
    &&   echo 'set -e' >> "$ND_ENTRYPOINT" \
    &&   echo 'export USER="${USER:=`whoami`}"' >> "$ND_ENTRYPOINT" \
    &&   echo 'if [ -n "$1" ]; then "$@"; else /usr/bin/env bash; fi' >> "$ND_ENTRYPOINT"; \
    fi \
    && chmod -R 777 /neurodocker && chmod a+s /neurodocker

ENTRYPOINT ["/neurodocker/startup.sh"]

ENV ANTSPATH="/opt/ants-2.2.0" \
    PATH="/opt/ants-2.2.0:$PATH"
RUN echo "Downloading ANTs ..." \
    && mkdir -p /opt/ants-2.2.0 \
    && curl -fsSL --retry 5 https://dl.dropbox.com/s/2f4sui1z6lcgyek/ANTs-Linux-centos5_x86_64-v2.2.0-0740f91.tar.gz \
    | tar -xz -C /opt/ants-2.2.0 --strip-components 1

RUN echo '{ \
    \n  "pkg_manager": "apt", \
    \n  "instructions": [ \
    \n    [ \
    \n      "base", \
    \n      "pyushkevich/itksnap" \
    \n    ], \
    \n    [ \
    \n      "ants", \
    \n      { \
    \n        "version": "2.2.0", \
    \n        "method": "binaries" \
    \n      } \
    \n    ] \
    \n  ] \
    \n}' > /neurodocker/neurodocker_specs.json

# Run the run.sh script on entry.
#ENTRYPOINT ["/flywheel/v0/run"]
