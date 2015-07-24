# act-plus freesurfer makefile

# This is where the subject directories live 
PROJHOME=/projects2/act-plus/subjects/session1

cwd=$(shell pwd)

# This sets the subject directories to be the ones we selected
SUBJECTS=$(shell cat /projects2/act-plus/uds/good_subjects.txt)
#SUBJECT=$(notdir $(cwd))

# Set open MP number of threads to be 1, so that we can parallize using make.
export OMP_NUM_THREADS=1

# for Freesurfer (running version 5.3)
export SUBJECTS_DIR=/projects2/act-plus/freesurfer
export QA_TOOLS=/usr/local/freesurfer/QAtools_v1.1

# be really careful with paths and variables - two versions of freesurfer
# installed
export FREESURFER_SETUP = /usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh
export RECON_ALL = /usr/local/freesurfer/stable5_3/bin/recon-all $(RECON_FLAGS)
export TKMEDIT = /usr/local/freesurfer/stable5_3/bin/tkmedit

define usage
   @echo Usage:
   @echo "make, or make interactive	Makes interactive targets"
   @echo "make noninteractive		Makes noninteractive targets"
   @echo 
   @echo Noninteractive targets:
   @echo "make setup			Copies source files to this directory"
   @echo "make freesurfer		Runs freesurfer"
   @echo
   @echo Other useful targets:
   @echo "make clean			Remove everything! Be careful!"
   @echo "make mostlyclean		Remove everything but the good bits."
   @echo "make help			Print this message."
   @echo
   @echo Variables:
   @echo "RECON_FLAGS			Set to flags to recon-all, by default"
   @echo "WAVE				1, 2 or 3 to select subjects, for setup"
endef

export SHELL=/bin/bash

.PHONY: qa clean mostlyclean output noninteractive 

noninteractive: setup freesurfer

all: noninteractive

output=$(SUBJECTS:%=%/mri/aparc+aseg.mgz) $(SUBJECTS:%=%/mri/brainmask.nii.gz)
freesurfer: $(output)

#recon-all $(RECON_FLAGS) -subjid  $${subj} -FLAIR $${subj}/flair.nii.gz -FLAIRpial;\

#####################################

qafiles=$(SUBJECTS:%=QA/%)

qa: $(qafiles)

QA/%: %
	source $$FREESURFER_SETUP ;\
	$(QA_TOOLS)/recon_checker -s $*

#####################################

# No more Freesurfer mixed in with other stuff

%/mri/aparc+aseg.mgz: $(PROJHOME)/%/memprage/T1.nii.gz
	rm -rf `dirname $@`/IsRunning.*
	source /usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh ;\
	export SUBJECTS_DIR=$(SUBJECTS_DIR) ;\
	/usr/local/freesurfer/stable5_3/bin/recon-all -i $< -subjid $* -all ;\
	/usr/local/freesurfer/stable5_3/bin/recon-all -s $* -T2 $(PROJHOME)/$*/flair/Flair.nii.gz -T2pial

#Use Registration matrix to create skull stripped brain (memprage/T1_brain) from FreeSurfer's skull strip in fsl T1 space

%/mri/brainmask.nii.gz: $(SUBJECTS_DIR)/%/mri/aparc+aseg.mgz
	source /usr/local/freesurfer/stable5_3/SetUpFreeSurfer.sh ;\
	mri_convert $(SUBJECTS_DIR)/$*/mri/brainmask.mgz $@

clean:
	echo rm -rf $(inputdirs)

mostlyclean:
	@echo Here I would delete things that are not necessary after all is said and done.

output: 
	@echo Nothing yet

setup: $(SUBJECTS)

%:  $(PROJHOME)/%/memprage/T1.nii.gz 
	mkdir -p $@/mri/orig; \
	cp $^ $@/mri/orig; \
	cd $@/mri/orig; \
	mri_convert T1.nii.gz 001.mgz

help:
	$(usage)
