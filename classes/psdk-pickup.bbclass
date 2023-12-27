# Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

python do_install () {
    import os
    import json
    from pathlib import Path
    import glob
    import subprocess

    # Update FILES:pkg. (Not used.)
    # input:
    #     lists: a pick-up manifest file
    #     pkg  : package you need to configure
    def update_files(lists, pkg, d):
        if not os.path.isfile(lists):
            print(f"Error: file '{lists}' does not exist")
        else:
            with open(lists, 'r') as file:
                f = ' '.join([line.strip() for line in file])
            d.setVar('FILES:' + pkg, f)

    # Translate function, when you depend on gstreamer recipes,
    # you can use this function to find gst recipes' outputs.
    # input:
    #     sysroot_path: the path of recipe-sysroot
    #     old_path: orginal pick-up path
    # output:
    #     new_path: return a path, to specify the real pick-up path
    def translate_path(sysroot_path, old_path):
        package_name = old_path[:old_path.find("/")]
        new_path = sysroot_path + "/" + old_path
        if "gstreamer1.0" in package_name:
            if os.path.exists((componentdir + "/" + armarch + "/" + package_name)):
                new_path = componentdir + "/" + armarch + "/" + old_path
            elif os.path.exists((componentdir + "/%s/" + package_name) %machine_arch):
                new_path = componentdir + ("/%s/" %machine_arch) + old_path
            else:
                bb.warn("%s can not find, please check the location." %package_name)
        return new_path

    # Pick up files with configure file from recipe-sysroot.
    # input:
    #     config_path: the path of configure file
    #     function_sdk_path: the path of recipe-sysroot
    #     product_sdk_path: the path of pick-up outputs
    #     pickup_record: a file to record the pick-up files
    def pickup_files(config_path, function_sdk_path, product_sdk_path, pickup_record):
        path = Path(config_path)
        bb.note("config file: %s" %path)
        if not path.exists():
            bb.fatal("config file: %s not exist" %path)
            return
        config = json.load(path.open(mode='r'))
        bb.note("function sdk info is below: %s" %config['function_sdks'])

        for sdk in config['function_sdks']:
            bb.note("function sdk name is below: %s" %sdk['name'])
            bb.note("function sdk pickup_files is below: %s" %sdk['pickup_files'])
            for pick in sdk['pickup_files']:
                for src in pick['from']:
                    to_path = product_sdk_path + "/" + pick['to']
                    from_path = translate_path(function_sdk_path, src)
                    bb.note("to_path: %s" %to_path)
                    bb.note("from_path: %s" %from_path)
                    bb.note("src: %s" %src[src.rfind("/")+1:])

                    if "/" == pick['to']:
                        find_cmd = "cd %s && mkdir -p %s && find ./ -type f | sed \"s/\.\//%s/g\" >> %s && cd -" \
                                    %(from_path[:from_path.rfind("/")], product_sdk_path, "\/", product_sdk_path + pickup_record)
                        bb.note(find_cmd)
                    else:
                        find_cmd = "cd %s && mkdir -p %s && find ./ -type f | sed \"s/\.\//%s/g\" >> %s && cd -" \
                                    %(from_path[:from_path.rfind("/")], product_sdk_path, "\/" + pick['to'].replace('/','\/'), product_sdk_path + pickup_record)
                        bb.note(find_cmd)
                    subprocess.call(find_cmd,shell=True)
                    for f in glob.glob(from_path):
                        bb.note("f = %s" %f)
                        if not os.path.exists(f):
                            bb.fatal("%s is not exsit, please check your config file" %f)
                        if not (os.path.exists(to_path[:to_path.rfind("/")])):
                            bb.note("%s is not exsit, have create it firstly" %to_path[:to_path.rfind("/")])
                            os.makedirs(to_path[:to_path.rfind("/")])
                        bb.note("pick from <%s> to <%s>" %(f,to_path))
                        copy_cmd = "cp -r %s %s" %(f,to_path)
                        subprocess.call(copy_cmd,shell=True)

    machine_arch = d.getVar('MACHINE_ARCH')
    sysrootdir = d.getVar('RECIPE_SYSROOT')
    componentdir = d.getVar('COMPONENTS_DIR')
    armarch = d.getVar('PACKAGE_ARCH')
    sdkname = d.getVar('SDK_PN')
    outputdir = d.getVar('D') + "/" + sdkname
    configfile_oss = d.getVar('WORKDIR') + "/" + d.getVar('CONFIG_SELECT')
    fileslist = "/pickup_files_list_oss"
    pickup_files(configfile_oss, sysrootdir, outputdir, fileslist)

    # move files_list to data dir
    fileslist_path = outputdir + "/opt/qcom/qirp-sdk/data/"
    mv_cmd = "mkdir -p %s && mv %s %s" %(fileslist_path, outputdir + fileslist, fileslist_path)
    bb.note(mv_cmd)
    subprocess.call(mv_cmd,shell=True)
}

# add a prefunction to reorganize directory structure
do_reorganize_pkg_dir () {
    if ls ${PKGDEST}/${PN}/${SDK_PN}/* >/dev/null 2>&1; then
        mv ${PKGDEST}/${PN}/${SDK_PN}/* ${PKGDEST}/${PN}/
        rm -rf ${PKGDEST}/${PN}/${SDK_PN}
    fi
}
