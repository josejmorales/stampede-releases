# Stampede releases

Installers and binaries for Stampede, a terminal stock trend screener.

## Install (macOS, Apple Silicon)

```
curl -fsSL https://raw.githubusercontent.com/josejmorales/stampede-releases/main/install.sh | bash
```

Then run `stampede`. Update later with `stampede update`.

Each release lists a SHA-256 for every file in `SHA256SUMS`; the installer and
`stampede update` check it before installing.
