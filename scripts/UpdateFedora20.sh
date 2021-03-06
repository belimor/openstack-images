#! /bin/bash
# Set to same as image_name in the .json - a temporary name for building
IMAGE_NAME="Packer Fedora"
source ../rc_files/racrc

cd ../images
# Download the latest version
wget -N http://download.fedoraproject.org/pub/fedora/linux/updates/20/Images/x86_64/Fedora-x86_64-20-20140407-sda.qcow2

# Upload to Glance
echo "Uploading to Glance..."
glance_id=`openstack image create --disk-format qcow2 --container-format bare --file Fedora-x86_64-20-20140407-sda.qcow2 TempFedoraImage | grep id | awk ' { print $4 }'`

# Run Packer on RAC
packer build \
    -var "source_image=$glance_id" \
    ../scripts/Fedora20.json | tee ../logs/Fedora20.log

if [ ${PIPESTATUS[0]} != 0 ]; then
    exit 1
fi

openstack image delete TempFedoraImage
sleep 5
# For some reason getting the ID fails but using the name succeeds.
#openstack image set --property description="Built on `date`" --property image_type='image' "${IMAGE_NAME}"
glance image-update --property description="Built on `date`" --property image_type='image' --purge-props "${IMAGE_NAME}"

# Grab Image and Upload to DAIR
openstack image save "${IMAGE_NAME}" --file F20.img
openstack image set --name "Fedora 20" "${IMAGE_NAME}"
echo "Image Available on RAC!"

source ../rc_files/dairrc
openstack image create --disk-format qcow2 --container-format bare --file F20.img "Fedora 20"

echo "Image Available on DAIR!"
