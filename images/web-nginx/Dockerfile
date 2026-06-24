# Imagen base oficial de Nginx
FROM docker.io/library/nginx:alpine

# Copia del contenido web
COPY index.html /usr/share/nginx/html/index.html

# Copia de la configuración de Nginx
COPY default.conf /etc/nginx/conf.d/default.conf

# Copia del certificado autofirmado
COPY certs/server.crt /etc/nginx/certs/server.crt
COPY certs/server.key /etc/nginx/certs/server.key

# Copia del fichero de autenticación básica
COPY auth/.htpasswd /etc/nginx/auth/.htpasswd

# Puerto HTTPS
EXPOSE 443
