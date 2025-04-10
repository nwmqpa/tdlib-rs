group "default" {
  targets = ["libtdjson"]
}

target "libtdjson" {
  context = "."
  dockerfile = "docker/Dockerfile"
  tags = [
    "ghcr.io/nwmqpa/libtdjson:latest",
    "ghcr.io/nwmqpa/libtdjson:latest-slim",
    "ghcr.io/nwmqpa/libtdjson:1.8.46",
    "ghcr.io/nwmqpa/libtdjson:1.8.46-slim",
  ]
  labels = {
    "org.opencontainers.image.source" = "https://github.com/nwmqpa/tdlib-rs"
    "org.opencontainers.image.author" = "thomas.nicollet@nebulis.io"
  }
  build_args = {
    "COMMIT_SHA" = "207f3be7b58b2a2b9f0a066b5b6ef18782b8b517"
  }
}
