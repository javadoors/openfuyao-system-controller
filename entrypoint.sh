#!/bin/bash
###############################################################
# Copyright (c) 2024 Huawei Technologies Co., Ltd.
# installer is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#          http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
# See the Mulan PSL v2 for more details.
###############################################################

# 安装执行路径
BASE_INSTALL_EXEC_DIR="/opt"
SUB_EXEC_DIR="openFuyao/openfuyao-system-install"
INSTALL_EXEC_DIR="$BASE_INSTALL_EXEC_DIR/$SUB_EXEC_DIR"

# 环境变量
# OPENFUYAO_REGISTRY

function _log() {
	local prefix="$1"
	shift
	echo "$(date +"[%Y-%m-%d %H:%M:%S,%N]") [${prefix}] $*"
}

function info_log () {
    _log "INFO" "$*"
}

function warning_log () {
    _log "WARNING" "$*"
}

function error_log () {
    _log "ERROR" "$*"
}

function fatal_log () {
    _log "FATAL" "$*"
    exit 1
}

# 拷贝脚本文件到宿主机
function copy_to_host() {
    info_log "copy install files to host"
    # 避免宿主机有同名路径，在宿主机上创建带有时间戳的目录
    nsenter -i/proc/1/ns/ipc -m/proc/1/ns/mnt -n/proc/1/ns/net mkdir -p "${INSTALL_EXEC_DIR}"
    if [ $? -ne 0 ]; then
        fatal_log "failed to create directory on host"
    fi

    cp -rf /home/openfuyao-system/* /mnt/opt/${SUB_EXEC_DIR}
    if [ $? -ne 0 ]; then
        fatal_log "failed to copy install files to host"
    fi
    info_log "copy install files to host success"
}

function remove_tmp_files() {
    info_log "remove temporary files"
    rm -rf /mnt/opt/${SUB_EXEC_DIR}
    if [ $? -ne 0 ]; then
        error_log "failed to remove temporary files"
    fi
}

function install_openfuyao_system() {
    info_log "start install openfuyao-system"
    copy_to_host

    # 执行安装脚本
    nsenter -i/proc/1/ns/ipc -m/proc/1/ns/mnt -n/proc/1/ns/net bash -c "cd ${INSTALL_EXEC_DIR} && ./install.sh -r ${OPENFUYAO_REGISTRY} --enableHttps=${ENABLE_HTTPS} --repo=${HELM_REPORITORY_URL} --harborAdminPassword=${HARBOR_ADMIN_PASSWORD} --harborRegistryPassword=${HARBOR_REGISTRY_PASSWORD} --harborDatabasePassword=${HARBOR_DATABASE_PASSWORD} --harborRegistryPvSize=${HARBOR_REGISTRY_PV_SIZE} --harborJobservicePvSize=${HARBOR_JOBSERVICE_PV_SIZE} --harborJobservicePvcSize=${HARBOR_JOBSERVICE_PVC_SIZE} --harborDatabasePvSize=${HARBOR_DATABASE_PV_SIZE} --harborDatabasePvcSize=${HARBOR_DATABASE_PVC_SIZE} --harborRegistryPvcSize=${HARBOR_REGISTRY_PVC_SIZE} --harborChartmuseumPvSize=${HARBOR_CHARTMUSEUM_PV_SIZE} --harborChartmuseumPvcSize=${HARBOR_CHARTMUSEUM_PVC_SIZE} --harborRedisPvSize=${HARBOR_REDIS_PV_SIZE} --harborRedisPvcSize=${HARBOR_REDIS_PVC_SIZE} --oauthCertsExpirationTime=${OAUTH_CERTS_EXPIRATION_TIME}"
    if [ $? -ne 0 ]; then
        fatal_log "failed to installed openfuyao-system"
    fi

    remove_tmp_files
}

function uninstall_openfuyao_system() {
    info_log "start uninstall openfuyao-system"
    copy_to_host

    nsenter -i/proc/1/ns/ipc -m/proc/1/ns/mnt -n/proc/1/ns/net bash -c  "cd ${INSTALL_EXEC_DIR} && ./uninstall.sh -r ${OPENFUYAO_REGISTRY}"
    if [ $? -ne 0 ]; then
        fatal_log "failed to uninstall openfuyao-system"
    fi

    remove_tmp_files
}

function usage() {
    echo "see source file"
}

# get-opt 参数
main(){
    while true
    do
        case "$1" in
        -o|--operate)  # 操作类型
            local operate="$2"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
        shift
        break
        ;;
        *)
        echo "$1 is not option, please use -h to view help"
        shift
        break
        ;;
        esac
        shift
    done

    if [ "${operate}" == "uninstall" ];then
        info_log "uninstall openfuyao-system"
        uninstall_openfuyao_system
    elif [ "${operate}" == "install" ]; then
        info_log "install openfuyao-system"
        install_openfuyao_system
    else
        info_log "without operation, use default install operation"
        install_openfuyao_system
    fi
}

ENTRYPOINT_SHELL=$(getopt -n entrypoint.sh -o o:h --long operate:,help -- "$@")
[ $? -ne 0 ] && exit 1
eval set -- "$ENTRYPOINT_SHELL"
main "$@"