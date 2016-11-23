FROM ubuntu:14.04.4
MAINTAINER cannin

##### UBUNTU
# Update Ubuntu and add extra repositories
RUN apt-get -y update
#RUN apt-get -y install software-properties-common
RUN apt-get -y install apt-transport-https

RUN echo 'deb https://cran.rstudio.com/bin/linux/ubuntu trusty/' >> /etc/apt/sources.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
RUN add-apt-repository -y ppa:openjdk-r/ppa

RUN apt-get -y update && apt-get -y upgrade

# Install basic commands
RUN apt-get -y install links nano htop

ENV R_BASE_VERSION 3.2.3-6trusty0

#RUN apt-cache policy r-cran-matrix

# Necessary for getting a specific R version (get oldest working packages by manual date comparison) and set main repository
RUN apt-get install -y --no-install-recommends \
  littler \
  r-cran-littler \
  r-cran-matrix=1.2-4-1trusty0 \
  r-cran-codetools=0.2-14-1~ubuntu14.04.1~ppa1 \
  r-cran-survival=2.38-3-1trusty0 \
  r-cran-nlme=3.1.123-1trusty0 \
  r-cran-mgcv=1.8-7-1trusty0 \
  r-cran-kernsmooth=2.23-15-1trusty0 \
  r-cran-cluster=2.0.3-1trusty0 \
  r-base=${R_BASE_VERSION}* \
  r-base-dev=${R_BASE_VERSION}* \
  r-recommended=${R_BASE_VERSION}* \
  r-doc-html=${R_BASE_VERSION}* \
  r-base-core=${R_BASE_VERSION}* \
  r-base-html=${R_BASE_VERSION}*

RUN echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /etc/R/Rprofile.site
RUN echo 'source("/etc/R/Rprofile.site")' >> /etc/littler.r

# Install software needed for common R libraries
# For RCurl
RUN apt-get -y install libcurl4-openssl-dev
# For rJava
RUN apt-get -y install libpcre++-dev
RUN apt-get -y install openjdk-8-jdk
# For XML
RUN apt-get -y install libxml2-dev

##### R: COMMON PACKAGES
# To let R find Java
RUN R CMD javareconf

# Install common R packages
RUN R -e "install.packages(c('devtools', 'gplots', 'httr', 'igraph', 'knitr', 'methods', 'plyr', 'RColorBrewer', 'rJava', 'rjson', 'R.methodsS3', 'R.oo', 'sqldf', 'stringr', 'testthat', 'XML', 'DT', 'htmlwidgets', 'log4r', 'pryr'))"

RUN R -e 'if(!require(devtools)) { install.packages("devtools") }; \
  library(devtools); \
  install_github("ramnathv/rCharts");'

# Install Bioconductor
RUN R -e "source('http://bioconductor.org/biocLite.R'); biocLite(c('Biobase', 'BiocCheck', 'BiocGenerics', 'BiocStyle', 'S4Vectors', 'IRanges', 'AnnotationDbi'))"

##### R: SHINY
# Install Shiny
RUN apt-get install -y \
    sudo \
    wget \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev

# Download and install Shiny server
# Cannot use ADD because using variables; Using wget instead
RUN wget --no-verbose https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget --no-verbose "https://s3.amazonaws.com/rstudio-shiny-server-os-build/ubuntu-12.04/x86_64/shiny-server-$VERSION-amd64.deb" -O ss-latest.deb && \
    gdebi -n ss-latest.deb && \
    rm -f version.txt ss-latest.deb

# Install shiny related packages
RUN R -e "install.packages(c('rmarkdown', 'shiny'))"

RUN R -e 'if(!require(devtools)) { install.packages("devtools") }; \
  library(devtools); \
  install_github("cytoscape/r-cytoscape.js");'

RUN R -e "library(devtools); install_cran('plotly')"

# Copy sample apps
RUN cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/

# Setup Shiny log
RUN mkdir -p /var/log/shiny-server
RUN chown shiny:shiny /var/log/shiny-server

# Expose Shiny server
EXPOSE 3838
#CMD ["shiny-server"]
