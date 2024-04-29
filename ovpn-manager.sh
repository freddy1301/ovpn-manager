#!/bin/bash

container="<PLEASE ENTER YOUR CONTAINER NAME HERE>"
container_set=false

echo " "

jp2a --color https://raw.githubusercontent.com/freddy1301/ovpn-clientmanager/main/openvpn_logo.png 2> /dev/null

echo " "

if command -v docker &> /dev/null; then
    # Check if Docker is Installed
    if sudo docker ps -a --format '{{.Names}}' | grep -q "^$container$"; then
    echo "Registered Clients:"
    installed=true
    else
        echo " "
        echo "There is no Container matching the Name $container. You may need to set the Name with Option 4 or Install the OpenVPN Server with Option 5"
    fi
else
    echo "Docker is not even installed. You can do that by choosing Option 5"
fi

sudo docker exec -it $container ovpn_listclients 2> /dev/null

echo " "

while true; do
    echo "1) Add a new Client"
    echo "2) Revoke a Client"
    echo "3) Export a Client Configuration"
    echo "4) Set Target OpenVPN Container"
    echo "5) Install OpenVPN Server and Required Packages (Debian Only)"
    echo "0) Exit"

    read option

    case $option in
        1)
            echo "Client Name:"
            read client_name
            echo " "
            
            echo "Generating Client Certifcate (You need to enter your root_ca privatekey passphrase)"
            sudo docker run -v /opt/openvpn:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full $client_name nopass
            sudo docker exec $container ovpn_getclient $client_name > $client_name.ovpn
	        if mv ./$client_name.ovpn /opt/openvpn/clients 2> /dev/null ;then
                echo "Exporting Client Configuration File to /opt/openvpn/clients/$client_name"
            else
                echo "Exporting Client Configuration File to ./$client_name.ovpn"
            fi

            
            unset client_name
            exit 0
            ;;
        2)
            echo "Client Name (Only on at a time!):"
            read client_name
            echo " "

            sudo docker exec -it $container ovpn_revokeclient $client_name

            echo "Looking for leftover Client Configurations..."
            files=$(find / -type f -name "$client_name.ovpn" 2>/dev/null)

            if [ -z "$files" ]; then
                echo "No files named '$client_name.ovpn' have been found."
                exit 0
            fi

            echo "Following files have been found:"
            echo "$files"
            echo

            read -p "Do you want do delete them? (Y/N): " answer

            if [ "$answer" == "Y" ]; then
                echo "Deleting files..."
                echo "$files" | xargs sudo rm -f
                echo "Files deleted!"
            else
                echo "No files have been deleted!"
            fi

            unset client_name
            exit 0
            ;;
        3)
            echo "Client Name:"
            read client_name
            echo " "

            sudo docker exec $container ovpn_getclient $client_name > $client_name.ovpn

            echo " "
            echo "File exported! ($client_name.ovpn)"
            echo " "

            unset client_name
            exit 0
            ;;
        4)
            # Setting Container Name
            echo " "
            echo "What should your Docker Container be called?" 
            read container
            sed -i 's/<PLEASE ENTER YOUR CONTAINER NAME HERE>/'$container'/g' ovpn-manager.sh
            sed -i 's/container_set=false/container_set=true/g' ovpn-manager.sh
            echo "Name Set! The Script exited to reload variables."
            exit 0
            ;;
        5)
            if [ "$installed" = true ]; then
              echo "There is already an existing Installation of Dockerized OpenVPN."
                exit 0
            fi
            # Checking if the User is in the same dir
            if [ ! -f "$(basename "$0")" ]; then
              echo "Please run the script from its directory."
                exit 1
            fi
            # Checking Container Name
            if [ "$container_set" = false ]; then
                echo " "
                echo "Please set the Container Name first. (Even if no OpenVPN Container is Installed)"
                echo " "
            else
            # Installing Packages
                echo " "
                echo "Installing Docker & jp2a..."
                screen -dmS ovpn-install sudo apt install docker.io jp2a -y > /dev/null &
                read -p "Do you want to watch the process? You should if you are not root. (Y/N): " answer
                if [ "$answer" == "Y" ]; then
                    screen -x ovpn-install
                    else
                echo "The Process will run in the background. You can still check with screen -x ovpn-install"
                fi
                unset answer
                # Wait until the Install is done
                while screen -list | grep -q ovpn-install; do
                sleep 1
                done
                echo " "
                echo "Packages Installed!"
                sleep 1
                # Check for Docker Service to come online
                    max_attempts=30
                    sleep_time=1

                    attempt=1
                    while [ $attempt -le $max_attempts ]; do
                        if ! sudo systemctl is-active --quiet docker; then
                            echo "Waiting for the Docker.service to come online ($attempt of $max_attempts Attempts)..."
                            sleep $sleep_time
                            ((attempt++))
                        else
                            echo "The Docker.service was started successfully!"
                            break  # Breche die Schleife ab, da der Service gestartet ist
                        fi
                    done
                    
                    if [ $attempt -gt $max_attempts ]; then
                      echo "The Docker Service did not start in $((max_attempts * sleep_time)) Seconds. The Script will exit now."
                        exit 1
                    fi
                unset max_attempts
                unset sleep_time
                unset attempt
                # Pull the Docker Image
                echo "Pulling Image..."
                sudo docker pull kylemanna/openvpn
                OVPN_DATA="/opt/openvpn"
                echo " "
                echo "At what IP/DNS Address can Clients reach your Server?"
                read hostname
                echo " "
                echo "Generating OpenVPN Configuration..."
                sudo docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://$hostname
                echo "Configuration Initialized and stored at /opt/openvpn/openvpn.conf"
                echo " "
                echo "Now the CA to Sign Client Certificates will be set up. You will be asked to put in a passphrase. This passphrase will be required to Add or Revoke Clients. Note it down properly and make it secure!"
                echo " "
                echo "Press Enter to continue..."
                read _
                sudo docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki
                echo " "
                echo "Creating /opt/openvpn/clients directory"
                sudo mkdir /opt/openvpn/clients
                sudo cp ./ovpn-manager.sh /opt/openvpn
                echo "Installation Finished!"
                sleep 1
                echo "Starting the Container..."
                sudo docker run -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp --name $container --cap-add=NET_ADMIN kylemanna/openvpn
                sudo docker inspect $container
                echo " "
                echo "The Container is now up and running (hopefully). Dont forget to open 1194/udp"
                echo "Bye!"
                exit 0
            fi
            unset hostname
            ;;
        0)
            echo "Exiting.."
            exit 0
            ;;
        *)
            echo "Unknown option. Please try again"
            ;;
    esac
done
