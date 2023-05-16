.. _installing_dsiprouter:


Installing dSIPRouter
=====================

Install dSIPRouter takes approximately 4-9 minutes to install.  The following video shows you the install process:

.. raw:: html

        <object width="560" height="315"><param name="movie"
        value="https://www.youtube.com/embed/Iu4BQkL1wGc"></param><param
        name="allowFullScreen" value="true"></param><param
        name="allowscriptaccess" value="always"></param><embed
        src="https://www.youtube.com/embed/Iu4BQkL1wGc"
        type="application/x-shockwave-flash" allowscriptaccess="always"
        allowfullscreen="true" width=""
        height="385"></embed></object>



Prerequisites:
^^^^^^^^^^^^^^

- Must run this as the root user (you can use sudo)
- git needs to be installed
- Hostname needs to be set to a FQDN (for certbot to get LetsEncrypt certificate)
- The installer will handle all other dependencies



Install Options
^^^^^^^^^^^^^^^^

- Proxy SIP Traffic Only (Don't Proxy audio (RTP) traffic)
- Proxy SIP Traffic and Audio when it detects a SIP Agent is behind NAT
- Proxy SIP Traffic, Audio and it configures the system to work properly when the PBX's and dSIPRouter are behind a NAT.

OS Support
^^^^^^^^^^

- **Debian 11 (Bullseye) (BETA)**
- **Debian 10 (Buster) (tested on 10.9)**
- **Debian 9 (Stretch) (tested on 9.6)**
- **Debian 8 (Jessie)**
- **CentOS 8**
- **CentOS 7**
- **Amazon Linux 2**
- **Ubuntu 16.04 (Xenial)**


Kamailio will be automatically installed along with dSIPRouter.
Must be installed on a fresh install of Debian Stretch, Debian Buster or CentOS 7.
You will not be prompted for any information.  It will take anywhere from 4-9 minutes to install - depending on the processing power of the machine. You can secure the Kamailio database after the installation.
Links to the installation documentation are below:

- :ref:`debian9-install`
- :ref:`debian10-install`
- :ref:`centos7_install`

Amazon AMI's
^^^^^^^^^^^^

We now provide Amazon AMI's (pre-built images) which allows you to get up and going even faster.
You can find a list of the images `here <https://aws.amazon.com/marketplace/search/results?x=0&y=0&searchTerms=dsiprouter/>`_.
The images are a nominal fee, which goes toward supporting the project.
