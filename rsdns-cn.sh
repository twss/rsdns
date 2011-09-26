#!/bin/bash
#
# rsdns-cn.sh - Used to create/delete CNAME records hosted on rackspace cloud dns
#

# load up our auth library
. lib/auth.sh

# load up our function library
. lib/func.sh

#prints out the usage information on error or request.
function usage () {
	printf "\n"
	printf "rscurl -u username -a apiKey -n cNAME -r aRECORD -t TTL\n"
	printf "\t-k Use London/UK Servers.\n"
	printf "\t-x Delete record.\n"
	printf "\t-U Update existing record.\n"
	printf "\t-h Show this.\n"
	printf "\n"
}


function create_cn () {
#{ "id" : "CNAME-123", "type" : "CNAME", "name" : "www.example.foo.com", "data" : "example.foo.com", "ttl" : 86400 }

  if [ -z $CNAME ]
    then
    usage
    exit 1
  fi

  get_domain $NAME
  
  check_domain
	
	if [ $FOUND -eq 1 ]
	then
      
      RSPOST=`echo '{"records":[{ "type" : "CNAME", "name" : "'$NAME'", "data" : "'$CNAME'", "ttl" : '$TTL' }]}'`
      
      create_record
  
    fi
}

function update_cn() {

  if [ -z $CNAME ]
    then
    usage
    exit 1
  fi

  get_domain $NAME
  
  RECORDTYPE="CNAME"
  
  get_recordid
  
      RSPOST=`echo '{ "name" : "'$NAME'", "data" : "'$CNAME'", "ttl" : '$TTL' }'`
  
      RC=`curl -s -X PUT -H X-Auth-Token:\ $TOKEN -H Content-Type:\ application/json  -H Accept:\ application/json $DNSSVR/$USERID/domains/$DOMAINID/records/$RECORDID --data "$RSPOST" |tr -s [:cntrl:] "\n"`
      
      
      if [[ $QUIET -eq 0 ]]; then
		echo $RC
      fi


}

function delete_cn () {

  get_domain $NAME
  
  RECORDTYPE="CNAME"

  delete_record

}

#Get options from the command line.
while getopts "u:a:n:r:t::hkqxU" option
do
	case $option in
		u	) RSUSER=$OPTARG ;;
		a	) RSAPIKEY=$OPTARG ;;
		n	) NAME=$OPTARG ;;
		r	) CNAME=$OPTARG ;;
		t	) TTL=$OPTARG ;;
		h	) usage;exit 0 ;;
		q	) QUIET=1 ;;
		k	) UKAUTH=1 ;;
		x	) DEL=1 ;;
		U	) UPDATE=1 ;;
	esac
done

#Check for enough variables, print usage if not enough.
if [ $# -lt 4 ]
	then
	usage
	exit 1
fi

if [ -z $NAME ]
    then
    usage
    exit 1
fi

#All actions require authentication, get it done first.
#If the authentication works this will return $TOKEN and $MGMTSVR for use by everything else.
get_auth $RSUSER $RSAPIKEY
if test -z $TOKEN
	then 
	if [[ $QUIET -eq 0 ]]; then
		echo Auth Token does not exist.
	fi
	exit 98
fi
if test -z $MGMTSVR
	then 
	if [[ $QUIET -eq 0 ]]; then
		echo Management Server does not exist.
	fi
	exit 98
fi

if [ -n "$UPDATE" ]
  then
  update_cn
  exit 1
fi

if [ -n "$DEL" ]
	then
	delete_cn
else
	create_cn
fi

#done
exit 0