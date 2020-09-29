#!/bin/sh

#####################################################
#                Created by: Pantha                 #
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
la=3.39500e+00;
lc=3.50000e+01;
CUTOFF=44;
CUTRHO=440;
type=4;
bravais=4;
atom=6;
dft="'vdw-df-ob86'"
tolerance=1.00000e-07
mixing=6.00000e-01
PRE_1="'pepd'";
OUT="'../temp'";
####################################################
echo $NAME
mkdir $NAME
cp Se.pbe-n-kjpaw_psl.1.0.0.UPF $NAME
cp Mo.pbe-spn-kjpaw_psl.1.0.0.UPF $NAME
cp Te.pbe-n-kjpaw_psl.1.0.0.UPF $NAME
cp S.pbe-n-kjpaw_psl.1.0.0.UPF $NAME
cp ${NAME_1}.dat $NAME
cp ${NAME_2}.dat $NAME
cp vdW_kernel_table $NAME
cd $NAME
#generate_vdW_kernel_table.x
####################################################

for i in 0.0 0.5 1.0 1.5 2.0 2.5 3.0 3.5 4.0 4.5 5.0 #  
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
    a             =  $la
    c             =  $lc
    ecutwfc       =  $CUTOFF
    ecutrho       =  $CUTRHO
    ibrav         =  $bravais
    nat           =  $atom
    ntyp          =  $type
    input_dft     =  $dft
/

&ELECTRONS
    conv_thr      =  $tolerance
    mixing_beta   =  $mixing
    startingpot   = "atomic"
    startingwfc   = "atomic+random"
/

&IONS
    ion_dynamics  = "bfgs"
/

ATOMIC_SPECIES
Se     78.96000  Se.pbe-n-kjpaw_psl.1.0.0.UPF
Mo     95.94000  Mo.pbe-spn-kjpaw_psl.1.0.0.UPF
Te    127.60000  Te.pbe-n-kjpaw_psl.1.0.0.UPF
S      32.06600  S.pbe-n-kjpaw_psl.1.0.0.UPF

ATOMIC_POSITIONS {angstrom}
Se       0.000000000      1.983185648     15.881182035    1   1   1
Mo       0.000000000      0.023028751     14.250600338    1   1   1
Te       0.000000000      1.983038417     12.371873724    0   0   0
S        0.000000000+$i   3.944263032+$j  22.520647484    0   0   0
Mo       0.000000000+$i   1.984265885+$j  21.058095971    1   1   1
Te       0.000000000+$i   3.944486633+$j  19.166009516    1   1   1

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
    a             =  $la
    c             =  $lc
    ecutwfc       =  $CUTOFF
    ecutrho       =  $CUTRHO
    ibrav         =  $bravais
    nat           =  $atom
    ntyp          =  $type
    input_dft     =  $dft
    edir          =  3
    eamp          =  0.00048
    eopreg        =  0.1
    emaxpos       =  0.7
/

&ELECTRONS
    conv_thr      =  $tolerance
    mixing_beta   =  $mixing
    startingpot   = "atomic"
    startingwfc   = "atomic+random"
/

ATOMIC_SPECIES
Se     78.96000  Se.pbe-n-kjpaw_psl.1.0.0.UPF
Mo     95.94000  Mo.pbe-spn-kjpaw_psl.1.0.0.UPF
Te    127.60000  Te.pbe-n-kjpaw_psl.1.0.0.UPF
S      32.06600  S.pbe-n-kjpaw_psl.1.0.0.UPF

K_POINTS (automatic)
  ${n} ${n} ${nz} ${s} ${s} ${s}

EOF


#####################################################################

#PYTHON Code to parse the relaxed atomic position 

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




