#! /bin/bash
# Set to same as image_name in the .json - a temporary name for building
IMAGE_NAME="Packer1404"
source ../rc_files/racrc

cd ../images
# Download the latest version
wget -N https://cloud-images.ubuntu.com/daily/server/trusty/current/trusty-server-cloudimg-amd64-disk1.img

# Upload to Glance
echo "Uploading to Glance..."
glance_id=`openstack image create --disk-format qcow2 --container-format bare --file trusty-server-cloudimg-amd64-disk1.img TempUbuntuImage | grep id | awk ' { print $4 }'`

# Run Packer on RAC
packer build \
    -var "source_image=$glance_id" \
    ../scripts/Ubuntu1404.json | tee ../logs/Ubuntu1404.log

if [ ${PIPESTATUS[0]} != 0 ]; then
    exit 1
fi

openstack image delete TempUbuntuImage
sleep 5
#For some reason getting the ID fails but using the name succeeds
#openstack image set --property description="Built on `date`" --property image_type='image' "${IMAGE_NAME}"
glance image-update --property description="Built on `date`" --property image_type='image' --purge-props "${IMAGE_NAME}"

# Grab Image and Upload to DAIR
openstack image save ${IMAGE_NAME} --file 1404.img
openstack image set --name "Ubuntu 14.04" "${IMAGE_NAME}"
echo "Image Available on RAC!"

#source ../rc_files/dairrc
#openstack image create --disk-format qcow2 --container-format bare --file 1404.img "Ubuntu 14.04"

#echo "Image Available on DAIR!"
