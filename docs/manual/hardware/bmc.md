# BMC

Baseboard Management Controller (*BMC*) allows you to manage you baremetall servers. Usually, each manafacture has its own BMC. Sometimes it miht be required to connect to the server console. Let's take a look how to prepare your laptop for connecting to some popular consoles.

## ATOS

For accessing [ATOS](https://atos.net) [java web start](https://en.wikipedia.org/wiki/Java_Web_Start). It's presented in java 8. You should do:

1. Install java 8 i.e. [azul](https://www.azul.com/downloads/)

    ```shell
    wget https://cdn.azul.com/zulu/bin/zulu8.62.0.19-ca-jdk8.0.332-macosx_aarch64.tar.gz
    tar -zxvf zulu8.62.0.19-ca-jdk8.0.332-macosx_aarch64.tar.gz
    ```

2. *optional* For mac m1 there is no javaws binary, so you should additionally pre install it. i.e. you can use [icedtea web portable](https://adoptopenjdk.net/icedtea-web.html)

    ```shell
    wget https://github.com/AdoptOpenJDK/IcedTea-Web/releases/download/icedtea-web-1.8.8/icedtea-web-1.8.8.portable.bin.zip
    unzip icedtea-web-1.8.8.portable.bin.zip
    ```

3. Usually BMCs are located in trusted netwrok & you should establish VPN or port forward the connection. let's imagine that we use 10.1.1.1 as a bastion host and 10.2.2.2 is out target BMC. Let's redirect the port via ssh

    ```shell
    ssh user@10.1.1.1 -c aes128-ctr -o KexAlgorithms=+diffie-hellman-group1-sha1  -L 4443:10.2.2.2:443
    ```

4. We are ready to access the BMC web interface and download `rcgui.jnlp`.
5. The `rcgui.jnlp` should be modified because of port forwarding

    ```shell
    sed -i -e s/10.2.2.2:443/127.0.0.1:4443/g rcgui.jnlp
    sed -i -e "s/<argument>10.2.2.2</<argument>127.0.0.1</g" rcgui.jnlp
    sed -i -e "s/<argument>443</<argument>4443</g" rcgui.jnlp
    ```

6. *optional* Mac M1 specific settings are required in `rcgui.jnlp`

    ```xml
    <resources os="Mac">
      <j2se version="1.6+"/>
      <jar href="rcgui.jar"/>
    </resources>
    ```

7. Run `rcgui.jnlp`

```shell
export JAVA_HOME=~/java/zulu8.62.0.19-ca-jre8.0.332-macosx_aarch64/
export PATH=~/java/zulu8.62.0.19-ca-jre8.0.332-macosx_aarch64/bin:$PATH
~/java/icedtea-web-image/bin/javaws.sh ~/Downloads/rcgui.jnlp
```