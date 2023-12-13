# Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

PATH:prepend = "/usr/bin:"

python do_fetch_extra () {
    import json
    from pathlib import Path
    import hashlib
    import glob
    import re
    import subprocess

    def get_sdk_info(sdk):
        # Get SDK absolute path
        if glob.glob(sdk) == []:
            bb.fatal("Fail to get the sdk from %s, please check the location!" %sdk)
            return
        sdk_matches = glob.glob(sdk)[0]
        sdk_path = Path(sdk_matches)
        cp_cmd = "cp -r %s %s/" %(sdk_path,d.getVar("B"))
        bb.note("Get SDK from %s" %sdk_path)
        subprocess.call(cp_cmd,shell=True)

        # Get SDK version info
        version_pattern = r"([\d.]+)"
        sdk_name = sdk_matches.split('/')[-1]
        matches = re.findall(version_pattern, sdk_name)
        if matches:
            version = matches[0]
            bb.note("SDK's version: %s" %version)
        else:
            version = ""
            bb.warn("No SDK's version")

        # Get SDK hashsum info
        hash_cmd = "md5sum %s" %sdk_matches
        process = subprocess.Popen(hash_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        stdout, stderr = process.communicate()
        hashsum = stdout.decode('utf-8').split(' ')[0]
        bb.note("SDK's hashsum: %s" %hashsum)

        return (version,hashsum)

    def get_config_sdk_info(config_file):
        # locate config_path
        absolute_config_path = d.getVar("FILE_DIRNAME") + "/../files/" + config_file
        path = Path(absolute_config_path)
        if not path.exists():
            bb.fatal("config file: %s not exist" %path)
            return
        bb.note("Config file path is %s " %(absolute_config_path))
        config = json.load(path.open(mode='r'))

        # get version info from config.json
        for function_sdk in config['function_sdks']:
            name = function_sdk['name']
            if d.getVar("PN") == name:
                version = function_sdk['version']
                bb.note("In config file, %s SDK version is %s " %(name, version))
                hashsum = function_sdk['hashsum']
                bb.note("In config file, %s SDK hashsum is %s " %(name, hashsum))
                break

        return (version,hashsum)

    # If you want to use a customized function sdk version,
    # please change the version to "latest" in the config file
    def version_check(sdk_version, sdk_hashsum, config_sdk_version, config_sdk_hashsum):
        if config_sdk_version == "latest" or config_sdk_hashsum == "latest":
            bb.note("Use latest SDK, bypass the version check")
            return

        # The hashsum is to ensure the uniqueness of the file during transmission or copying.
        # Recompression will change the hashsum value, which is normal. So if your function sdk
        # is regenerated from source code, please ignore this warning.
        if config_sdk_version == "":
            bb.warn("There are no version info in config file! Just check hashsum ")
            if sdk_hashsum != config_sdk_hashsum:
                bb.warn("real sdk hash is %s, hash in config is %s" %(sdk_hashsum,config_sdk_hashsum))
                bb.warn("Version or hashsum MISMATCHES, please check")
            else:
                bb.note("SDK hash matches with the info in config file")
                return

        if sdk_version == config_sdk_version and sdk_hashsum == config_sdk_hashsum:
            bb.note("SDK version & hash matches with the info in config file")
            return
        else:
            bb.warn("real sdk version is %s, version in config is %s " %(sdk_version,config_sdk_version))
            bb.warn("real sdk hash is %s, hash in config is %s " %(sdk_hashsum,config_sdk_hashsum))
            bb.warn("Version or hashsum MISMATCHES, please check")

    sdk_version, sdk_hashsum = get_sdk_info(d.getVar("SDKSPATH"))
    config_sdk_version, config_sdk_hashsum = get_config_sdk_info(d.getVar("CONFIGFILE"))
    version_check(sdk_version, sdk_hashsum, config_sdk_version, config_sdk_hashsum)
}

addtask do_fetch_extra before do_fetch

python do_unpack () {
    import os
    from pathlib import Path
    import subprocess

    def extract_sdk(dir):
        if not os.path.exists(dir):
            bb.fatal('{} not exist'.format(dir))
            return
        for entry in os.listdir(dir):
            path = os.path.join(dir, entry)
            if os.path.isdir(path):
                extract_sdk(path)
            else:
                extract_package(path)

    def extract_package(file):
        extract_funcs = [
            ('.tar.gz', extract_targz),
            ('.tgz', extract_targz),
            ('.tar.xz', extract_tarxz),
            ('.txz', extract_txz),
            ('.zip', extract_zip),
            ('.tar', extract_tar),
            ('.deb', extract_deb),
            ('.ipk', extract_ipk),
            ('.7z', extract_7z),
        ]
        for func in extract_funcs:
            if (file.endswith(func[0])):
                extract_file(file, func)

    def extract_file(file, func):
        out_path = file[:-len(func[0])]
        bb.note('extract {} to {}'.format(file, out_path))
        if not Path(out_path).exists():
            Path(out_path).mkdir()
        func[1](file, out_path)
        extract_sdk(out_path)

    def extract_targz(file, out_path):
        mkdir_cmd = "mkdir -p %s" %out_path
        subprocess.call(mkdir_cmd,shell=True)
        # tar -zxf file -C out_path
        extract_cmd = "tar -zxf %s -C %s" %(file,out_path)
        bb.note(extract_cmd)
        subprocess.call(extract_cmd,shell=True)
        pass

    def extract_tarxz(file, out_path):
        mkdir_cmd = "mkdir -p %s" %out_path
        subprocess.call(mkdir_cmd,shell=True)
        # xz -d file && tar -xf file -C out_path
        extract_cmd = "xz -d %s" %file
        bb.note(extract_cmd)
        subprocess.call(extract_cmd,shell=True)
        extract_cmd = "tar -xf %s -C %s" %(file[:-3],out_path)
        bb.note(extract_cmd)
        subprocess.call(extract_cmd,shell=True)
        pass

    def extract_txz(file, out_path):
        mkdir_cmd = "mkdir -p %s" %out_path
        subprocess.call(mkdir_cmd,shell=True)
        # tar -xJf file -C out_path
        extract_cmd = "tar -xJf %s -C %s" %(file,out_path)
        bb.note(extract_cmd)
        subprocess.call(extract_cmd,shell=True)
        pass

    def extract_zip(file, out_path):
        # unzip -x file -d file out_path
        extract_cmd = "unzip -x %s -d %s" %(file,out_path)
        bb.note(extract_cmd)
        subprocess.call(extract_cmd,shell=True)
        pass

    def extract_tar(file, out_path):
        mkdir_cmd = "mkdir -p %s" %out_path
        subprocess.call(mkdir_cmd,shell=True)
        # tar -xf file -C out_path
        extract_cmd = "tar -xf %s -C %s" %(file,out_path)
        bb.note(extract_cmd)
        subprocess.call(extract_cmd,shell=True)
        pass

    def extract_deb(file, out_path):
        # dpkg -X file out_path
        extract_cmd = "dpkg -X %s %s/data" %(file,out_path)
        subprocess.call(extract_cmd,shell=True)
        extract_cmd = "dpkg -e %s %s" %(file,out_path)
        bb.note(extract_cmd)
        subprocess.call(extract_cmd,shell=True)
        pass

    def extract_ipk(file, out_path):
        # ar -x file --output out_path
        extract_cmd = "cd %s && ar -x %s && cd -" %(out_path,file)
        bb.note(extract_cmd)
        subprocess.call(extract_cmd,shell=True)
        pass

    def extract_7z(file, out_path):
        # TODO
        # 7z x file -r -o out_path
        pass

    extract_sdk(d.getVar('S'))
}

python do_install() {
    import os
    import subprocess
    import shutil

    def locate_extract_dir(dir):
        if(len(os.listdir(dir)) == 1 ):
            bb.note(dir + "/" + os.listdir(dir)[0])
            d.setVar("COPYDIR", dir + "/" + os.listdir(dir)[0])
            # d.setVar("DIRNAME", os.listdir(dir)[0])
        else:
            for entry in os.listdir(dir):
                path = os.path.join(dir, entry)
                if os.path.isdir(path) and entry != ".git":
                    locate_extract_dir(path)

    def migrate_data_dir(dir):
        data_dir_list = ""
        for dirpath, dirnames, filenames in os.walk(dir):
            if "data" in dirnames:  # if include data dir
                data_dir = os.path.join(dirpath, "data")
                data_dir += "/*"
                data_dir_list += data_dir + " "
        if data_dir_list:
            copy_cmd = "cp -r %s %s" %(data_dir_list,d.getVar("D") + "/" + d.getVar("PN"))
            bb.note(copy_cmd)
            subprocess.call(copy_cmd,shell=True)
        else:
            bb.note("do_install: There has no data dir after unpacked")

    locate_extract_dir(d.getVar('S'))
    copy_cmd = "cp -r %s %s" %(d.getVar("COPYDIR"),d.getVar("D") + "/" + d.getVar("PN"))
    bb.note(copy_cmd)
    subprocess.call(copy_cmd,shell=True)
    migrate_data_dir(d.getVar("D") + "/" + d.getVar("PN"))

    # remove N/A files
    rm_cmd = "rm -rf %s" %d.getVar("FILES_SKIP")
    bb.note(rm_cmd)
    subprocess.call(rm_cmd,shell=True)

    directory = d.getVar("D") + "/" + d.getVar("PN")
    for file in os.listdir(directory):
        if file.endswith('.'+d.getVar("IMAGE_PKGTYPE")):
            pkg_file = os.path.join(directory, file)
            os.remove(pkg_file)
            dir_name = os.path.splitext(pkg_file)[0]
            bb.note(dir_name)
            if os.path.isdir(dir_name):
                shutil.rmtree(dir_name)
}

SYSROOT_DIRS = "/${DIRNAME}/"
SYSROOT_DIRS_IGNORE = "/${PN}/${PN}"
FILES:${PN} = "/"

do_fetch_extra[cleandirs] = "${S}"
do_unpack[cleandirs] = ""
do_configure[noexec] = "1"
do_compile[noexec] = "1"
do_prepare_recipe_sysroot[noexec] = "1"
do_populate_lic[noexec] = "1"
do_package_qa[noexec] = "1"

INSANE_SKIP:${PN} += "already-stripped"
INHIBIT_SYSROOT_STRIP = "1"
EXCLUDE_FROM_SHLIBS = "1"
