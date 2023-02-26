FROM centos:7
#description
LABEL Desription="building this image for resume"

LABEL Maintaner="Olatunde <tundeficky@gmail.com>"
#executing commands to update the pacckage
RUN yum update -y && yum clean all

#Executing command to install apache
RUN yum install httpd -y
#Copying an index.html in a specify location in a container
COPY index.html /var/www/html/

EXPOSE 80
#start the httpd from endpoint
ENTRYPOINT [ "/usr/sbin/httpd" ]
#/usr/sbin/httpd foreground
CMD [ "-D", "FOREGROUND" ]


