#!/bin/bash

lowercase()
{
  echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

exit_if_invalid()
{
  remaining_chars="$(echo -n $* | sed s'/|\|\/\|(\|)\|;\|:\|@\|&\|-\|+\|\$\|=\|,\|?\|%\|#\|!\|[a-zA-Z0-9]\|\n\|\.\| //'g)"
  if [ "$remaining_chars" == '' ]; then
    return
  else
    exit 1
  fi
}

get_ports_pages()
{
  curl -Lfs -o tempfile.txt $$THESERVER$$/urlandports/$$THEKEY$$ || ( echo "could not download content" &&  exit 1)
  line_number="1"
  while read line;do
    exit_if_invalid "$line"
    if [ $line_number = "1" ]
      then
        urls=( $line )
      else
        ports=( $line )
    fi
    ((++line_number))
  done < tempfile.txt
}

ports_data()
{

  PORTXML=""

  for port in "${ports[@]}"
  do
    netstat -ln  | awk '{ print $4 }' | awk 'BEGIN { FS=":" } ; { print $NF }' | grep "^${port}$" > /dev/null
    if [ $? =  "1" ]
      then
        PORTXML="${PORTXML}<port><address>${port}</address><status>0</status></port>"
      else
        PORTXML="${PORTXML}<port><address>${port}</address><status>1</status></port>"
    fi
  done
}

pages_data()
{

  PAGEXML=""

  for page in "${urls[@]}"
  do
    if curl --output /dev/null --silent --head --fail "${page}"
      then
        PAGEXML="${PAGEXML}<page><url>${page}</url><status>1</status></page>"
      else
        PAGEXML="${PAGEXML}<page><url>${page}</url><status>0</status></page>"
      fi
  done

}

os_data()
{
  OS=`lowercase \`uname\``
  KERNEL=`uname -r`
  MACH=`uname -m`

  if [ "{$OS}" == "windowsnt" ]; then
    OS=windows
  elif [ "{$OS}" == "darwin" ]; then
    OS=mac
  else
    OS=`uname`
    if [ "${OS}" = "SunOS" ] ; then
      OS=Solaris
      ARCH=`uname -p`
      OSSTR="${OS} ${REV}(${ARCH} `uname -v`)"
    elif [ "${OS}" = "AIX" ] ; then
      OSSTR="${OS} `oslevel` (`oslevel -r`)"
    elif [ "${OS}" = "Linux" ] ; then
      if [ -f /etc/redhat-release ] ; then
        DistroBasedOn='RedHat'
        DIST=`cat /etc/redhat-release |sed s/\ release.*//`
        PSUEDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
        REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
      elif [ -f /etc/SuSE-release ] ; then
        DistroBasedOn='SuSe'
        PSUEDONAME=`cat /etc/SuSE-release | tr "\n" ' '| sed s/VERSION.*//`
        REV=`cat /etc/SuSE-release | tr "\n" ' ' | sed s/.*=\ //`
      elif [ -f /etc/mandrake-release ] ; then
        DistroBasedOn='Mandrake'
        PSUEDONAME=`cat /etc/mandrake-release | sed s/.*\(// | sed s/\)//`
        REV=`cat /etc/mandrake-release | sed s/.*release\ // | sed s/\ .*//`
      elif [ -f /etc/debian_version ] ; then
        DistroBasedOn='Debian'
        if [ -f /etc/lsb-release ] ; then
          DIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`
          PSUEDONAME=`cat /etc/lsb-release | grep '^DISTRIB_CODENAME' | awk -F= '{ print $2 }'`
          REV=`cat /etc/lsb-release | grep '^DISTRIB_RELEASE' | awk -F=  '{ print $2 }'`
        elif [ -x /usr/bin/lsb_release ] ; then
          DIST=`/usr/bin/lsb_release -i | awk -F'\t'  '{ print $2 }'`
          PSUEDONAME=`/usr/bin/lsb_release -c | awk -F'\t'  '{ print $2 }'`
          REV=`/usr/bin/lsb_release -r | awk -F'\t'  '{ print $2 }'`
        else
          DIST='Debian'
          REV=`head /etc/debian_version`
        fi
      fi
      if [ -f /etc/UnitedLinux-release ] ; then
        DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
      fi
      OS=`lowercase $OS`
      DistroBasedOn=`lowercase $DistroBasedOn`
      readonly OS
      readonly DIST
      readonly DistroBasedOn
      readonly PSUEDONAME
      readonly REV
      readonly KERNEL
      readonly MACH
    fi
  fi
}

bandwidth_data()
{
  RX=`netstat -i | grep -v lo | awk '{print $4}' | tail -1`
  TX=`netstat -i | grep -v lo | awk '{print $8}' | tail -1`
  readonly TX
  readonly RX
}

uptime_data()
{
  UPTIME=`awk '{ print $1 }' /proc/uptime`
}

load_data()
{
  LOAD1=`awk '{ print $1 }' /proc/loadavg`
  LOAD2=`awk '{ print $2 }' /proc/loadavg`
  LOAD3=`awk '{ print $3 }' /proc/loadavg`
}

memory_data()
{
  MEMTOTAL=`awk '/MemTotal/ { print $2 }' /proc/meminfo`
  MEMFREE=`awk '/MemFree/ { print $2 }' /proc/meminfo`
  SWAPTOTAL=`awk '/SwapTotal/ { print $2 }' /proc/meminfo`
  SWAPFREE=`awk '/SwapFree/ { print $2 }' /proc/meminfo`
}

cpu_data()
{
  CPU=`awk 'BEGIN { FS=":" } /model name/ { print $2 }' /proc/cpuinfo | sed q`
  CPUMHZ=`awk 'BEGIN { FS=":" } /cpu MHz/ { print $2 }' /proc/cpuinfo | sed q`
  CPUCOUNT=`cat /proc/cpuinfo | grep processor | wc -l`
}

disk_data()
{
  DRIVES=`df -h | sed 1d | awk '{ print "<drive><totalspace>",$2,"</totalspace><usedspace>",$3,"</usedspace><percent>",$5,"</percent><path>",$6,"</path></drive>"; }'` 
}

cpu_data
memory_data
load_data
uptime_data
bandwidth_data
os_data
disk_data
get_ports_pages
ports_data
pages_data

XML=`cat <<SETVAR
<status>
  <access_key>$$THEKEY$$</access_key>
  <cpuinfo>
    <cpu>$CPU</cpu>
    <cpucount>$CPUCOUNT</cpucount>
    <cpumhz>$CPUMHZ</cpumhz>
  </cpuinfo>
  <memory>
    <total>$MEMTOTAL</total>
    <swaptotal>$SWAPTOTAL</swaptotal>
    <used>$MEMFREE</used>
    <swapused>$SWAPFREE</swapused>
  </memory>
  <load>
    <load1>$LOAD1</load1>
    <load2>$LOAD2</load2>
    <load3>$LOAD3</load3>
  </load>
  <uptime>$UPTIME</uptime>
  <bandwidth>
    <tx>$TX</tx> 
    <rx>$RX</rx>
  </bandwidth>
  <release>$DIST</release>
  <version>$REV</version>
  <platform>$KERNEL</platform>
  <drives>$DRIVES</drives>
  <ports>$PORTXML</ports>
  <pages>$PAGEXML</pages>
</status>
SETVAR`

curl -H "Content-Type: text/xml" -d "$XML" $$THESERVER$$/receive_monitor/
