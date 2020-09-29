#!/bin/sh

#####################################################
#           Created By: Pantha                      #
#####################################################


#Variables
#####################################################
NAME="PES_PDS"
NAME_1="energy"
NAME_2="dipole"
INPUT_1="relax.in"
OUTPUT_1="relax.out"
INPUT_2="scf.in"
OUTPUT_2="scf.out"
n=12;
nz=1;
s=0;
CUTOFF=44;
CUTRHO=440;
PRE_1="'pepd'";
OUT="'../temp'";
####################################################
echo $NAME
mkdir $NAME
cp Se.pbe-dn-kjpaw_psl.1.0.0.UPF $NAME
cp S.pbe-n-kjpaw_psl.1.0.0.UPF $NAME
cp Mo.pbe-spn-kjpaw_psl.1.0.0.UPF $NAME
cp ${NAME_1}.dat $NAME
cp ${NAME_2}.dat $NAME
cd $NAME
generate_vdW_kernel_table.x
####################################################

for i in 0.0 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0
do
for j in 0.0 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 #  
do

#################################################################
sub_name=${i}_${j}
if [ -d "/home/pantha/Downloads/hetero/MoS-SeTe/pepd/10.14/PES_PDS/$sub_name" ]
then
echo "$sub_name already exists"
continue
fi
mkdir $sub_name
echo "$sub_name created"
mv ${NAME_1}.dat $sub_name
mv ${NAME_2}.dat $sub_name
cd $sub_name

##################################################################
cat > ${INPUT_1} << EOF

&CONTROL
    calculation   = "relax",
    forc_conv_thr =  1.00000e-04
    pseudo_dir    = "../",
    outdir        =  $OUT
    prefix        =  $PRE_1

/

&SYSTEM
    a                         =  3.23400e+00
    c                         =  2.50000e+01
    ecutrho                   =  $CUTRHO
    ecutwfc                   =  $CUTOFF
    ibrav                     =  4
    nat                       =  6
    ntyp                      =  3
    input_dft                 =  "vdw-df-ob86"

/

&ELECTRONS
    conv_thr         =  1.00000e-07
    mixing_beta      =  6.00000e-01
    startingpot      = "atomic"
    startingwfc      = "atomic+random"
/

&IONS
    ion_dynamics = "bfgs"
/


ATOMIC_SPECIES
Se     78.96000  Se.pbe-dn-kjpaw_psl.1.0.0.UPF
S      32.06600  S.pbe-n-kjpaw_psl.1.0.0.UPF
Mo     95.94000  Mo.pbe-spn-kjpaw_psl.1.0.0.UPF

ATOMIC_POSITIONS {angstrom}
Se       0.000000000      1.867152000      3.240777023 1 1 1
Mo       0.000000000      0.000000000      1.534921754 1 1 1
S        0.000000000      1.867152000      0.000000000 0 0 0
Se       1.617000000+$i   0.933576000+$j   9.600000000 0 0 0
Mo       0.000000000+$i   1.867152000+$j   7.895169413 1 1 1 
S        1.617000000+$i   0.933576000+$j   6.359028722 1 1 1

K_POINTS (automatic)
  ${n} ${n} ${nz} ${s} ${s} ${s}
EOF

pw.x < ${INPUT_1} > ${OUTPUT_1}

#####################################################################

cat > ${INPUT_2} << EOF

&CONTROL
    calculation   = "scf",
    pseudo_dir    = "../",
    outdir        =  $OUT
    prefix        = 'scfd'
    tprnfor       = .TRUE.
    tstress       = .TRUE.
    tefield       = .TRUE.
    dipfield      = .TRUE.
/

&SYSTEM
    a                         =  3.23400e+00
    c                         =  2.50000e+01
    ecutrho                   =  $CUTRHO
    ecutwfc                   =  $CUTOFF
    ibrav                     =  4
    nat                       =  6
    ntyp                      =  3
    input_dft                 =  "vdw-df-ob86"
    edir		      =  3
    eamp		      =  0.D0
    eopreg		      =  0.1
    emaxpos                   =  0.5

/

&ELECTRONS
    conv_thr         =  1.00000e-07
    mixing_beta      =  6.00000e-01
    startingpot      = "atomic"
    startingwfc      = "atomic+random"
/



ATOMIC_SPECIES
Se     78.96000  Se.pbe-dn-kjpaw_psl.1.0.0.UPF
S      32.06600  S.pbe-n-kjpaw_psl.1.0.0.UPF
Mo     95.94000  Mo.pbe-spn-kjpaw_psl.1.0.0.UPF

K_POINTS (automatic)
  ${n} ${n} ${nz} ${s} ${s} ${s}

EOF


#####################################################################

#PYTHON 

cat > relaxed_atomic_position.py << EOF
fh = open('${OUTPUT_1}', 'r')
f = open('${INPUT_2}', 'a')
flag = 0
a = []

for line in fh:
    line=line.rstrip()
    if line.startswith('Begin') :
        flag = 1
    elif line.startswith('End'):
        flag = 0
    elif flag:
        f.write(line[0:48] + '\n')


fh.close()
f.close()
EOF

python3 relaxed_atomic_position.py
#####################################################################

pw.x < ${INPUT_2} > ${OUTPUT_2}

awk '/\!/ {E=$5} $1=="PWSCF" {printf"%s %s %s %s\n",'$i', '$j', E, $3}' $OUTPUT_2 >> ${NAME_1}.dat
#####################################################################

grep Dipole ${OUTPUT_2} >> dipole_all.dat

cat > dipole.py << EOF
file_1=open('dipole_all.dat','r' )
file_2=open('${NAME_2}.dat','a')

count=0
count1=0


for i in file_1:
	count+=1
file_1.seek(0,0)

for j in file_1:
	count1+=1
	if count1==count-1:
		line=j
		line=line.split()
		word=line[4]

file_1.close()
text=str($i) + ' ' + str($j) + ' ' + word + '\n'
print(text)
file_2.write(text)
file_2.close()
EOF

python3 dipole.py

#####################################################################
cp ${NAME_1}.dat ..
cp ${NAME_2}.dat ..
echo "End_${sub_name}"
cd ..
######################################################################
done
done

##########################################################

##########################################################

cd ..
echo "End_${NAME}"

#######################################################################
#clipboard



