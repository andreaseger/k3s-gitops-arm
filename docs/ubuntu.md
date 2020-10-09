# Ubuntu

> All these commands are run from your computer, not the RPi.

## Downloads the Flash tool

```bash
sudo curl -L "https://github.com/hypriot/flash/releases/download/2.3.0/flash" -o /usr/local/bin/flash
sudo chmod +x /usr/local/bin/flash
```

## Download and extract the image

```bash
cd ~/Downloads
curl -L "https://cdimage.ubuntu.com/releases/20.04.1/release/ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz" -o ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz
unxz -T 0 ~/Downloads/ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz
```

## Configure

Update [cloud-config.example.yml](../setup/cloud-config.example.yml) as you see fit.

## Flash

```bash
flash \
    --userdata setup/cloud-config.yml \
    ~/Downloads/ubuntu-19.10.1-preinstalled-server-arm64+raspi3.img
```

or flash with other tools and `cp setup/cloud-config.yml <bootdrive>/user-data`

## Boot

Place the SD Card in your RPi and give the system 5 minutes to boot before trying to SSH in.
