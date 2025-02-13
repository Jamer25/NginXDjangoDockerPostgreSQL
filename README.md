# NginXDjangoDockerPostgreSQL
Agregando el servidor web de alto rendimiento NginX a lo que se trabajó en el proyecto DjangoDockerPostgreSQL


# Luego de lo anterior, de agregar el Dockerfile y los requirements.txt em el .yml agregamos

Se tiene que agregar el nuevo servicio Nginx:

nginx:
    build: ./nginx (especifica que el servicio nginx debe construirse desde un directorio ./nginx ) (entonces en mi directorio local creamos la carpeta nginx)
    image: nginx
    container_name: "nginx_cont"
    ports:
      - "80:80"
    depends_on:
      - web


# Ahora vamos a ejecutar:

    docker compose run web django-admin startproject django_docker .

# Ahora en el project de django en settings.py:
  
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'my_database',
        'USER': 'admin',
        'PASSWORD': 'admin',
        'HOST': 'db',
        'PORT': 5432
    }
}
# Luego ejecutar el comando para actualizar los cambios agregados:
  docker compose up

# Creamos la carpeta nginx

Y dentro de esa carpeta colocamos:
default.conf: 
El archivo default.conf es un archivo de configuración para Nginx, que actúa como un proxy inverso. Su función principal es redirigir las solicitudes entrantes (por ejemplo, desde el navegador) a tu aplicación Django.

upstream django_docker: Define un grupo de servidores backend (en este caso, la aplicación Django).

server web:8000; indica que Nginx debe redirigir las solicitudes al servicio web (definido en tu docker-compose.yml) en el puerto 8000.


server: Configura el servidor Nginx para escuchar en el puerto 80.

server_name localhost; indica que el servidor responderá a solicitudes dirigidas a localhost.

location / define que todas las solicitudes (/) se redirijan al upstream django_docker (es decir, a tu aplicación Django).

El Dockerfile en la carpeta nginx se utiliza para construir una imagen personalizada de Nginx que incluye tu archivo de configuración default.conf.

# En default.conf:

upstream django_docker{
    server web:8000;

}

server{
    listen 80;
    server_name localhost;

    location /{
        proxy_pass http://django_docker;
    }
}

# En Dockerfile de la carpeta nginx:
FROM nginx:1.27.4-alpine

COPY default.conf /etc/nginx/conf.d/default.conf
# Para detener y eliminar los contenedores, redes, volúmenes e imágenes que fueron creados con docker compose up
    docker compose down 

# Luego construir:
    docker compose build

# Luego ejecuta:
    docker compose up

#  AHORA COMO HACEMOS CON LAS MIGRACIONES PARA NUESTRO PROYECTO DJANGO?
    Abro otra terminal y ejecuto:
        docker compose run web python manage.py migrate
  
# AHORA PARA CREAR EL SUPERUSUARIO:
      
      docker exec -it django python manage.py createsuperuser

  it: para que sea una pantalla iterativa

# Ahora si quiero crear una app
  docker exec django python manage.py startapp core

# Queremos saber que contenedores se están ejecutando:
  docker ps