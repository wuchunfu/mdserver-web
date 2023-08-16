#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# cd /Users/midoks/Desktop/mwdev/server/mdserver-web/plugins/mongodb && /bin/bash install.sh install 5.0.4
# cd /www/server/mdserver-web/plugins/mongodb && /bin/bash install.sh install 5.0.4

curPath=`pwd`
rootPath=$(dirname "$curPath")
rootPath=$(dirname "$rootPath")
serverPath=$(dirname "$rootPath")

install_tmp=${rootPath}/tmp/mw_install.pl
VERSION=$2

sysName=`uname`
echo "use system: ${sysName}"

# bash ${rootPath}/scripts/getos.sh
# OSNAME=`cat ${rootPath}/data/osname.pl`
# SYS_VERSION_ID=`cat /etc/*-release | grep VERSION_ID | awk -F = '{print $2}' | awk -F "\"" '{print $2}'`


Install_app()
{
	echo '正在安装脚本文件...' > $install_tmp
	MG_DIR=$serverPath/source/mongodb
	mkdir -p $MG_DIR

	cd ${rootPath}/plugins/php/lib && /bin/bash openssl.sh
	export PKG_CONFIG_PATH=$serverPath/lib/openssl/lib/pkgconfig

	if [ ! -f $MG_DIR/mongodb-src-r${VERSION}.tar.gz ]; then
		wget --no-check-certificate -O $MG_DIR/mongodb-src-r${VERSION}.tar.gz https://fastdl.mongodb.org/src/mongodb-src-r${VERSION}.tar.gz
		echo "wget --no-check-certificate -O $MG_DIR/mongodb-src-r${VERSION}.tar.gz https://fastdl.mongodb.org/src/mongodb-src-r${VERSION}.tar.gz"
	fi

	if [ ! -d $MG_DIR/mongodb-src-r${VERSION} ];then
		cd $MG_DIR && tar -zxvf $MG_DIR/mongodb-src-r${VERSION}.tar.gz
	fi

	cd $MG_DIR/mongodb-src-r${VERSION} && python3 -m pip install requirements_parser
	cd $MG_DIR/mongodb-src-r${VERSION} && python3 -m pip install -r etc/pip/compile-requirements.txt

	# cd $MG_DIR/mongodb-src-r${VERSION} && python3 buildscripts/scons.py all -j 2
	# echo "cd $MG_DIR/mongodb-src-r${VERSION} && python3 buildscripts/scons.py all -j 2"
	# cd $MG_DIR/mongodb-src-r${VERSION} && python3 buildscripts/scons.py all MONGO_VERSION=${VERSION} -j 4


	cd $MG_DIR/mongodb-src-r${VERSION} && python3 buildscripts/scons.py core MONGO_VERSION=${VERSION} -j 4
	cd $MG_DIR/mongodb-src-r${VERSION} && python3 buildscripts/scons.py --prefix=$serverPath/mongodb install MONGO_VERSION=${VERSION} \
	--ssl CPPPATH=$serverPath/1.0.2j/include \
	LIBPATH=$serverPath/openssl/1.0.2j/lib
	echo "cd $MG_DIR/mongodb-src-r${VERSION} && python3 buildscripts/scons.py --prefix=$serverPath/mongodb install MONGO_VERSION=${VERSION}"

	if [ "$?" == "0" ];then
		mkdir -p $serverPath/mongodb
		echo "${VERSION}" > $serverPath/mongodb/version.pl
		echo '安装完成' > $install_tmp

		#初始化 
		cd ${rootPath} && python3 ${rootPath}/plugins/mongodb/index.py start
		cd ${rootPath} && python3 ${rootPath}/plugins/mongodb/index.py initd_install
	fi
}


Uninstall_app()
{

	rm -rf $serverPath/mongodb
	echo "Uninstall_mongodb" > $install_tmp
}

action=$1
if [ "${1}" == 'install' ];then
	Install_app
else
	Uninstall_app
fi
