# Local build and smoke test. On Maître the Catalog entry runs the image.

image := "localhost/t3-code-os:dev"
name := "t3-code-os-dev"
port := "3774"

build:
    podman build -t {{image}} -f Containerfile .

# Run like Maître does: two volumes, published on loopback only.
run: build
    podman volume create --ignore {{name}}-home
    mkdir -p .scratch/workspace
    podman run -d --name {{name}} --shm-size 1g \
      -p 127.0.0.1:{{port}}:3773 \
      -v {{name}}-home:/home/dev:Z,U \
      -v ./.scratch/workspace:/workspace:Z \
      {{image}}
    @echo "Pairing link: just logs (look for /pair#token=), served at http://127.0.0.1:{{port}}"

logs:
    podman logs -f {{name}}

shell:
    podman exec -it {{name}} bash -l

pair:
    podman exec {{name}} t3 pair

stop:
    podman rm -f {{name}}

# Removes the container and its home volume: T3 state and Provider Logins.
reset: stop
    podman volume rm -f {{name}}-home
