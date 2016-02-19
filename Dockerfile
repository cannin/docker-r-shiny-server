FROM ubuntu:14.04.3
MAINTAINER cannin

##### UBUNTU
# Update Ubuntu and add extra repositories
RUN apt-get -y install software-properties-common
RUN apt-add-repository -y ppa:marutter/rrutter
RUN apt-get -y update && apt-get -y upgrade

# Install basic commands
RUN apt-get -y install links nano htop

# Necessary for getting the latest R version
RUN apt-get -y install r-base r-base-dev

# Install software needed for common R libraries
# For RCurl
RUN apt-get -y install libcurl4-openssl-dev
# For rJava
RUN apt-get -y install libpcre++-dev
RUN apt-get -y install openjdk-7-jdk
# For XML
RUN apt-get -y install libxml2-dev

##### R: COMMON PACKAGES
# To let R find Java
RUN R CMD javareconf

# Install common R packages
RUN R -e "install.packages(c('devtools', 'gplots', 'httr', 'igraph', 'knitr', 'methods', 'plyr', 'RColorBrewer', 'rJava', 'rjson', 'R.methodsS3', 'R.oo', 'sqldf', 'stringr', 'testthat', 'XML', 'DT', 'htmlwidgets', 'log4r', 'pryr'), repos='http://cran.rstudio.com/')"

RUN R -e 'setRepositories(ind=1:6); \
  options(repos="http://cran.rstudio.com/"); \
  if(!require(devtools)) { install.packages("devtools") }; \
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
RUN R -e "install.packages(c('rmarkdown', 'shiny'), repos='http://cran.rstudio.com/')"

RUN R -e 'setRepositories(ind=1:6); \
  options(repos="http://cran.rstudio.com/"); \
  if(!require(devtools)) { install.packages("devtools") }; \
  library(devtools); \
  install_github("cytoscape/r-cytoscape.js");'

# Copy sample apps
RUN cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/

# Setup Shiny log
RUN mkdir -p /var/log/shiny-server
RUN chown shiny:shiny /var/log/shiny-server

# Expose Shiny server
EXPOSE 3838
#CMD ["shiny-server"]
