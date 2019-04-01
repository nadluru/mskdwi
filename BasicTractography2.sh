#!/bin/bash

export dwi=$1
bvals=$2
bvecs=$3
mask=$4
suffix=$5

######betvar=${dwi%.nii*}_bet
dwibfloat=${dwi%.nii*}.Bfloat
scheme=${dwi%.nii*}_Camino_${suffix}.scheme
export dti=${dwi%.nii*}_dti_${suffix}.Bfloat
tracts=${dwi%.nii*}_tracts_${suffix}

####bet $dwi $betvar -m
# image2voxel -4dimage $dwi -inputdatatype float -outputdatatype float -outputfile $dwibfloat
fsl2scheme -bvalfile $bvals -bvecfile $bvecs > $scheme
modelfit -inputfile $dwibfloat -inputdatatype float -outputdatatype float -outputfile $dti -schemefile $scheme -model ldt -bgmask $mask

parallel -j2 --bar 'cat $dti | {} -inputdatatype float -outputdatatype float | voxel2image -inputdatatype float -outputroot ${dwi%.nii*}_{} -header $dwi' ::: fa md

track -inputmodel dt -inputfile $dti -inputdatatype float -outputdatatype float -seedfile $mask -anisthresh 0.05 -curvethresh 45 -curveinterval 0.5 -stepsize 0.1 -tracker euler -outputfile $tracts.Bfloat
cat $tracts.Bfloat | procstreamlines -mintractlength 10 -outputfile ${tracts}Filtered.Bfloat -seedfile $mask
camino_to_trackvis -i ${tracts}Filtered.Bfloat -o /tmp/tmp${tracts//\//\_}Filtered.trk --nifti $mask --phys-coords
cp /tmp/tmp${tracts//\//\_}Filtered.trk ${tracts}Filtered.trk
