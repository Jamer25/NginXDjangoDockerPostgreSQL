# NginXDjangoDockerPostgreSQL
Agregando el servidor web de alto rendimiento NginX a lo que se trabajó en el proyecto DjangoDockerPostgreSQL

# Definición del uso de nginx
Si no usas Nginx, tendríamos que acceder directamente a tu aplicación Django en http://localhost:8000. Sin embargo, esto tiene desventajas:
No puedes manejar tráfico HTTPS directamente.
No puedes servir archivos estáticos de manera eficiente.
No tienes una capa de proxy inverso para mejorar el rendimiento y la seguridad.

Acceso a través de Nginx (http://localhost):

Esto funciona porque Nginx está escuchando en el puerto 80 y redirige las solicitudes a Django.

Es la forma "correcta" de acceder a tu aplicación en un entorno de producción, ya que Nginx proporciona beneficios como:

Servir archivos estáticos de manera eficiente.

Manejar tráfico HTTPS.

Mejorar el rendimiento y la seguridad.

# ¿Por qué es mejor usar Nginx en producción?
Aunque puedes acceder directamente a Django en http://localhost:8000, no es recomendable hacerlo en un entorno de producción. Aquí te explico por qué:

a) Seguridad:
El servidor de desarrollo de Django (runserver) no está diseñado para manejar tráfico en producción. Es lento y no es seguro.

Nginx actúa como una capa adicional de seguridad, protegiendo tu aplicación de ataques comunes.

b) Rendimiento:
Nginx es mucho más eficiente para manejar múltiples solicitudes simultáneas.

Puede servir archivos estáticos (CSS, JS, imágenes) directamente, liberando a Django de esa carga.

c) HTTPS:
Nginx puede manejar certificados SSL/TLS para servir tu aplicación a través de HTTPS (https://localhost).

Django, por sí solo, no puede manejar HTTPS de manera eficiente.

d) Balanceo de carga:
Si en el futuro escalas tu aplicación y tienes múltiples instancias de Django, Nginx puede actuar como un balanceador de carga, distribuyendo el tráfico entre ellas.

# ¿Cómo evitar el acceso directo a http://localhost:8000 en producción?
Si deseas asegurarte de que los usuarios solo accedan a tu aplicación a través de Nginx (http://localhost), puedes hacer lo siguiente:

a) No exponer el puerto 8000:
Elimina la línea ports: - "8000:8000" del servicio web en tu docker-compose.yml.

Esto evitará que el puerto 8000 esté disponible fuera del contenedor.

# b) Restringir el acceso al puerto 8000:
Si necesitas mantener el puerto 8000 expuesto (por ejemplo, para debugging), puedes restringir el acceso a solo localhost:
    services:
  web:
    build: .
    container_name: django
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - .:/code
    ports:
      - "127.0.0.1:8000:8000"  # Solo accesible desde localhost
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
        proxy_pass http://web:8000;
    }
}

# OBS:
 ¿Qué ocurre cuando Nginx usa proxy_pass http://web:8000;?
 Desde dentro del contenedor de Nginx, web:8000 es una dirección válida.
 Nginx redirige las solicitudes a http://web:8000, que en realidad apunta al servicio web en Docker.
 Tu aplicación Django está escuchando en 0.0.0.0:8000, así que puede aceptar la conexión.
para comprobarlo:
docker exec -it nginx_cont sh
ping web
Para comprobar otra forma:
docker exec -it nginx_cont sh
curl -I http://web:8000

Pero esto sucede dentro de la red de Docker, no en tu navegador.

 Nginx traduce proxy_pass http://web:8000; como http://(IP del contenedor de web) dentro de la red de Docker.
 Por eso puedes hacer proxy_pass http://web:8000;, pero no puedes acceder a http://web:8000 desde tu navegador en la máquina host.
# OBS 2
     El problema es que Django verifica el Host en ALLOWED_HOSTS y django_backend no estaba en la lista, así que bloqueó la solicitud.

¿Cómo proxy_set_header Host $host; soluciona el problema?
proxy_set_header Host $host;
Le dijiste a Nginx:
"No cambies el Host, usa el mismo que envió el cliente (el navegador)".

Ahora, cuando el navegador accede a http://localhost, Nginx reenvía la solicitud a Django, pero asegurándose de que el Host siga siendo localhost, no django_backend.
# en settings.py
Debes asegurarte de que web está incluido en ALLOWED_HOSTS dentro de settings.py:
ALLOWED_HOSTS = ['localhost', '127.0.0.1', 'web']

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


  # OJOOOOOO
  ¿por qué proxy_pass sigue siendo útil si proxy_set_header es obligatorio?
- proxy_pass es necesario porque define a dónde enviará la solicitud Nginx (en este caso, a web:8000).
- proxy_set_header Host localhost ( proxy_set_header Host $host;); solo corrige el Host, pero sin proxy_pass, Nginx no sabría a dónde redirigir la solicitud.

Así que ambos son necesarios para que la configuración funcione correctamente.

¿Qué hace server_name localhost; en Nginx?
- Define los dominios o direcciones IP que este servidor virtual manejará.
- En este caso, indica que este bloque de configuración solo se aplicará cuando el cliente acceda a localhost.

