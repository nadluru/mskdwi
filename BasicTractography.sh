#!/bin/bash

bet data_combi.nii.gz data_combi_bet -m
image2voxel -4dimage data_combi.nii.gz -inputdatatype float -outputdatatype float -outputfile data_combi.Bfloat
fsl2scheme -bvalfile bvals -bvecfile bvecs > camino.scheme
modelfit -inputfile data_combi.Bfloat -inputdatatype float -outputdatatype float -outputfile data_combi_dti.Bfloat -schemefile camino.scheme -model ldt
echo -e "fa\nmd" | xargs -I %  bash -c 'cat data_combi_dti.Bfloat | % -inputdatatype float -outputdatatype float | voxel2image -inputdatatype float -outputroot % -header data_combi.nii.gz'

track -inputmodel dt -inputfile data_combi_dti.Bfloat -inputdatatype float -outputdatatype float -seedfile data_combi_bet_mask.nii.gz -anisthresh 0 -curvethresh 45 -curveinterval 0.5 -stepsize 0.1 -tracker euler -outputfile TractsLightWeightVis.Bfloat
cat TractsLightWeightVis.Bfloat | procstreamlines -mintractlength 100 -outputfile TractsLightWeightVisFiltered.Bfloat -seedfile data_combi_bet_mask.nii.gz
camino_to_trackvis -i TractsLightWeightVisFiltered.Bfloat -o TractsLightWeightVisFiltered.trk --nifti data_combi_bet_mask.nii.gz --phys-coords

cat data_combi_dti.Bfloat | dteig -inputdatatype float -outputdatatype float -inputmodel dt > data_combi_dti_eig.Bfloat
pdview -inputfile data_combi_dti_eig.Bfloat -inputmodel dteig -header data_combi.nii.gz -inputdatatype float


root="DTI_toNagesh_3_1_19/*/??R/DiffusionPreproc/data"
parallel --link echo {1} {2} {3} ::: $root/data.nii.gz ::: $root/bvals ::: $root/bvecs

root="DTI_toNagesh_3_1_19/*/??R/DiffusionPreproc/data"
parallel -j4 --verbose -k --bar --plus 'bet {} {..}_bet -m;fslmaths {..}_bet_mask.nii.gz -ero {..}_bet_mask_ero.nii.gz;' ::: $root/data.nii.gz

root="DTI_toNagesh_3_1_19/*/??R/DiffusionPreproc/data"
parallel -j4 --bar --link ./BasicTractography2.sh {1} {2} {3} {4} ::: $root/data.nii.gz ::: $root/bvals ::: $root/bvecs ::: $root/nodif_brain_mask.nii.gz

root="DTI_toNagesh_3_1_19/*/??R/DiffusionPreproc/data"
parallel --link echo {1} {2} {3} {4} ::: $root/data.nii.gz ::: $root/bvals ::: $root/bvecs ::: $root/data_bet_mask_ero.nii.gz

root="DTI_toNagesh_3_1_19/*/??R/DiffusionPreproc/data"
parallel -j4 --bar --link ./BasicTractography2.sh {1} {2} {3} {4} ::: $root/data.nii.gz ::: $root/bvals ::: $root/bvecs ::: $root/data_bet_mask_ero.nii.gz

root="DTI_toNagesh_3_1_19/*/??R/DiffusionPreproc/data"
parallel -j4 --bar --link ./BasicTractography2.sh {1} {2} {3} {4} ::: $root/data.nii.gz ::: $root/bvals ::: $root/bvecs_swapxz ::: $root/data_bet_mask_ero.nii.gz

root="DTI_toNagesh_3_1_19/*/??R/DiffusionPreproc/data"
parallel -j4 --bar 'cat {} | dteig -inputdatatype float -outputdatatype float -inputmodel dt > {.}_eig.Bfloat' ::: $root/data_dti.Bfloat


root="DTI_toNagesh_3_1_19/*/??R/DiffusionPreproc/data"
parallel -j8 --bar --plus 'image2voxel -4dimage {} -inputdatatype float -outputdatatype float -outputfile {..}.Bfloat' ::: $root/data.nii.gz

root="DTI_toNagesh_3_1_19/*/COMBI"
parallel -j8 --bar --plus 'image2voxel -4dimage {} -inputdatatype float -outputdatatype float -outputfile {..}.Bfloat' ::: $root/data_combi.nii.gz

root="DTI_toNagesh_3_1_19/*/??R/DiffusionPreproc/data"
parallel -j4 --verbose -k --bar --link ./BasicTractography2.sh {1} {2} {3} {4} {5} ::: $root/data.nii.gz ::: $root/bvals ::: $root/bvecs_swapxz ::: $root/data_bet_mask_ero.nii.gz ::: xz

root="DTI_toNagesh_3_1_19/*/COMBI"
parallel -j4 --verbose -k --bar --plus 'bet {} {..}_bet -m;fslmaths {..}_bet_mask.nii.gz -ero {..}_bet_mask_ero.nii.gz;' ::: $root/data_combi.nii.gz

root="DTI_toNagesh_3_1_19/*/COMBI"
root2="DTI_toNagesh_3_1_19/*/UPR/DiffusionPreproc/data"
parallel -j4 --verbose -k --bar --link ./BasicTractography2.sh {1} {2} {3} {4} {5} ::: $root/data_combi.nii.gz ::: $root2/bvals ::: $root2/bvecs_swapxz ::: $root/data_combi_bet_mask_ero.nii.gz ::: xz

root="DTI_toNagesh_3_1_19/*/COMBI"
root2="DTI_toNagesh_3_1_19/*/UPR/DiffusionPreproc/data"
parallel -j4 --verbose -k --bar --link ./BasicTractography2.sh {1} {2} {3} {4} {5} ::: $root/data_combi.nii.gz ::: $root2/bvals ::: $root2/bvecs ::: $root/data_combi_bet_mask_ero.nii.gz ::: noswap

## Debugging...
cd Tractography/DTI_toNagesh_3_1_19/4160_hsi_120002_TOI2/UPR/DiffusionPreproc/data
fsl2scheme -bvalfile bvals -bvecfile bvecs_swapxy > camino.scheme
modelfit -inputfile data.Bfloat -inputdatatype float -outputdatatype float -outputfile data_dti2.Bfloat -schemefile camino.scheme -model ldt
cat data_dti2.Bfloat | dteig -inputdatatype float -outputdatatype float -inputmodel dt > data_dti2_eig.Bfloat


fsl2scheme -bvalfile bvals -bvecfile bvecs_swapyz > camino.scheme
modelfit -inputfile data.Bfloat -inputdatatype float -outputdatatype float -outputfile data_dti3.Bfloat -schemefile camino.scheme -model ldt
cat data_dti3.Bfloat | dteig -inputdatatype float -outputdatatype float -inputmodel dt > data_dti3_eig.Bfloat
pdview -inputfile data_dti3_eig.Bfloat -inputmodel dteig -header data.nii.gz -inputdatatype float

fsl2scheme -bvalfile bvals -bvecfile bvecs_swapxz > camino.scheme
modelfit -inputfile data.Bfloat -inputdatatype float -outputdatatype float -outputfile data_dti4.Bfloat -schemefile camino.scheme -model ldt
cat data_dti4.Bfloat | dteig -inputdatatype float -outputdatatype float -inputmodel dt > data_dti4_eig.Bfloat
pdview -inputfile data_dti4_eig.Bfloat -inputmodel dteig -header data.nii.gz -inputdatatype float

x z seems to be it!!!


# hmm....does not seem to be...so trying yz again. 3898 had issues prior to ISMRM as well so focussing on that first.

fsl2scheme -bvalfile bvals -bvecfile bvecs_yz > camino.scheme
modelfit -inputfile data_combi.Bfloat -inputdatatype float -outputdatatype float -outputfile data_dti3.Bfloat -schemefile camino.scheme -bgmask data_combi_bet_mask.nii.gz -model ldt
cat data_dti3.Bfloat | dteig -inputdatatype float -outputdatatype float -inputmodel dt > data_dti3_eig.Bfloat
pdview -inputfile data_dti3_eig.Bfloat -inputmodel dteig -header data.nii.gz -inputdatatype float

# 4/1/2019. 10:38 a.m.

root="DTI_toNagesh_3_1_19/*/??R/DiffusionPreproc/data"
parallel -j4 --verbose -k --bar --link ./BasicTractography2.sh {1} {2} {3} {4} {5} ::: $root/data.nii.gz ::: mskscannerbvals ::: mskscannerbvecs ::: $root/data_bet_mask_ero.nii.gz ::: scanner


root="DTI_toNagesh_3_1_19/*/COMBI"
root2="DTI_toNagesh_3_1_19/*/UPR/DiffusionPreproc/data"
parallel -j4 --verbose -k --bar --link ./BasicTractography2.sh {1} {2} {3} {4} {5} ::: $root/data_combi.nii.gz ::: mskscannerbvals ::: mskscannerbvecs ::: $root/data_combi_bet_mask_ero.nii.gz ::: scanner