#!/bin/bash

DIR=${1:-$(dirname $0)/../examples/consul-cluster}
REGION=${2:-$OS_REGION_NAME}
DESTROY=${3:-1}
CLEAN=${4:-1}
PROJECT=${OS_TENANT_ID}
VRACK=${OVH_VRACK_ID}

test_tf(){
    # timeout is not 60 seconds but 60 loops, each taking at least 1 sec
    local timeout=60
    local inc=0
    local res=1

    while [ "$res" -ne 0 ] && [ "$inc" -lt "$timeout" ]; do
        (cd "${DIR}" && terraform output tf_test | sh)
        res=$?
        sleep 1
        ((inc++))
    done

    return $res
}


# if destroy mode, clean previous terraform setup
if [ "${CLEAN}" == "1" ]; then
    (cd "${DIR}" && rm -Rf .terraform *.tfstate*)
fi

# run the full terraform setup
(cd "${DIR}" && terraform init \
	   && terraform apply -auto-approve -var region="${REGION}" -var project_id="${PROJECT}" -var vrack_id="${VRACK}")
EXIT_APPLY=$?

# if terraform went well run test
if [ "${EXIT_APPLY}" == 0 ]; then
    test_tf
    EXIT_APPLY=$?
fi

# if destroy mode, clean terraform setup
if [ "${DESTROY}" == "1" ]; then
    (cd "${DIR}" && terraform destroy -force -var region="${REGION}" -var project_id="${PROJECT}" -var vrack_id="${VRACK}"\
        && rm -Rf .terraform *.tfstate*)
    EXIT_DESTROY=$?
else
    EXIT_DESTROY=0
fi

exit $((EXIT_APPLY+EXIT_DESTROY))
