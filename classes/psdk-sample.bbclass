# Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

def check_and_sync_sample_codes(d):
    samples_path = d.getVar('SAMPLES_PATH')
    sample_code_link = d.getVar('SAMPLE_CODE_LINK')
    if samples_path and os.path.exists(samples_path):
        bb.note("Get samples from local path")
        pass
    elif sample_code_link:
        bb.note("Get samples from remote link")
        return "sync_sample_codes"
    else :
        bb.note("No samples found from both remote link and local path")
        pass

do_install[postfuncs] += "${@check_and_sync_sample_codes(d)}"

sync_sample_codes() {
    
    bbnote "downloading samples..."
    
    #orgnanize sample codes
    install -d ${SAMPLES_PATH}
    cd ${SAMPLES_PATH}

    #get all sample code link and assign to LINK array
    tempfile=$(mktemp)
    echo "${SAMPLE_CODE_LINK}" | tr ' ' '\n' > $tempfile
    mapfile -t LINK < $tempfile

    #sync every sample git project
    for link in "${LINK[@]}"; do
        echo "$link"
        url=$(echo $link | cut -d';' -f1)
        branch=$(echo $link | cut -d';' -f2 | cut -d'=' -f2)
        git clone -b $branch $url
    done
}

def check_sample_codes(d):
    samples_path = d.getVar('ROBOTICS_SAMPLES_PATH')
    if samples_path and os.path.exists(samples_path):
        bb.note("Get robotics samples from local path")
        return samples_path
    else :
        bb.note("No robotics samples found")
        return d.getVar('ROBOTICS_SAMPLE_CODE_LINK')

#SRC_URI += "${@check_sample_codes(d)}"
