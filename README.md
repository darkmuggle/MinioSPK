Minio Packaging for Synology NAS 
==

This repo can create a Synology NAS SPK file suitable for a home user. If you don't know what [Minio is, please take look](https://minio.io/).

What this is
===

Minio offers a wide-variety of features. This repo only exposes enough of Minio to get started. That is:
* fetch and build Minio for the Synology ARM or i386-platform
* package Minio in a SPK format
* Targets for ARM or i386-based Synology

Minio has elected to support Synology NAS's through [Docker Containers](https://github.com/minio/minio/issues/4210). In my opinion, targeting Docker is the correct decision for Cloud-base storage. However, if you have a consumer-grade Synology NAS, using Docker is a non-starter: I hope that this side-project will help close the gap.

As of right now, it only supports:
* non-SSL encryption
* setting the ACCESS and SECRET key

Here Be Dragons
===

Removing the Minio installation from the NAS will result in your data being deleted.

THIS ONLY WORKS FOR ARM-7/ARM64 or i386 NAS's right now.

Due to the inclusion of Minio's Art Work, re-distribution of the SPK may violate their terms. Please see LICENSE-Artwork for more information..

Credit where Credit is Due
===

I based this repo off the great work from a [Gitea SPK](https://github.com/flipswitchingmonkey/gitea-spk) that I also use on my Synology NAS.

Getting Started
===

You will need:
* Make
* gawk
* Docker
* Git
* A Synology NAS based on one of the chipsets in [arch.desc](arch.desc) file

Docker is used to as the build system and to manage dependencies, specifically:
* Artwork is fetched remotely. This requires tooling to get the artwork, unzip to extract it and ImageMagick to transform the icon sizes.
* The building of Minio is done in a Debian Stretch Golang container. This was done to make the packaging more accessible to people who just want an `spk` but don't want to setup Go.

After cloning/forking this repo:
* run `make init`. This step fetches the latest release of Minio and the icons.
* run `make arm7` or `make arm64` or `make i386`. During this step, a docker container will cross compile Minio. It will take a bit.
* Go to your NAS's package manager. This should be Synology's "Package Center".
* Click `Manual Install`
* Follow the dialogs
* Take care to choose a good `ACCESS_KEY` and `SECRET_KEY` 
* Login at `http://<NAS IP>:<port>` where `<port>` was the one you selected in the dialogs.

Pull-Requests Accepted
===

I promise not to be a jerk. If you improve, or add a feature, please send it my way; I'm happy to consider it. Opensource should be inclusive. 
