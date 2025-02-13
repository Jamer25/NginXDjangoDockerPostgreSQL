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
default.conf
Dockerfile

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

# Luego construir:
docker compose build

# Luego ejecuta:
docker compose up