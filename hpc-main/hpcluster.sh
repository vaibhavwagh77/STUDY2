#!/bin/bash

#COLOR CODES
red='\033[31m'
cyan='\033[0;36m'
lightblue='\e[38;5;109m'
green='\e[32m'
blue='\e[34m'
upper="${lightblue}╔$(printf '%.0s═' $(seq "80"))╗${end}"
lower="${lightblue}╚$(printf '%.0s═' $(seq "80"))╝${end}"
end='\e[0m'
#----------------------------
function validate_args(){
        if [[ -z ${master_ip} || -z ${master_hostname} || -z ${ip} || -z ${host} || -z ${ssh} || -z ${nfs} || -z ${supervisor} || ! ${master_ip} =~ regex || ! ${ip} =~ regex || ! ${ssh} =~ ([Tt]rue|[Ff]alse) || ! ${nfs} =~ ([Tt]rue|[Ff]alse) || ! ${supervisor} =~ ([Tt]rue|[Ff]alse) ]];then
                printf "Error: Invalid ${red}IP/HOSTNAME/SSH/NFS/SUPERVISOR${end} in ${config}"
                exit 4
        fi
}

# C_ARGS
function c_args(){
        #-------------------------------------------------------------------------------------------------------------
        # COMPUTE NODEs
        nodes_list=($(sed -n '/^compute_nodes:/,/^[^ ]/{/^  node/s/^  //p}' ${config}))
        # echo "Number of NODEs : ${#nodes_list[@]}"
        for NODE in ${nodes_list[@]};do
            ip=$(sed -n '/^compute_nodes:/,/^[^ ]/{/^  /s/^  //p}' config.yaml | sed -n "/^$NODE/,/^[^ ]/{/^  - /s/^ //p}"|awk -F": " '/ip/{print $NF}')
            host=$(sed -n '/^compute_nodes:/,/^[^ ]/{/^  /s/^  //p}' config.yaml | sed -n "/^$NODE/,/^[^ ]/{/^  - /s/^ //p}"|awk -F": " '/hostname/{print $NF}')
            validate_args
            #### EXEC TASKs
            #$1 ${ip} ${host}
        done

}

# M_ARGS
function m_args(){
        #----------------------------------------------------------------------------
        # MASTER NODE
        master_ip=$(sed -n '/^master_nodes:/,/^[^ ]/{/^  - /s/^  - //p}' $config | awk -F": " '/ip/{print $NF}')
        master_hostname=$(sed -n '/^master_nodes:/,/^[^ ]/{/^  - /s/^  - //p}' $config | awk -F": " '/hostname/{print $NF}')
        #-----------------------------------------------------------------------
        validate_args
        #### EXEC TASKs
        #$1 ${master_ip} ${master_hostname}
}
# FUNCTION HELP
function help(){
    printf "${upper}\n\t\t${cyan}High-Performance Computing (HPC) Cluster Utility${end}\n${lower}\n\n"
    printf "${blue}Usage: ${end}"
    printf "\tbash $0 [MODEs] [ARGS]...\n"


    printf "\n${blue}MODEs:${end}\n"
    printf "\tmaster\t[CONFIGURE MASTER NODE]\n"
    printf "\tcompute\t[CONFIGURE COMPUTE NODEs]\n"
    printf "\n"
}

function master_help(){
    printf "${upper}\n\t\t${cyan}High-Performance Computing (HPC) Cluster Utility${end}\n${lower}\n\n"
    printf "${blue}Usage: ${end}"
    printf "\tbash $0 master [ARGS]...\n"
    printf "\n"
    printf "${blue}Args: ${end}\n"
    printf "\t-c/--config config.yaml\tProvide YAML file for cluster's master node [Required${red}*${end}]\n"
    printf "\t-h/--help \t\tUsage for cluster's master node\n"
}











function master_ssh_setup(){
   if systemctl status ssh &> /dev/null;then
           printf "${cyan}SSH is already installed${end}: ${green}$(systemctl is-active ssh)${end}\n"
   else
           printf "$ip\t$hostname\n" >> /etc/hosts
           printf "Update /etc/hosts for $hostname & $ip: [${green}DONE${end}]\n"
           echo -en "Installing SSH : [${red}WAITING${end}]\r"
           apt install openssh-server -y -qq &> /dev/null
           echo -en "Installing SSH : [${green}DONE${end}]\n"
           systemctl start ssh &> /dev/null
           systemctl enable ssh &> /dev/null
   fi

}

case $1 in
        "master")
                case $2 in
                        "-h"|"--help")
                                master_help
                                exit 0
                                ;;
                        "-c"|"--config")
                                config=${3}

                                # GLOBAL VAR - SERVER SETUP ON ALL NODEs
                                #ssh=$(sed -n 's/^ssh: //p' ${config})
                                #nfs=$(sed -n 's/^nfs: //p' ${config})
                                #supervisor=$(sed -n 's/^supervisor: //p' ${config})
                                #-----------------------
                                if [[ -z ${config} ]] || [[ ! -f ${config} ]];then
                                        printf "\nError: must specify YAML file as argument for master mode\n"
                                        master_help
                                        exit 3
                                fi
                                #elif [[ ! -f ${config} ]];then || ( printf "\nError: must specify YAML file as argument for master mode\n"; master_help; exit 4;)

                                ;;
                        *)
                            printf "\nError: ${red}${0} master ${2:-UNKNOWN}${end} invalid argument\n"
                            master_help
                            exit 2
                            ;;
                esac
                ;;
        "compute")
                printf "Cluster input CODE\n"
                ;;
        "-h"|"--help")
                help
                exit 0
                ;;
        *)
                printf "Error: ${red}$0 ${1:-UNKNOWN}${end} invalid input\n"
                help
                exit 1
                ;;
esac
echo "end"



















#if [[ -z $hostname ]] || [[ -z $ip ]];then
#        printf "\nError: must specify -ip/-host argument in master mode: \n\t${cyan}bash $0 master -h/--help${end}\n"
#        exit 3
#else
#        hostnamectl set-hostname $hostname 2> /dev/null
#        dhclient -r &> /dev/null
#        dhclient &> /dev/null
        #inet=$(ip -br a | grep "UP" | grep -v "127.0.0.1"| awk '{print $1}')
        #gw=$(ip route show dev $inet| head -1| awk '{print $NF}')
        #ip link set $inet down
        #ip address replace $ip dev $inet
        #ip route add $ip via $gw dev $inet
        #ip link set $inet up
#fi
