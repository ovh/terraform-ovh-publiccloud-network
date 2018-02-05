#!/bin/bash

DIR=${1:-simple}
REGION=${2:-$OS_REGION_NAME}
PROJECT=${OS_TENANT_ID}
VRACK=${OVH_VRACK_ID}

(cd "${DIR}" && rm -Rf .terraform \
     && terraform init \
	   && terraform apply -auto-approve -var region="${REGION}" -var project_id="${PROJECT}" -var vrack_id="${VRACK}")
EXIT_APPLY=$?

(cd "${DIR}" && terraform destroy -force -var region="${REGION}" -var project_id="${PROJECT}" -var vrack_id="${VRACK}")
EXIT_DESTROY=$?

exit $((EXIT_APPLY+EXIT_DESTROY))
