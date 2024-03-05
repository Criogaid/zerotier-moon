# zerotier-moon
🐳 A docker image to create ZeroTier moon in one step.

## Usage
```bash
docker run --rm \
  --name zerotier-moon \
  -p 9993:9993/udp \
  -v ./zerotier-one:/var/lib/zerotier-one \
  --device /dev/net/tun \
  --cap-add NET_ADMIN \
  --cap-add SYS_ADMIN \
  criogaid/zerotier-moon \
  -4 YourIPv4Address \
  -6 YourIPv6AddressIfYouHaveOne \
  -p 9993
```


## Docker-compose 

```yaml
version: '3'

# Define the services section
services:
  zerotier-moon:
    # Use the criogaid/zerotier-moon image
    image: criogaid/zerotier-moon

    # Restart the container automatically if it crashes
    restart: unless-stopped

    # Set the container name to "zerotier-moon"
    container_name: zerotier-moon

    # Publish port 9993/udp from the container to the host
    ports:
      - "9993:9993/udp"

    # Mount the ./zerotier-one directory from the host to /var/lib/zerotier-one in the container
    volumes:
      - ./zerotier-one:/var/lib/zerotier-one

    # Set the ZEROTIER_JOIN_NETWORKS environment variable to the specified network ID
    # Or you can make it join to multiple networks by [network1, network2, ...]
    environment:
      - ZEROTIER_JOIN_NETWORKS= # Optional, the network ID you want to join
      - ZEROTIER_API_SECRET=  # Optional, if you want to use the ZeroTier Central API
      - ZEROTIER_IDENTITY_PUBLIC= # Optional, if you want to use a custom identity
      - ZEROTIER_IDENTITY_SECRET= # Optional, if you want to use a custom identity

    # Allow the container to access the host's network devices
    devices:
      - /dev/net/tun

    # Add NET_ADMIN and SYS_ADMIN capabilities to the container
    cap_add:
      - NET_ADMIN
      - SYS_ADMIN

    # Set the command to be executed when the container starts
    command:
      - -4 YourIPv4Address # if you don't have an IPv4 address, you can remove this line
      - -6 YourIPv6AddressIfYouHaveOne # if you don't have an IPv6 address, you can remove this line
      - -p 9993 # Optional, the port you want to use
```

## Logs Output
If everything goes well, you will see the following logs:
```bash
IPv4 address: xxx.xxx.xxx.xxx
IPv6 address is unset, automatically catch the IPv6 address
Failed to catch the IPv6 address.
\r=> Configuring networks to join
Your ZeroTier moon id is xxxxxxxxxx, you could orbit moon using "zerotier-cli orbit xxxxxxxxx xxxxxxxxx"
Starting Control Plane...
Starting V6 Control Plane...
```