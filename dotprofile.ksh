# OpenBSD: dot.profile 
#
# sh/ksh initialization

function ban () {
  pfctl -t banned -T add $1
  pfctl -k $1
}

function ip2long () {
  ip=$1
  OLDIFS=$IFS
  IFS=.
  set -A octets -- $ip
  IFS=$OLDIFS
  # Calculate the integer value
  int_ip=$(( (${octets[0]} << 24) + (${octets[1]} << 16) + (${octets[2]} << 8) + ${octets[3]} ))
  echo $int_ip
}

function long2ip {
  int=$1
  o1=$(( (int >> 24) & 255 ))
  o2=$(( (int >> 16) & 255 ))
  o3=$(( (int >> 8) & 255 ))
  o4=$(( int & 255 ))
  ip="$o1.$o2.$o3.$o4"
  echo "$ip"
}

function genrange {
  start_ip=$1
  end_ip=$2
  cidr=$3

  bits_left=$(( 32 - cidr ))
  block_size=1
  i=0

  while [ $i -lt $bits_left ]; do
      block_size=$(( block_size * 2 ))
      i=$(( i + 1 ))
  done

  # Convert start and end to integers
  start_int=$(ip2long "$start_ip")
  end_int=$(ip2long "$end_ip")

  # Align to block size
  mod=$(( start_int % block_size ))
  if [ $mod -ne 0 ]; then
      aligned_start=$(( start_int - mod + block_size ))
  else
      aligned_start=$start_int
  fi

  # Generate the CIDR blocks
  curr=$aligned_start
  while [ $curr -le $end_int ]; do
      long2ip $curr
      curr=$(( curr + block_size ))
  done
}

function banrange {
  start_ip=$1
  end_ip=$2
  cidr=$3
  for i in $(genrange $start_ip $end_ip $cidr);do
    ban $i/$cidr
  done
}
